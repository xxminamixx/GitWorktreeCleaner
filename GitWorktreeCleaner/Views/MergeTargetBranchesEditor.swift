//
//  MergeTargetBranchesEditor.swift
//  GitWorktreeCleaner
//

import SwiftUI

/// Sheet for editing the branches a worktree's branch must be merged into
/// (all of them) to be flagged "merged" and safe to remove.
///
/// A branch is verified against the repository when it's added, so a typo
/// or nonexistent name is rejected on the spot. A branch that was valid at
/// registration but no longer resolves (e.g. deleted upstream) is kept and
/// flagged with a "not found" tag instead, since it isn't necessarily wrong
/// to leave configured (it may come back after a fetch).
struct MergeTargetBranchesEditor: View {
    let repoPath: String
    let branches: [String]
    let onSave: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: [String]
    @State private var newBranch: String = ""
    @State private var notFoundBranches: Set<String> = []
    @State private var addErrorMessage: String?

    private let service = GitWorktreeService()

    init(repoPath: String, branches: [String], onSave: @escaping ([String]) -> Void) {
        self.repoPath = repoPath
        self.branches = branches
        self.onSave = onSave
        _draft = State(initialValue: branches)
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

            if let addErrorMessage {
                Text(addErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if draft.isEmpty {
                Text(Constant.MergeTargetEditor.emptyList)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                List {
                    ForEach(draft, id: \.self) { branch in
                        HStack(spacing: 8) {
                            Text(branch)
                                .font(.body.monospaced())
                            if notFoundBranches.contains(branch) {
                                StatusTag(text: Constant.Tag.notFound, color: .red)
                            }
                            Spacer()
                            Button {
                                draft.removeAll { $0 == branch }
                                notFoundBranches.remove(branch)
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
                    onSave(draft)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(minWidth: 380)
        .onAppear {
            notFoundBranches = Set(draft.filter { !service.branchExists($0, repoPath: repoPath) })
        }
    }

    private func addBranch() {
        let entries = BranchList.parse(newBranch)
        guard !entries.isEmpty else { return }

        var missing: [String] = []
        for entry in entries where !draft.contains(entry) {
            if service.branchExists(entry, repoPath: repoPath) {
                draft.append(entry)
            } else {
                missing.append(entry)
            }
        }

        if missing.isEmpty {
            addErrorMessage = nil
            newBranch = ""
        } else {
            addErrorMessage = String(localized: Constant.MergeTargetEditor.branchNotFound(branches: BranchList.format(missing)))
        }
    }
}
