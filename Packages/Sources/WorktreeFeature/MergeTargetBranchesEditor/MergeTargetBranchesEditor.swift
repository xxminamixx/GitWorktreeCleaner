//
//  MergeTargetBranchesEditor.swift
//  GitWorktreeCleaner
//

import Localization
import Models
import SwiftUI

/// Sheet for editing the branches a worktree's branch must be merged into
/// (all of them) to be flagged "merged" and safe to remove. 1:1 with
/// `MergeTargetBranchesEditorViewModel`.
///
/// A branch is verified against the repository when it's added, so a typo
/// or nonexistent name is rejected on the spot. A branch that was valid at
/// registration but no longer resolves (e.g. deleted upstream) is kept and
/// flagged with a "not found" tag instead, since it isn't necessarily wrong
/// to leave configured (it may come back after a fetch).
struct MergeTargetBranchesEditor: View {
    let onSave: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MergeTargetBranchesEditorViewModel
    @State private var newBranch: String = ""

    init(repoPath: String, branchList: [String], onSave: @escaping ([String]) -> Void) {
        self.onSave = onSave
        _viewModel = StateObject(wrappedValue: MergeTargetBranchesEditorViewModel(repoPath: repoPath, branchList: branchList))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Constant.MergeTargetEditor.title)
                .font(.headline)

            HStack(spacing: 8) {
                TextField(Constant.MergeTargetEditor.newBranchPlaceholder, text: $newBranch)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { addBranch() }
                Button(Constant.MergeTargetEditor.addButton) { addBranch() }
                    .disabled(BranchList.parse(newBranch).isEmpty)
            }

            if let addErrorMessage = viewModel.addErrorMessage {
                Text(addErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if viewModel.draft.isEmpty {
                Text(Constant.MergeTargetEditor.emptyList)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                List {
                    ForEach(viewModel.draft, id: \.self) { branch in
                        HStack(spacing: 8) {
                            Text(branch)
                                .font(.body.monospaced())
                            if viewModel.notFoundBranches.contains(branch) {
                                StatusTag(text: Constant.Tag.notFound, color: .red)
                            }
                            Spacer()
                            Button {
                                viewModel.removeBranch(branch)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(minHeight: 120, maxHeight: 240)
            }

            HStack {
                Spacer()
                Button(Constant.ConfirmDelete.cancelButton) { dismiss() }
                Button(Constant.MergeTargetEditor.saveButton) {
                    onSave(viewModel.draft)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(minWidth: 380)
        .onAppear {
            viewModel.checkNotFoundBranches()
        }
    }

    private func addBranch() {
        if viewModel.addBranch(newBranch) {
            newBranch = ""
        }
    }
}
