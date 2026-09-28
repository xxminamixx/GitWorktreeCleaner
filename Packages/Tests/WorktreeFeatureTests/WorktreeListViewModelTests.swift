//
//  WorktreeListViewModelTests.swift
//  GitWorktreeCleaner
//

import Dependencies
import Foundation
import GitWorktreeServiceClient
import Models
import Testing
@testable import WorktreeFeature

@MainActor
struct WorktreeListViewModelTests {
    @Test func initSetsRepoPathAndDefaultsMergeTargetBranchListToEmpty() {
        let viewModel = WorktreeListViewModel(repoPath: "/repo")

        #expect(viewModel.repoPath == "/repo")
        #expect(viewModel.mergeTargetBranchList == [])
        #expect(viewModel.worktreeList.isEmpty)
    }

    @Test func selectableWorktreeListExcludesMainAfterRefresh() async {
        let main = makeWorktree(path: "/repo/main", isMain: true)
        let feature = makeWorktree(path: "/repo/feature")

        let viewModel = withDependencies {
            $0.gitWorktreeServiceClient.listWorktrees = { _ in [main, feature] }
        } operation: {
            WorktreeListViewModel(repoPath: "/repo")
        }

        viewModel.refresh()
        await waitUntil { !viewModel.isLoading }

        #expect(viewModel.worktreeList.map(\.path) == ["/repo/main", "/repo/feature"])
        #expect(viewModel.selectableWorktreeList.map(\.path) == ["/repo/feature"])
    }

    @Test func refreshIntersectsSelectionWithNewlyLoadedWorktrees() async {
        let kept = makeWorktree(path: "/repo/kept")

        let viewModel = withDependencies {
            $0.gitWorktreeServiceClient.listWorktrees = { _ in [kept] }
        } operation: {
            WorktreeListViewModel(repoPath: "/repo")
        }
        viewModel.selection = ["/repo/kept", "/repo/stale"]

        viewModel.refresh()
        await waitUntil { !viewModel.isLoading }

        #expect(viewModel.selection == ["/repo/kept"])
        #expect(viewModel.errorMessage == nil)
    }

    @Test func refreshFailurePopulatesErrorMessageAndClearsState() async {
        struct TestError: LocalizedError {
            var errorDescription: String? { "boom" }
        }

        let viewModel = withDependencies {
            $0.gitWorktreeServiceClient.listWorktrees = { _ in throw TestError() }
        } operation: {
            WorktreeListViewModel(repoPath: "/repo")
        }
        viewModel.selection = ["/repo/a"]

        viewModel.refresh()
        await waitUntil { !viewModel.isLoading }

        #expect(viewModel.worktreeList.isEmpty)
        #expect(viewModel.selection.isEmpty)
        #expect(viewModel.errorMessage == "boom")
    }

    @Test func updateMergeTargetBranchListRecomputesMergedAndInvalidBranches() async {
        let worktree = makeWorktree(path: "/repo/a")

        let viewModel = withDependencies {
            $0.gitWorktreeServiceClient.listWorktrees = { _ in [worktree] }
            $0.gitWorktreeServiceClient.mergeCheckResult = { _, targetBranchList, _ in
                targetBranchList == ["main"]
                    ? MergeCheckResult(mergedPathList: ["/repo/a"], invalidTargetBranchList: [])
                    : MergeCheckResult(mergedPathList: [], invalidTargetBranchList: ["ghost"])
            }
        } operation: {
            WorktreeListViewModel(repoPath: "/repo")
        }
        viewModel.refresh()
        await waitUntil { !viewModel.isLoading }

        viewModel.updateMergeTargetBranchList(["main"])
        await waitUntil { !viewModel.mergedPathList.isEmpty }
        #expect(viewModel.mergedPathList == ["/repo/a"])
        #expect(viewModel.invalidMergeTargetBranchList.isEmpty)

        viewModel.updateMergeTargetBranchList(["ghost"])
        await waitUntil { !viewModel.invalidMergeTargetBranchList.isEmpty }
        #expect(viewModel.mergedPathList.isEmpty)
        #expect(viewModel.invalidMergeTargetBranchList == ["ghost"])
    }

    @Test func updateMergeTargetBranchListToEmptyClearsMergedState() async {
        let worktree = makeWorktree(path: "/repo/a")
        let viewModel = withDependencies {
            $0.gitWorktreeServiceClient.listWorktrees = { _ in [worktree] }
            $0.gitWorktreeServiceClient.mergeCheckResult = { _, _, _ in
                MergeCheckResult(mergedPathList: ["/repo/a"], invalidTargetBranchList: [])
            }
        } operation: {
            WorktreeListViewModel(repoPath: "/repo", mergeTargetBranchList: ["main"])
        }
        viewModel.refresh()
        await waitUntil { !viewModel.mergedPathList.isEmpty }

        viewModel.updateMergeTargetBranchList([])
        await waitUntil { viewModel.mergedPathList.isEmpty }

        #expect(viewModel.mergedPathList.isEmpty)
        #expect(viewModel.invalidMergeTargetBranchList.isEmpty)
    }

    @Test func toggleSelectionIgnoresMainWorktreeButTracksOthers() {
        let main = makeWorktree(path: "/repo/main", isMain: true)
        let feature = makeWorktree(path: "/repo/feature")
        let viewModel = WorktreeListViewModel(repoPath: "/repo")

        viewModel.toggleSelection(for: main, isSelected: true)
        #expect(viewModel.selection.isEmpty)

        viewModel.toggleSelection(for: feature, isSelected: true)
        #expect(viewModel.selection == ["/repo/feature"])

        viewModel.toggleSelection(for: feature, isSelected: false)
        #expect(viewModel.selection.isEmpty)
    }

    @Test func selectAllSelectsOnlySelectableWorktreeListAndClearSelectionEmptiesIt() async {
        let main = makeWorktree(path: "/repo/main", isMain: true)
        let feature = makeWorktree(path: "/repo/feature")
        let viewModel = withDependencies {
            $0.gitWorktreeServiceClient.listWorktrees = { _ in [main, feature] }
        } operation: {
            WorktreeListViewModel(repoPath: "/repo")
        }
        viewModel.refresh()
        await waitUntil { !viewModel.isLoading }

        viewModel.selectAll()
        #expect(viewModel.selection == ["/repo/feature"])

        viewModel.clearSelection()
        #expect(viewModel.selection.isEmpty)
    }

    @Test func canRemoveSelectionRequiresNonEmptySelection() {
        let viewModel = WorktreeListViewModel(repoPath: "/repo")

        #expect(viewModel.canRemoveSelection == false)
        viewModel.selection = ["/repo/a"]
        #expect(viewModel.canRemoveSelection == true)
    }

    @Test func requestRemoveSelectedOnlyShowsConfirmationWhenRemovable() {
        let viewModel = WorktreeListViewModel(repoPath: "/repo")

        viewModel.requestRemoveSelected()
        #expect(viewModel.showRemoveConfirmation == false)

        viewModel.selection = ["/repo/a"]
        viewModel.requestRemoveSelected()
        #expect(viewModel.showRemoveConfirmation == true)
    }

    @Test func confirmRemoveSelectedCallsServiceForEachTargetAndClearsSelection() async {
        let a = makeWorktree(path: "/repo/a")
        let b = makeWorktree(path: "/repo/b")
        let removedPaths = Box<[String]>([])

        let viewModel = withDependencies {
            $0.gitWorktreeServiceClient.listWorktrees = { _ in [a, b] }
            $0.gitWorktreeServiceClient.remove = { path, _ in
                removedPaths.value.append(path)
                return path == "/repo/a" ? .success(()) : .failure(.commandFailed("nope"))
            }
        } operation: {
            WorktreeListViewModel(repoPath: "/repo")
        }
        viewModel.refresh()
        await waitUntil { !viewModel.isLoading }
        viewModel.selection = ["/repo/a", "/repo/b"]

        viewModel.confirmRemoveSelected()
        await waitUntil { !viewModel.isLoading }

        #expect(Set(removedPaths.value) == ["/repo/a", "/repo/b"])
        #expect(viewModel.selection.isEmpty)
    }

    @Test func confirmRemoveSelectedIsNoOpWithoutARemovableSelection() {
        let viewModel = WorktreeListViewModel(repoPath: "/repo")

        viewModel.confirmRemoveSelected()

        #expect(viewModel.isLoading == false)
    }
}
