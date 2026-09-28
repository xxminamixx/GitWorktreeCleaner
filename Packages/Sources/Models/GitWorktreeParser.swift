//
//  GitWorktreeParser.swift
//  GitWorktreeCleaner
//

import Foundation

public enum GitWorktreeParser {
    /// Parses the output of `git worktree list --porcelain`.
    public static func parse(_ output: String) -> [Worktree] {
        var result: [Worktree] = []

        var path: String?
        var head: String?
        var branch: String?
        var isBare = false
        var isDetached = false
        var isLocked = false
        var lockReason: String?
        var isPrunable = false
        var prunableReason: String?

        func flush() {
            guard let currentPath = path else { return }
            result.append(
                Worktree(
                    path: currentPath,
                    headSHA: head,
                    branch: branch,
                    isBare: isBare,
                    isDetached: isDetached,
                    isLocked: isLocked,
                    lockReason: lockReason,
                    isPrunable: isPrunable,
                    prunableReason: prunableReason
                )
            )
            path = nil
            head = nil
            branch = nil
            isBare = false
            isDetached = false
            isLocked = false
            lockReason = nil
            isPrunable = false
            prunableReason = nil
        }

        for rawLine in output.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(rawLine)
            if line.isEmpty {
                flush()
                continue
            }
            if line.hasPrefix("worktree ") {
                flush()
                path = String(line.dropFirst("worktree ".count))
            } else if line.hasPrefix("HEAD ") {
                head = String(line.dropFirst("HEAD ".count))
            } else if line.hasPrefix("branch ") {
                branch = String(line.dropFirst("branch ".count))
            } else if line == "bare" {
                isBare = true
            } else if line == "detached" {
                isDetached = true
            } else if line.hasPrefix("locked") {
                isLocked = true
                let reason = line.dropFirst("locked".count).trimmingCharacters(in: .whitespaces)
                lockReason = reason.isEmpty ? nil : reason
            } else if line.hasPrefix("prunable") {
                isPrunable = true
                let reason = line.dropFirst("prunable".count).trimmingCharacters(in: .whitespaces)
                prunableReason = reason.isEmpty ? nil : reason
            }
        }
        flush()

        if !result.isEmpty {
            result[0].isMain = true
        }
        return result
    }
}
