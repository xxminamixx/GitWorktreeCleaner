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
}
