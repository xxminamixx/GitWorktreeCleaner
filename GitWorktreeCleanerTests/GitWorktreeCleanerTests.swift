//
//  GitWorktreeCleanerTests.swift
//  GitWorktreeCleanerTests
//
//  Created by minami kyohei on 2026/09/28.
//

import Testing
@testable import GitWorktreeCleaner

struct GitWorktreeCleanerTests {

    @Test func branchListParsesAndTrimsEntries() async throws {
        let branches = BranchList.parse(" develop, base/xxxx ,, ")
        #expect(branches == ["develop", "base/xxxx"])
    }

    @Test func branchListFormatsForDisplay() async throws {
        #expect(BranchList.format(["develop", "base/xxxx"]) == "develop, base/xxxx")
    }

    @Test func mergedWorktreePathsRequiresEveryTargetBranch() async throws {
        let fullyMerged = makeWorktree(path: "/repo/merged", branch: "refs/heads/feature/done")
        let partiallyMerged = makeWorktree(path: "/repo/partial", branch: "refs/heads/feature/wip")
        let detached = makeWorktree(path: "/repo/detached", branch: nil, isDetached: true)

        let developMerged: Set<String> = ["main", "feature/done", "feature/wip"]
        let baseMerged: Set<String> = ["main", "feature/done"]

        let result = GitWorktreeService.mergedWorktreePaths(
            worktrees: [fullyMerged, partiallyMerged, detached],
            mergedBranchSets: [developMerged, baseMerged]
        )

        #expect(result == [fullyMerged.path])
    }

    @Test func mergedWorktreePathsIsEmptyWithoutTargetBranches() async throws {
        let worktree = makeWorktree(path: "/repo/a", branch: "refs/heads/main")
        #expect(GitWorktreeService.mergedWorktreePaths(worktrees: [worktree], mergedBranchSets: []).isEmpty)
    }

    @Test func mergedWorktreePathsExcludesMainWorktree() async throws {
        var main = makeWorktree(path: "/repo/main", branch: "refs/heads/develop")
        main.isMain = true
        let linked = makeWorktree(path: "/repo/linked", branch: "refs/heads/feature/done")

        let developMerged: Set<String> = ["develop", "feature/done"]

        let result = GitWorktreeService.mergedWorktreePaths(
            worktrees: [main, linked],
            mergedBranchSets: [developMerged]
        )

        #expect(result == [linked.path])
    }

    private func makeWorktree(path: String, branch: String?, isDetached: Bool = false) -> Worktree {
        Worktree(
            path: path,
            headSHA: "abc123",
            branch: branch,
            isBare: false,
            isDetached: isDetached,
            isLocked: false,
            lockReason: nil,
            isPrunable: false,
            prunableReason: nil
        )
    }
}
