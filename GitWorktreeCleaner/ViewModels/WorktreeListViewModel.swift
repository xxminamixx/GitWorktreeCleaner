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

    private let service = GitWorktreeService()

    var selectableWorktrees: [Worktree] {
        worktrees.filter { !$0.isMain }
    }

    var canRemoveSelection: Bool {
        !selection.isEmpty && !isLoading
    }

    /// Switches to a different repository, e.g. after a sidebar selection change.
    func setRepository(_ path: String?) {
        guard repoPath != path else { return }
        repoPath = path
        worktrees = []
        selection.removeAll()
        errorMessage = nil
        if path != nil {
            refresh()
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
            } catch {
                errorMessage = error.localizedDescription
                worktrees = []
                selection.removeAll()
            }
            isLoading = false
        }
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
