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
/// repository list via `repositoryListDidChange(_:)`.
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
    @Published private(set) var mergeTargetBranchListByRepo: [String: [String]] = [:]

    @Dependency(\.userDefaultsClient) private var userDefaults

    private static let selectedRepositoryKey = "GitWorktreeCleaner.selectedRepository"
    private static let mergeTargetBranchListKey = "GitWorktreeCleaner.mergeTargetBranches"

    init() {
        selectedRepository = userDefaults.string(Self.selectedRepositoryKey)
        if let data = userDefaults.data(Self.mergeTargetBranchListKey),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            mergeTargetBranchListByRepo = decoded
        }
    }

    /// Called whenever `RepositoryListView` reports the registered repository
    /// list changed, so selection and stored merge-target branches stay
    /// consistent with which repositories actually still exist.
    func repositoryListDidChange(_ repositoryList: [String]) {
        hasRepositories = !repositoryList.isEmpty
        if let selectedRepository, !repositoryList.contains(selectedRepository) {
            self.selectedRepository = repositoryList.first
        } else if selectedRepository == nil {
            selectedRepository = repositoryList.first
        }

        let pruned = mergeTargetBranchListByRepo.filter { repositoryList.contains($0.key) }
        if pruned.count != mergeTargetBranchListByRepo.count {
            mergeTargetBranchListByRepo = pruned
            persistMergeTargetBranchList()
        }
    }

    func mergeTargetBranchList(for repoPath: String) -> [String] {
        mergeTargetBranchListByRepo[repoPath] ?? []
    }

    func setMergeTargetBranchList(_ branchList: [String], for repoPath: String) {
        if branchList.isEmpty {
            mergeTargetBranchListByRepo.removeValue(forKey: repoPath)
        } else {
            mergeTargetBranchListByRepo[repoPath] = branchList
        }
        persistMergeTargetBranchList()
    }

    private func persistMergeTargetBranchList() {
        if let data = try? JSONEncoder().encode(mergeTargetBranchListByRepo) {
            userDefaults.setData(Self.mergeTargetBranchListKey, data)
        }
    }
}
