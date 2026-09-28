//
//  MainScreen.swift
//  GitWorktreeCleaner
//

import Foundation
import Localization
import SwiftUI

/// App entry point / coordinator. Owns `MainViewModel` and decides which
/// child view to show; `RepositoryListView` and `WorktreeListView` each own
/// their own ViewModel and are wired together only via bindings/closures.
public struct MainScreen: View {
    @StateObject private var mainViewModel = MainViewModel()

    public init() {}

    public var body: some View {
        NavigationSplitView {
            RepositoryListView(
                selectedRepository: $mainViewModel.selectedRepository,
                onRepositoriesChanged: { mainViewModel.repositoriesDidChange($0) }
            )
        } detail: {
            detail
        }
        .frame(minWidth: 820, minHeight: 460)
    }

    @ViewBuilder
    private var detail: some View {
        if !mainViewModel.hasRepositories {
            EmptyStateView(
                systemImage: "folder.badge.plus",
                title: Constant.EmptyState.noRepositoriesTitle,
                message: Constant.EmptyState.noRepositoriesMessage
            )
        } else if let repoPath = mainViewModel.selectedRepository {
            WorktreeListView(
                repoPath: repoPath,
                mergeTargetBranches: mainViewModel.mergeTargetBranches(for: repoPath)
            ) { branches in
                mainViewModel.setMergeTargetBranches(branches, for: repoPath)
            }
            .id(repoPath)
        } else {
            EmptyStateView(
                systemImage: "sidebar.left",
                title: Constant.EmptyState.selectRepositoryTitle,
                message: Constant.EmptyState.selectRepositoryMessage
            )
        }
    }
}

#Preview {
    MainScreen()
}
