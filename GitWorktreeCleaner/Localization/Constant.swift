//
//  Constant.swift
//  GitWorktreeCleaner
//
//  Centralized access to the strings kept in Localizable.xcstrings.
//  Each entry uses a short, stable key so call sites don't depend on
//  the English wording. Values are `LocalizedStringResource` so SwiftUI
//  views (Text, Button, Label, .help, alert, confirmationDialog, ...) can
//  consume them directly without an intermediate String conversion; only
//  AppKit/model boundaries that require a plain String resolve one via
//  `String(localized:)`.
//

import Foundation

enum Constant {
    enum Sidebar {
        static var title: LocalizedStringResource {
            LocalizedStringResource("sidebar.title", defaultValue: "Repositories", comment: "Sidebar section header")
        }
        static var addRepositoryHelp: LocalizedStringResource {
            LocalizedStringResource("sidebar.addRepositoryHelp", defaultValue: "Add Repository", comment: "Tooltip for the add-repository toolbar button")
        }
        static var removeFromList: LocalizedStringResource {
            LocalizedStringResource("sidebar.removeFromList", defaultValue: "Remove from List", comment: "Context menu action removing a repository from the sidebar (does not touch disk)")
        }
    }

    enum Detail {
        static var repositoryLabel: LocalizedStringResource {
            LocalizedStringResource("detail.repositoryLabel", defaultValue: "Repository", comment: "Caption above the selected repository's path")
        }
        static var selectAll: LocalizedStringResource {
            LocalizedStringResource("detail.selectAll", defaultValue: "Select All", comment: "Button selecting every removable worktree")
        }
        static var clearSelection: LocalizedStringResource {
            LocalizedStringResource("detail.clearSelection", defaultValue: "Clear Selection", comment: "Button clearing the current worktree selection")
        }
        static var refresh: LocalizedStringResource {
            LocalizedStringResource("detail.refresh", defaultValue: "Refresh", comment: "Button reloading the worktree list")
        }
        static func removeSelected(count: Int) -> LocalizedStringResource {
            LocalizedStringResource("detail.removeSelected", defaultValue: "Remove Selected (\(count))", comment: "Destructive button removing the selected worktrees; shows the selection count")
        }
        static var loading: LocalizedStringResource {
            LocalizedStringResource("detail.loading", defaultValue: "Loading worktrees…", comment: "Progress label while listing worktrees")
        }
    }

    enum EmptyState {
        static var noRepositoriesTitle: LocalizedStringResource {
            LocalizedStringResource("empty.noRepositories.title", defaultValue: "No Repositories", comment: "Empty state title when no repository has been added yet")
        }
        static var noRepositoriesMessage: LocalizedStringResource {
            LocalizedStringResource("empty.noRepositories.message", defaultValue: "Add a git repository to see its worktrees.", comment: "Empty state message when no repository has been added yet")
        }
        static var addRepositoryButton: LocalizedStringResource {
            LocalizedStringResource("empty.addRepositoryButton", defaultValue: "Add Repository…", comment: "Button in the empty state that opens the add-repository panel")
        }
        static var selectRepositoryTitle: LocalizedStringResource {
            LocalizedStringResource("empty.selectRepository.title", defaultValue: "Select a Repository", comment: "Empty state title when repositories exist but none is selected")
        }
        static var selectRepositoryMessage: LocalizedStringResource {
            LocalizedStringResource("empty.selectRepository.message", defaultValue: "Choose a repository from the sidebar.", comment: "Empty state message when repositories exist but none is selected")
        }
        static var noWorktreesTitle: LocalizedStringResource {
            LocalizedStringResource("empty.noWorktrees.title", defaultValue: "No Worktrees Found", comment: "Empty state title when the selected repository has no linked worktrees")
        }
        static var noWorktreesMessage: LocalizedStringResource {
            LocalizedStringResource("empty.noWorktrees.message", defaultValue: "This repository doesn't have any linked worktrees.", comment: "Empty state message when the selected repository has no linked worktrees")
        }
    }

    enum ConfirmDelete {
        static func title(count: Int) -> LocalizedStringResource {
            LocalizedStringResource("confirmDelete.title", defaultValue: "Remove \(count) worktree\(count == 1 ? "" : "s")?", comment: "Confirmation dialog title before force-removing selected worktrees")
        }
        static var message: LocalizedStringResource {
            LocalizedStringResource("confirmDelete.message", defaultValue: "This permanently deletes the selected worktree folders and discards any uncommitted or untracked changes inside them. This cannot be undone.", comment: "Confirmation dialog body warning about force removal")
        }
        static var removeButton: LocalizedStringResource {
            LocalizedStringResource("confirmDelete.removeButton", defaultValue: "Remove Forcefully", comment: "Destructive confirm button for force-removing worktrees")
        }
        static var cancelButton: LocalizedStringResource {
            LocalizedStringResource("confirmDelete.cancelButton", defaultValue: "Cancel", comment: "Cancel button in the removal confirmation dialog")
        }
    }

    enum ErrorAlert {
        static var title: LocalizedStringResource {
            LocalizedStringResource("error.title", defaultValue: "Error", comment: "Generic error alert title")
        }
        static var okButton: LocalizedStringResource {
            LocalizedStringResource("error.okButton", defaultValue: "OK", comment: "Dismiss button on the error alert")
        }
        static var removalFailuresHeader: LocalizedStringResource {
            LocalizedStringResource("error.removalFailuresHeader", defaultValue: "Some worktrees could not be removed:", comment: "Header line above a list of per-worktree removal failures")
        }
        static var notAGitRepository: LocalizedStringResource {
            LocalizedStringResource("error.notAGitRepository", defaultValue: "The selected folder is not part of a git repository.", comment: "Error shown when the chosen folder has no git repository")
        }
        static var worktreeListFailed: LocalizedStringResource {
            LocalizedStringResource("error.worktreeListFailed", defaultValue: "git worktree list failed.", comment: "Fallback error when listing worktrees fails without a specific git message")
        }
        static func removeFailedFallback(path: String) -> LocalizedStringResource {
            LocalizedStringResource("error.removeFailedFallback", defaultValue: "Failed to remove \(path).", comment: "Fallback error when removing a worktree fails without a specific git message")
        }
        static func gitLaunchFailed(reason: String) -> LocalizedStringResource {
            LocalizedStringResource("error.gitLaunchFailed", defaultValue: "Could not launch git: \(reason)", comment: "Error shown when the git process itself fails to launch")
        }
    }

    enum Panel {
        static var addRepositoryPrompt: LocalizedStringResource {
            LocalizedStringResource("panel.addRepository.prompt", defaultValue: "Add", comment: "Confirm button label on the folder picker used to add a repository")
        }
        static var addRepositoryMessage: LocalizedStringResource {
            LocalizedStringResource("panel.addRepository.message", defaultValue: "Select a folder inside the git repository you want to manage.", comment: "Instructional message on the folder picker used to add a repository")
        }
    }

    enum Tag {
        static var main: LocalizedStringResource {
            LocalizedStringResource("tag.main", defaultValue: "main", comment: "Badge marking the repository's primary worktree")
        }
        static var bare: LocalizedStringResource {
            LocalizedStringResource("tag.bare", defaultValue: "bare", comment: "Badge marking a bare worktree")
        }
        static var locked: LocalizedStringResource {
            LocalizedStringResource("tag.locked", defaultValue: "locked", comment: "Badge marking a locked worktree")
        }
        static var prunable: LocalizedStringResource {
            LocalizedStringResource("tag.prunable", defaultValue: "prunable", comment: "Badge marking a prunable worktree")
        }
    }
}
