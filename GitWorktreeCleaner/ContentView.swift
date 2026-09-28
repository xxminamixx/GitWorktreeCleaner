//
//  ContentView.swift
//  GitWorktreeCleaner
//

import Foundation
import SwiftUI

struct ContentView: View {
    @StateObject private var repositoryStore = RepositoryStore()
    @StateObject private var viewModel = WorktreeListViewModel()

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .frame(minWidth: 820, minHeight: 460)
        .onAppear {
            viewModel.setRepository(repositoryStore.selectedRepository)
        }
        .onChange(of: repositoryStore.selectedRepository) { _, newValue in
            repositoryStore.persistSelection()
            viewModel.setRepository(newValue)
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

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack {
                Text(Constant.Sidebar.title)
                    .font(.headline)
                Spacer()
                Button {
                    repositoryStore.addRepository()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help(Constant.Sidebar.addRepositoryHelp)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            List(selection: $repositoryStore.selectedRepository) {
                ForEach(repositoryStore.repositories, id: \.self) { path in
                    RepositoryRow(path: path)
                        .tag(path)
                        .contextMenu {
                            Button(Constant.Sidebar.removeFromList, role: .destructive) {
                                repositoryStore.removeRepository(path)
                            }
                        }
                }
            }
            .listStyle(.sidebar)
        }
    }

    @ViewBuilder
    private var detail: some View {
        if repositoryStore.repositories.isEmpty {
            emptyState(
                systemImage: "folder.badge.plus",
                title: Constant.EmptyState.noRepositoriesTitle,
                message: Constant.EmptyState.noRepositoriesMessage,
                showAddButton: true
            )
        } else if repositoryStore.selectedRepository == nil {
            emptyState(
                systemImage: "sidebar.left",
                title: Constant.EmptyState.selectRepositoryTitle,
                message: Constant.EmptyState.selectRepositoryMessage,
                showAddButton: false
            )
        } else {
            VStack(spacing: 0) {
                header
                Divider()
                worktreeContent
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Constant.Detail.repositoryLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.repoPath ?? "")
                    .font(.body.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
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
            emptyState(
                systemImage: "tray",
                title: Constant.EmptyState.noWorktreesTitle,
                message: Constant.EmptyState.noWorktreesMessage,
                showAddButton: false
            )
        } else {
            List(viewModel.worktrees) { worktree in
                WorktreeRow(
                    worktree: worktree,
                    isSelected: viewModel.selection.contains(worktree.path)
                ) { isOn in
                    viewModel.toggleSelection(for: worktree, isSelected: isOn)
                }
            }
            .listStyle(.inset)
            .opacity(viewModel.isLoading ? 0.5 : 1.0)
            .disabled(viewModel.isLoading)
        }
    }

    private func emptyState(systemImage: String, title: LocalizedStringResource, message: LocalizedStringResource, showAddButton: Bool) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if showAddButton {
                Button(Constant.EmptyState.addRepositoryButton) { repositoryStore.addRepository() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    ContentView()
}
