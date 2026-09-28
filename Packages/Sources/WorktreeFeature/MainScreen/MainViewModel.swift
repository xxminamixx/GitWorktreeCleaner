//
//  MainViewModel.swift
//  GitWorktreeCleaner
//

import Combine
import Dependencies
import Foundation
import UserDefaultsClient

/// Backs `MainScreen`. Owns the selected repository and per-repo merge-target
/// branches — the state shared between the sidebar (`RepositoryListView`) and
/// the detail pane (`WorktreeListView`) — kept in sync with the registered
/// repository list via `repositoriesDidChange(_:)`.
@MainActor
final class MainViewModel: ObservableObject {
    @Published private(set) var hasRepositories = false
    @Published var selectedRepository: String? {
        didSet {
            guard selectedRepository != oldValue else { return }
            userDefaults.setString(Self.selectedRepositoryKey, selectedRepository)
        }
    }
    /// Branches a worktree's branch must be merged into (for every entry)
    /// to be flagged as safe to remove, keyed by repository path.
    @Published private(set) var mergeTargetBranchesByRepo: [String: [String]] = [:]

    @Dependency(\.userDefaultsClient) private var userDefaults

    private static let selectedRepositoryKey = "GitWorktreeCleaner.selectedRepository"
    private static let mergeTargetBranchesKey = "GitWorktreeCleaner.mergeTargetBranches"

    init() {
        selectedRepository = userDefaults.string(Self.selectedRepositoryKey)
        if let data = userDefaults.data(Self.mergeTargetBranchesKey),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            mergeTargetBranchesByRepo = decoded
        }
    }

    /// Called whenever `RepositoryListView` reports the registered repository
    /// list changed, so selection and stored merge-target branches stay
    /// consistent with which repositories actually still exist.
    func repositoriesDidChange(_ repositories: [String]) {
        hasRepositories = !repositories.isEmpty
        if let selectedRepository, !repositories.contains(selectedRepository) {
            self.selectedRepository = repositories.first
        } else if selectedRepository == nil {
            selectedRepository = repositories.first
        }

        let pruned = mergeTargetBranchesByRepo.filter { repositories.contains($0.key) }
        if pruned.count != mergeTargetBranchesByRepo.count {
            mergeTargetBranchesByRepo = pruned
            persistMergeTargetBranches()
        }
    }

    func mergeTargetBranches(for repoPath: String) -> [String] {
        mergeTargetBranchesByRepo[repoPath] ?? []
    }

    func setMergeTargetBranches(_ branches: [String], for repoPath: String) {
        if branches.isEmpty {
            mergeTargetBranchesByRepo.removeValue(forKey: repoPath)
        } else {
            mergeTargetBranchesByRepo[repoPath] = branches
        }
        persistMergeTargetBranches()
    }

    private func persistMergeTargetBranches() {
        if let data = try? JSONEncoder().encode(mergeTargetBranchesByRepo) {
            userDefaults.setData(Self.mergeTargetBranchesKey, data)
        }
    }
}
