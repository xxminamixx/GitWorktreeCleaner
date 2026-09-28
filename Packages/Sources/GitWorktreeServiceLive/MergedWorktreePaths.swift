//
//  MergedWorktreePaths.swift
//  GitWorktreeCleaner
//

import Models

/// Pure intersection logic, factored out for testing without a real git repo.
/// A worktree is "merged" when its branch is present in every set in
/// `mergedBranchSets` (one set per target branch). The main worktree is
/// always excluded: it can't be removed regardless of merge status, so
/// flagging it "merged" would be misleading.
enum MergedWorktreePaths {
    static func compute(worktrees: [Worktree], mergedBranchSets: [Set<String>]) -> Set<String> {
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
