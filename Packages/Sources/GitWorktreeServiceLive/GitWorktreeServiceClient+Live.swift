//
//  GitWorktreeServiceClient+Live.swift
//  GitWorktreeCleaner
//

import Dependencies
import Foundation
import GitWorktreeServiceClient
import Localization
import Models

extension GitWorktreeServiceClient: DependencyKey {
    public static let liveValue: Self = {
        let cli = GitCLI()

        /// Names of local branches already merged into `target`.
        @Sendable
        func mergedBranchNames(mergedInto target: String, repoPath: String) throws -> Set<String> {
            let result = try cli.run(["branch", "--format=%(refname:short)", "--merged", target], in: repoPath)
            guard result.succeeded else {
                throw GitWorktreeError.commandFailed(result.stderr.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            let names = result.stdout
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            return Set(names)
        }

        return Self(
            listWorktrees: { repoPath in
                let result = try cli.run(["worktree", "list", "--porcelain"], in: repoPath)
                guard result.succeeded else {
                    let message = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
                    if message.contains("not a git repository") {
                        throw GitWorktreeError.notAGitRepository
                    }
                    throw GitWorktreeError.commandFailed(message.isEmpty ? String(localized: Constant.ErrorAlert.worktreeListFailed) : message)
                }
                return GitWorktreeParser.parse(result.stdout)
            },
            remove: { worktreePath, repoPath in
                do {
                    let result = try cli.run(["worktree", "remove", "--force", worktreePath], in: repoPath)
                    if result.succeeded {
                        return .success(())
                    }
                    let message = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
                    return .failure(.commandFailed(message.isEmpty ? String(localized: Constant.ErrorAlert.removeFailedFallback(path: worktreePath)) : message))
                } catch {
                    return .failure(.commandFailed(error.localizedDescription))
                }
            },
            branchExists: { ref, repoPath in
                (try? cli.run(["rev-parse", "--verify", "--quiet", ref], in: repoPath))?.succeeded == true
            },
            mergeCheckResult: { worktreeList, targetBranchList, repoPath in
                guard !targetBranchList.isEmpty else {
                    return MergeCheckResult(mergedPathList: [], invalidTargetBranchList: [])
                }

                var mergedBranchSets: [Set<String>] = []
                var invalidTargetBranchList: [String] = []
                for target in targetBranchList {
                    if let names = try? mergedBranchNames(mergedInto: target, repoPath: repoPath) {
                        mergedBranchSets.append(names)
                    } else {
                        invalidTargetBranchList.append(target)
                    }
                }

                guard invalidTargetBranchList.isEmpty else {
                    return MergeCheckResult(mergedPathList: [], invalidTargetBranchList: invalidTargetBranchList)
                }
                return MergeCheckResult(
                    mergedPathList: MergedWorktreePaths.compute(worktreeList: worktreeList, mergedBranchSets: mergedBranchSets),
                    invalidTargetBranchList: []
                )
            }
        )
    }()
}
