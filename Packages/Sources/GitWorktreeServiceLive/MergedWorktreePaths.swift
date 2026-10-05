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
///
/// `targetHeadSHASet` holds the current tip commit of every target branch.
/// `git branch --merged <target>` reports a branch as merged whenever its
/// tip is merely *reachable* from `target` — which is trivially true for a
/// worktree that was just branched off `target` and has no commits of its
/// own yet (its tip SHA equals `target`'s). That state is indistinguishable
/// from an actual merge, so a worktree whose head matches a target's head
/// exactly is excluded rather than risk telling the user brand-new work is
/// "merged" and safe to delete.
enum MergedWorktreePaths {
    static func compute(worktreeList: [Worktree], mergedBranchSets: [Set<String>], targetHeadSHASet: Set<String> = []) -> Set<String> {
        guard !mergedBranchSets.isEmpty else { return [] }
        var result: Set<String> = []
        for worktree in worktreeList where !worktree.isMain {
            guard let branchName = worktree.shortBranchName else { continue }
            if let headSHA = worktree.headSHA, targetHeadSHASet.contains(headSHA) { continue }
            if mergedBranchSets.allSatisfy({ $0.contains(branchName) }) {
                result.insert(worktree.path)
            }
        }
        return result
    }
}
