//
//  WorktreeListViewModel.swift
//  GitWorktreeCleaner
//

import Combine
import Dependencies
import Foundation
import GitWorktreeServiceClient
import Localization
import Models

/// Backs `WorktreeListView`. One instance per selected repository (`repoPath`
/// is fixed at init; `WorktreeListView` uses `.id(repoPath)` so a new instance
/// is created whenever the selected repository changes).
@MainActor
final class WorktreeListViewModel: ObservableObject {
    let repoPath: String
    @Published private(set) var worktreeList: [Worktree] = []
    @Published var selection: Set<String> = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var showRemoveConfirmation = false
    @Published private(set) var mergeTargetBranchList: [String]
    /// Paths of worktrees whose branch is already merged into every branch
    /// in `mergeTargetBranchList`, i.e. safe to remove.
    @Published private(set) var mergedPathList: Set<String> = []
    /// Target branches in `mergeTargetBranchList` that no longer resolve to a
    /// valid ref (e.g. deleted upstream after being registered).
    @Published private(set) var invalidMergeTargetBranchList: [String] = []

    @Dependency(\.gitWorktreeServiceClient) private var service

    init(repoPath: String, mergeTargetBranchList: [String] = []) {
        self.repoPath = repoPath
        self.mergeTargetBranchList = mergeTargetBranchList
    }

    var selectableWorktreeList: [Worktree] {
        worktreeList.filter { !$0.isMain }
    }

    var canRemoveSelection: Bool {
        !selection.isEmpty && !isLoading
    }

    /// Updates the branches worktree branches must be merged into, and
    /// recomputes which currently-listed worktrees qualify.
    func updateMergeTargetBranchList(_ branchList: [String]) {
        guard mergeTargetBranchList != branchList else { return }
        mergeTargetBranchList = branchList
        Task {
            await recomputeMerged()
        }
    }

    func refresh() {
        isLoading = true
        errorMessage = nil
        let service = self.service
        let repoPath = self.repoPath

        Task {
            do {
                let list = try await Task.detached(priority: .userInitiated) {
                    try service.listWorktrees(repoPath)
                }.value
                worktreeList = list
                selection.formIntersection(Set(list.map(\.path)))
                await recomputeMerged()
            } catch {
                errorMessage = error.localizedDescription
                worktreeList = []
                selection.removeAll()
                mergedPathList = []
                invalidMergeTargetBranchList = []
            }
            isLoading = false
        }
    }

    private func recomputeMerged() async {
        guard !mergeTargetBranchList.isEmpty else {
            mergedPathList = []
            invalidMergeTargetBranchList = []
            return
        }
        let service = self.service
        let targetBranchList = mergeTargetBranchList
        let list = worktreeList
        let repoPath = self.repoPath
        let result = await Task.detached(priority: .userInitiated) {
            service.mergeCheckResult(list, targetBranchList, repoPath)
        }.value
        mergedPathList = result.mergedPathList
        invalidMergeTargetBranchList = result.invalidTargetBranchList
    }

    func toggleSelection(for worktree: Worktree, isSelected: Bool) {
        guard !worktree.isMain else { return }
        if isSelected {
            selection.insert(worktree.path)
        } else {
            selection.remove(worktree.path)
        }
    }

    func selectAll() {
        selection = Set(selectableWorktreeList.map(\.path))
    }

    func clearSelection() {
        selection.removeAll()
    }

    func requestRemoveSelected() {
        guard canRemoveSelection else { return }
        showRemoveConfirmation = true
    }

    func confirmRemoveSelected() {
        let targets = worktreeList.filter { selection.contains($0.path) && !$0.isMain }
        guard !targets.isEmpty else { return }

        isLoading = true
        let service = self.service
        let repoPath = self.repoPath

        Task {
            var failures: [String] = []
            for worktree in targets {
                let result = await Task.detached(priority: .userInitiated) {
                    service.remove(worktree.path, repoPath)
                }.value
                if case .failure(let error) = result {
                    failures.append("\(worktree.displayName): \(error.localizedDescription)")
                }
            }
            selection.removeAll()
            errorMessage = failures.isEmpty
                ? nil
                : String(localized: Constant.ErrorAlert.removalFailuresHeader) + "\n" + failures.joined(separator: "\n")
            refresh()
        }
    }
}
