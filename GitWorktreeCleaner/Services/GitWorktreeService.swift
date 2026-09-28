//
//  GitWorktreeService.swift
//  GitWorktreeCleaner
//

import Foundation

enum GitWorktreeError: LocalizedError {
    case notAGitRepository
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAGitRepository:
            return String(localized: Constant.ErrorAlert.notAGitRepository)
        case .commandFailed(let message):
            return message
        }
    }
}

struct GitWorktreeService: Sendable {
    private let cli = GitCLI()

    func listWorktrees(repoPath: String) throws -> [Worktree] {
        let result = try cli.run(["worktree", "list", "--porcelain"], in: repoPath)
        guard result.succeeded else {
            let message = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            if message.contains("not a git repository") {
                throw GitWorktreeError.notAGitRepository
            }
            throw GitWorktreeError.commandFailed(message.isEmpty ? String(localized: Constant.ErrorAlert.worktreeListFailed) : message)
        }
        return GitWorktreeParser.parse(result.stdout)
    }

    func remove(worktreePath: String, repoPath: String) -> Result<Void, GitWorktreeError> {
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
    }

    /// Whether `ref` resolves to a valid git object (local branch, remote-tracking
    /// branch, tag, or commit) in `repoPath`.
    func branchExists(_ ref: String, repoPath: String) -> Bool {
        (try? cli.run(["rev-parse", "--verify", "--quiet", ref], in: repoPath))?.succeeded == true
    }

    struct MergeCheckResult: Sendable {
        let mergedPaths: Set<String>
        let invalidTargetBranches: [String]
    }

    /// Checks which worktrees are merged into every branch in `targetBranches`.
    /// A target branch that no longer resolves (e.g. deleted upstream after
    /// being registered) is reported via `invalidTargetBranches` instead of
    /// throwing; while any target is invalid nothing can be confirmed "merged
    /// into all", so `mergedPaths` comes back empty.
    func mergeCheckResult(worktrees: [Worktree], targetBranches: [String], repoPath: String) -> MergeCheckResult {
        guard !targetBranches.isEmpty else { return MergeCheckResult(mergedPaths: [], invalidTargetBranches: []) }

        var mergedBranchSets: [Set<String>] = []
        var invalidTargetBranches: [String] = []
        for target in targetBranches {
            if let names = try? mergedBranchNames(mergedInto: target, repoPath: repoPath) {
                mergedBranchSets.append(names)
            } else {
                invalidTargetBranches.append(target)
            }
        }

        guard invalidTargetBranches.isEmpty else {
            return MergeCheckResult(mergedPaths: [], invalidTargetBranches: invalidTargetBranches)
        }
        return MergeCheckResult(
            mergedPaths: Self.mergedWorktreePaths(worktrees: worktrees, mergedBranchSets: mergedBranchSets),
            invalidTargetBranches: []
        )
    }

    /// Names of local branches already merged into `target`.
    private func mergedBranchNames(mergedInto target: String, repoPath: String) throws -> Set<String> {
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

    /// Pure intersection logic, factored out for testing without a real git repo.
    /// A worktree is "merged" when its branch is present in every set in
    /// `mergedBranchSets` (one set per target branch). The main worktree is
    /// always excluded: it can't be removed regardless of merge status, so
    /// flagging it "merged" would be misleading.
    static func mergedWorktreePaths(worktrees: [Worktree], mergedBranchSets: [Set<String>]) -> Set<String> {
        guard !mergedBranchSets.isEmpty else { return [] }
        var result: Set<String> = []
        for worktree in worktrees where !worktree.isMain {
            guard let branchName = worktree.shortBranchName else { continue }
            if mergedBranchSets.allSatisfy({ $0.contains(branchName) }) {
                result.insert(worktree.path)
            }
        }
        return result
    }
}
