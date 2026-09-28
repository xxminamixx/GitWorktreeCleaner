//
//  Worktree.swift
//  GitWorktreeCleaner
//

import Foundation

struct Worktree: Identifiable, Hashable, Sendable {
    var id: String { path }

    let path: String
    let headSHA: String?
    let branch: String?
    let isBare: Bool
    let isDetached: Bool
    let isLocked: Bool
    let lockReason: String?
    let isPrunable: Bool
    let prunableReason: String?
    var isMain: Bool = false

    var displayName: String {
        URL(fileURLWithPath: path).lastPathComponent
    }

    var shortSHA: String {
        guard let headSHA else { return "-" }
        return String(headSHA.prefix(7))
    }

    var branchDisplay: String {
        if isBare { return "(bare)" }
        if let branch {
            return branch.replacingOccurrences(of: "refs/heads/", with: "")
        }
        if isDetached { return "detached" }
        return "-"
    }
}
