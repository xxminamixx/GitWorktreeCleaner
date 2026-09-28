//
//  WorktreeListView.swift
//  GitWorktreeCleaner
//

import Localization
import Models
import SwiftUI

/// Detail pane: worktrees for one repository. 1:1 with `WorktreeListViewModel`.
/// The caller gives it a fresh identity per `repoPath` (`.id(repoPath)`), so a
/// new `WorktreeListViewModel` is created whenever the selected repository changes.
struct WorktreeListView: View {
    let repoPath: String
    let onUpdateMergeTargetBranches: ([String]) -> Void

    @StateObject private var viewModel: WorktreeListViewModel
    @State private var isEditingMergeTargets = false

    init(repoPath: String, mergeTargetBranches: [String], onUpdateMergeTargetBranches: @escaping ([String]) -> Void) {
        self.repoPath = repoPath
        self.onUpdateMergeTargetBranches = onUpdateMergeTargetBranches
        _viewModel = StateObject(wrappedValue: WorktreeListViewModel(repoPath: repoPath, mergeTargetBranches: mergeTargetBranches))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            worktreeContent
        }
        .onAppear {
            viewModel.refresh()
        }
        .sheet(isPresented: $isEditingMergeTargets) {
            MergeTargetBranchesEditor(
                repoPath: repoPath,
                branchList: viewModel.mergeTargetBranches
            ) { branchList in
                viewModel.updateMergeTargetBranches(branchList)
                onUpdateMergeTargetBranches(branchList)
            }
        }
        .confirmationDialog(
            Constant.ConfirmDelete.title(count: viewModel.selection.count),
            isPresented: $viewModel.showRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button(Constant.ConfirmDelete.removeButton, role: .destructive) {
                viewModel.confirmRemoveSelected()
            }
            Button(Constant.ConfirmDelete.cancelButton, role: .cancel) {}
        } message: {
            Text(Constant.ConfirmDelete.message)
        }
        .alert(
            Constant.ErrorAlert.title,
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { isPresented in if !isPresented { viewModel.errorMessage = nil } }
            )
        ) {
            Button(Constant.ErrorAlert.okButton) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Constant.Detail.repositoryLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(repoPath)
                    .font(.body.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            HStack(spacing: 8) {
                Text(mergeTargetSummaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(Constant.Detail.mergeTargetEdit) { isEditingMergeTargets = true }
                    .buttonStyle(.automatic)
            }

            HStack {
                Button(Constant.Detail.selectAll) { viewModel.selectAll() }
                    .disabled(viewModel.selectableWorktrees.isEmpty)
                Button(Constant.Detail.clearSelection) { viewModel.clearSelection() }
                    .disabled(viewModel.selection.isEmpty)
                Spacer()
                Button {
                    viewModel.refresh()
                } label: {
                    Label(Constant.Detail.refresh, systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
                Button(role: .destructive) {
                    viewModel.requestRemoveSelected()
                } label: {
                    Label(Constant.Detail.removeSelected(count: viewModel.selection.count), systemImage: "trash")
                }
                .disabled(!viewModel.canRemoveSelection)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var worktreeContent: some View {
        if viewModel.isLoading && viewModel.worktrees.isEmpty {
            ProgressView(Constant.Detail.loading)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.worktrees.isEmpty {
            EmptyStateView(
                systemImage: "tray",
                title: Constant.EmptyState.noWorktreesTitle,
                message: Constant.EmptyState.noWorktreesMessage
            )
        } else {
            List(viewModel.worktrees) { worktree in
                WorktreeRow(
                    worktree: worktree,
                    isSelected: viewModel.selection.contains(worktree.path),
                    isMerged: viewModel.mergedPaths.contains(worktree.path)
                ) { isOn in
                    viewModel.toggleSelection(for: worktree, isSelected: isOn)
                }
            }
            .listStyle(.inset)
            .opacity(viewModel.isLoading ? 0.5 : 1.0)
            .disabled(viewModel.isLoading)
        }
    }

    private var mergeTargetSummaryText: LocalizedStringResource {
        let branches = viewModel.mergeTargetBranches
        guard !branches.isEmpty else { return Constant.Detail.mergeTargetSummaryEmpty }
        return Constant.Detail.mergeTargetSummary(branches: BranchList.format(branches))
    }
}
