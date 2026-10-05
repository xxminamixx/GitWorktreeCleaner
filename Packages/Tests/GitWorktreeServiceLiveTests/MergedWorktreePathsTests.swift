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
            worktreeList: [fullyMerged, partiallyMerged, detached],
            mergedBranchSets: [developMerged, baseMerged]
        )

        #expect(result == [fullyMerged.path])
    }

    @Test func mergedWorktreePathsIsEmptyWithoutTargetBranches() {
        let worktree = makeWorktree(path: "/repo/a", branch: "refs/heads/main")
        #expect(MergedWorktreePaths.compute(worktreeList: [worktree], mergedBranchSets: []).isEmpty)
    }

    @Test func mergedWorktreePathsExcludesBranchIdenticalToTargetHead() {
        // A worktree just branched off `main` with no commits of its own has
        // the same SHA as `main`, so `git branch --merged main` trivially
        // includes it even though nothing was actually merged.
        let freshlyBranched = makeWorktree(path: "/repo/fresh", branch: "refs/heads/fresh", headSHA: "main-sha")
        let genuinelyMerged = makeWorktree(path: "/repo/done", branch: "refs/heads/done", headSHA: "other-sha")

        let mainMerged: Set<String> = ["main", "fresh", "done"]

        let result = MergedWorktreePaths.compute(
            worktreeList: [freshlyBranched, genuinelyMerged],
            mergedBranchSets: [mainMerged],
            targetHeadSHASet: ["main-sha"]
        )

        #expect(result == [genuinelyMerged.path])
    }

    @Test func mergedWorktreePathsExcludesMainWorktree() {
        var main = makeWorktree(path: "/repo/main", branch: "refs/heads/develop")
        main.isMain = true
        let linked = makeWorktree(path: "/repo/linked", branch: "refs/heads/feature/done")

        let developMerged: Set<String> = ["develop", "feature/done"]

        let result = MergedWorktreePaths.compute(
            worktreeList: [main, linked],
            mergedBranchSets: [developMerged]
        )

        #expect(result == [linked.path])
    }

    private func makeWorktree(path: String, branch: String?, isDetached: Bool = false, headSHA: String = "abc123") -> Worktree {
        Worktree(
            path: path,
            headSHA: headSHA,
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
