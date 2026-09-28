//
//  GitWorktreeServiceClient.swift
//  GitWorktreeCleaner
//

import Dependencies
import DependenciesMacros
import Foundation
import Localization
import Models

public enum GitWorktreeError: LocalizedError {
    case notAGitRepository
    case commandFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notAGitRepository:
            return String(localized: Constant.ErrorAlert.notAGitRepository)
        case .commandFailed(let message):
            return message
        }
    }
}

public struct MergeCheckResult: Sendable {
    public let mergedPaths: Set<String>
    public let invalidTargetBranches: [String]

    public init(mergedPaths: Set<String>, invalidTargetBranches: [String]) {
        self.mergedPaths = mergedPaths
        self.invalidTargetBranches = invalidTargetBranches
    }
}

@DependencyClient
public struct GitWorktreeServiceClient: Sendable {
    public var listWorktrees: @Sendable (_ repoPath: String) throws -> [Worktree]
    public var remove: @Sendable (_ worktreePath: String, _ repoPath: String) -> Result<Void, GitWorktreeError> = { _, _ in .success(()) }
    public var branchExists: @Sendable (_ ref: String, _ repoPath: String) -> Bool = { _, _ in false }
    /// Checks which worktrees are merged into every branch in `targetBranches`.
    /// A target branch that no longer resolves (e.g. deleted upstream after
    /// being registered) is reported via `invalidTargetBranches` instead of
    /// throwing; while any target is invalid nothing can be confirmed "merged
    /// into all", so `mergedPaths` comes back empty.
    public var mergeCheckResult: @Sendable (_ worktrees: [Worktree], _ targetBranches: [String], _ repoPath: String) -> MergeCheckResult = { _, _, _ in
        MergeCheckResult(mergedPaths: [], invalidTargetBranches: [])
    }
}

extension GitWorktreeServiceClient: TestDependencyKey {
    public static let testValue = Self()
}

extension DependencyValues {
    public var gitWorktreeServiceClient: GitWorktreeServiceClient {
        get { self[GitWorktreeServiceClient.self] }
        set { self[GitWorktreeServiceClient.self] = newValue }
    }
}
