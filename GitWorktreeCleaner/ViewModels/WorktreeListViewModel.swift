//
//  WorktreeListViewModel.swift
//  GitWorktreeCleaner
//

import Combine
import Foundation

@MainActor
final class WorktreeListViewModel: ObservableObject {
    @Published private(set) var repoPath: String?
    @Published private(set) var worktrees: [Worktree] = []
    @Published var selection: Set<String> = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var showRemoveConfirmation = false
    @Published private(set) var mergeTargetBranches: [String] = []
    /// Paths of worktrees whose branch is already merged into every branch
    /// in `mergeTargetBranches`, i.e. safe to remove.
    @Published private(set) var mergedPaths: Set<String> = []
    /// Target branches in `mergeTargetBranches` that no longer resolve to a
    /// valid ref (e.g. deleted upstream after being registered).
    @Published private(set) var invalidMergeTargetBranches: [String] = []

    private let service = GitWorktreeService()

    var selectableWorktrees: [Worktree] {
        worktrees.filter { !$0.isMain }
    }

    var canRemoveSelection: Bool {
        !selection.isEmpty && !isLoading
    }

    /// Switches to a different repository, e.g. after a sidebar selection change.
    /// `mergeTargetBranches` is passed in alongside the path so the very
    /// first `refresh()` already checks merges against the right branches.
    func setRepository(_ path: String?, mergeTargetBranches: [String] = []) {
        guard repoPath != path else { return }
        repoPath = path
        worktrees = []
        selection.removeAll()
        errorMessage = nil
        mergedPaths = []
        invalidMergeTargetBranches = []
        self.mergeTargetBranches = mergeTargetBranches
        if path != nil {
            refresh()
        }
    }

    /// Updates the branches worktree branches must be merged into, and
    /// recomputes which currently-listed worktrees qualify.
    func updateMergeTargetBranches(_ branches: [String]) {
        guard mergeTargetBranches != branches else { return }
        mergeTargetBranches = branches
        Task {
            await recomputeMerged()
        }
    }

    func refresh() {
        guard let repoPath else { return }
        isLoading = true
        errorMessage = nil
        let service = self.service

        Task {
            do {
                let list = try await Task.detached(priority: .userInitiated) {
                    try service.listWorktrees(repoPath: repoPath)
                }.value
                worktrees = list
                selection.formIntersection(Set(list.map(\.path)))
                await recomputeMerged()
            } catch {
                errorMessage = error.localizedDescription
                worktrees = []
                selection.removeAll()
                mergedPaths = []
                invalidMergeTargetBranches = []
            }
            isLoading = false
        }
    }

    private func recomputeMerged() async {
        guard let repoPath, !mergeTargetBranches.isEmpty else {
            mergedPaths = []
            invalidMergeTargetBranches = []
            return
        }
        let service = self.service
        let targetBranches = mergeTargetBranches
        let list = worktrees
        let result = await Task.detached(priority: .userInitiated) {
            service.mergeCheckResult(worktrees: list, targetBranches: targetBranches, repoPath: repoPath)
        }.value
        mergedPaths = result.mergedPaths
        invalidMergeTargetBranches = result.invalidTargetBranches
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
        selection = Set(selectableWorktrees.map(\.path))
    }

    func clearSelection() {
        selection.removeAll()
    }

    func requestRemoveSelected() {
        guard canRemoveSelection else { return }
        showRemoveConfirmation = true
    }

    func confirmRemoveSelected() {
        guard let repoPath else { return }
        let targets = worktrees.filter { selection.contains($0.path) && !$0.isMain }
        guard !targets.isEmpty else { return }

        isLoading = true
        let service = self.service

        Task {
            var failures: [String] = []
            for worktree in targets {
                let result = await Task.detached(priority: .userInitiated) {
                    service.remove(worktreePath: worktree.path, repoPath: repoPath)
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
