//
//  Worktree.swift
//  GitWorktreeCleaner
//

import Foundation

public struct Worktree: Identifiable, Hashable, Sendable {
    public var id: String { path }

    public let path: String
    public let headSHA: String?
    public let branch: String?
    public let isBare: Bool
    public let isDetached: Bool
    public let isLocked: Bool
    public let lockReason: String?
    public let isPrunable: Bool
    public let prunableReason: String?
    public var isMain: Bool = false

    public init(
        path: String,
        headSHA: String?,
        branch: String?,
        isBare: Bool,
        isDetached: Bool,
        isLocked: Bool,
        lockReason: String?,
        isPrunable: Bool,
        prunableReason: String?,
        isMain: Bool = false
    ) {
        self.path = path
        self.headSHA = headSHA
        self.branch = branch
        self.isBare = isBare
        self.isDetached = isDetached
        self.isLocked = isLocked
        self.lockReason = lockReason
        self.isPrunable = isPrunable
        self.prunableReason = prunableReason
        self.isMain = isMain
    }

    public var displayName: String {
        URL(fileURLWithPath: path).lastPathComponent
    }

    public var shortSHA: String {
        guard let headSHA else { return "-" }
        return String(headSHA.prefix(7))
    }

    public var branchDisplay: String {
        if isBare { return "(bare)" }
        if let branch {
            return branch.replacingOccurrences(of: "refs/heads/", with: "")
        }
        if isDetached { return "detached" }
        return "-"
    }

    /// The local branch name (without the `refs/heads/` prefix), or `nil`
    /// for bare/detached worktrees that have no branch to check merges for.
    public var shortBranchName: String? {
        guard let branch, !isBare else { return nil }
        return branch.replacingOccurrences(of: "refs/heads/", with: "")
    }
}
