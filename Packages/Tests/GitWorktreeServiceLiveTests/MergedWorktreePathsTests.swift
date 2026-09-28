import Models
import Testing
@testable import GitWorktreeServiceLive

struct MergedWorktreePathsTests {
    @Test func mergedWorktreePathsRequiresEveryTargetBranch() {
        let fullyMerged = makeWorktree(path: "/repo/merged", branch: "refs/heads/feature/done")
        let partiallyMerged = makeWorktree(path: "/repo/partial", branch: "refs/heads/feature/wip")
        let detached = makeWorktree(path: "/repo/detached", branch: nil, isDetached: true)

        let developMerged: Set<String> = ["main", "feature/done", "feature/wip"]
        let baseMerged: Set<String> = ["main", "feature/done"]

        let result = MergedWorktreePaths.compute(
            worktrees: [fullyMerged, partiallyMerged, detached],
            mergedBranchSets: [developMerged, baseMerged]
        )

        #expect(result == [fullyMerged.path])
    }

    @Test func mergedWorktreePathsIsEmptyWithoutTargetBranches() {
        let worktree = makeWorktree(path: "/repo/a", branch: "refs/heads/main")
        #expect(MergedWorktreePaths.compute(worktrees: [worktree], mergedBranchSets: []).isEmpty)
    }

    @Test func mergedWorktreePathsExcludesMainWorktree() {
        var main = makeWorktree(path: "/repo/main", branch: "refs/heads/develop")
        main.isMain = true
        let linked = makeWorktree(path: "/repo/linked", branch: "refs/heads/feature/done")

        let developMerged: Set<String> = ["develop", "feature/done"]

        let result = MergedWorktreePaths.compute(
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
