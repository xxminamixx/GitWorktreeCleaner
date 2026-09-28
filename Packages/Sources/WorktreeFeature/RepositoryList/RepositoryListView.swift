//
//  RepositoryListView.swift
//  GitWorktreeCleaner
//

import Localization
import SwiftUI

/// Sidebar: the list of registered repositories. 1:1 with `RepositoryListViewModel`.
/// Selection is owned by the parent (`MainViewModel`) and passed in as a binding;
/// list changes are reported upward via `onRepositoriesChanged` so the parent can
/// keep selection and per-repo merge-target branches consistent with it.
struct RepositoryListView: View {
    @Binding var selectedRepository: String?
    let onRepositoriesChanged: ([String]) -> Void

    @StateObject private var viewModel = RepositoryListViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(Constant.Sidebar.title)
                    .font(.headline)
                Spacer()
                Button {
                    if let newPath = viewModel.addRepository() {
                        selectedRepository = newPath
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help(Constant.Sidebar.addRepositoryHelp)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            List(selection: $selectedRepository) {
                ForEach(viewModel.repositories, id: \.self) { path in
                    RepositoryRow(path: path)
                        .tag(path)
                        .contextMenu {
                            Button(Constant.Sidebar.removeFromList, role: .destructive) {
                                viewModel.removeRepository(path)
                            }
                        }
                }
            }
            .listStyle(.sidebar)
        }
        .onAppear {
            onRepositoriesChanged(viewModel.repositories)
        }
        .onChange(of: viewModel.repositories) { _, newValue in
            onRepositoriesChanged(newValue)
        }
    }
}
