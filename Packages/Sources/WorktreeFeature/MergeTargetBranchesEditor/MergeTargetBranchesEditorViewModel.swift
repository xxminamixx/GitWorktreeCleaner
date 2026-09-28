//
//  MergeTargetBranchesEditorViewModel.swift
//  GitWorktreeCleaner
//

import Combine
import Dependencies
import Foundation
import GitWorktreeServiceClient
import Localization
import Models

/// Backs `MergeTargetBranchesEditor`. Owns the draft branch list, verifies
/// each entry against the repository, and tracks which registered branches
/// no longer resolve.
@MainActor
final class MergeTargetBranchesEditorViewModel: ObservableObject {
    let repoPath: String
    @Published private(set) var draft: [String]
    @Published private(set) var notFoundBranches: Set<String> = []
    @Published private(set) var addErrorMessage: String?

    @Dependency(\.gitWorktreeServiceClient) private var service

    init(repoPath: String, branchList: [String]) {
        self.repoPath = repoPath
        self.draft = branchList
    }

    func checkNotFoundBranches() {
        notFoundBranches = Set(draft.filter { !service.branchExists($0, repoPath) })
    }

    /// Parses and adds the entries in `input` (comma-separated), verifying
    /// each against the repository. Returns `true` if every entry was valid
    /// (the caller can then clear its text field).
    @discardableResult
    func addBranch(_ input: String) -> Bool {
        let entries = BranchList.parse(input)
        guard !entries.isEmpty else { return false }

        var missing: [String] = []
        for entry in entries where !draft.contains(entry) {
            if service.branchExists(entry, repoPath) {
                draft.append(entry)
            } else {
                missing.append(entry)
            }
        }

        if missing.isEmpty {
            addErrorMessage = nil
            return true
        } else {
            addErrorMessage = String(localized: Constant.MergeTargetEditor.branchNotFound(branches: BranchList.format(missing)))
            return false
        }
    }

    func removeBranch(_ branch: String) {
        draft.removeAll { $0 == branch }
        notFoundBranches.remove(branch)
    }
}
