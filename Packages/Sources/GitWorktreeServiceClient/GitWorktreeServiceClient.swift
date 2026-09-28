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
    public let mergedPathList: Set<String>
    public let invalidTargetBranchList: [String]

    public init(mergedPathList: Set<String>, invalidTargetBranchList: [String]) {
        self.mergedPathList = mergedPathList
        self.invalidTargetBranchList = invalidTargetBranchList
    }
}

@DependencyClient
public struct GitWorktreeServiceClient: Sendable {
    public var listWorktrees: @Sendable (_ repoPath: String) throws -> [Worktree]
    public var remove: @Sendable (_ worktreePath: String, _ repoPath: String) -> Result<Void, GitWorktreeError> = { _, _ in .success(()) }
    public var branchExists: @Sendable (_ ref: String, _ repoPath: String) -> Bool = { _, _ in false }
    /// Checks which worktrees are merged into every branch in `targetBranchList`.
    /// A target branch that no longer resolves (e.g. deleted upstream after
    /// being registered) is reported via `invalidTargetBranchList` instead of
    /// throwing; while any target is invalid nothing can be confirmed "merged
    /// into all", so `mergedPathList` comes back empty.
    public var mergeCheckResult: @Sendable (_ worktreeList: [Worktree], _ targetBranchList: [String], _ repoPath: String) -> MergeCheckResult = { _, _, _ in
        MergeCheckResult(mergedPathList: [], invalidTargetBranchList: [])
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
