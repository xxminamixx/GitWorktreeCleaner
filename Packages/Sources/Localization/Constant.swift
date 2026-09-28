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

public enum Constant {
    public enum Sidebar {
        public static var title: LocalizedStringResource {
            LocalizedStringResource("sidebar.title", defaultValue: "Repositories", comment: "Sidebar section header")
        }
        public static var addRepositoryHelp: LocalizedStringResource {
            LocalizedStringResource("sidebar.addRepositoryHelp", defaultValue: "Add Repository", comment: "Tooltip for the add-repository toolbar button")
        }
        public static var removeFromList: LocalizedStringResource {
            LocalizedStringResource("sidebar.removeFromList", defaultValue: "Remove from List", comment: "Context menu action removing a repository from the sidebar (does not touch disk)")
        }
    }

    public enum Detail {
        public static var repositoryLabel: LocalizedStringResource {
            LocalizedStringResource("detail.repositoryLabel", defaultValue: "Repository", comment: "Caption above the selected repository's path")
        }
        public static var selectAll: LocalizedStringResource {
            LocalizedStringResource("detail.selectAll", defaultValue: "Select All", comment: "Button selecting every removable worktree")
        }
        public static var clearSelection: LocalizedStringResource {
            LocalizedStringResource("detail.clearSelection", defaultValue: "Clear Selection", comment: "Button clearing the current worktree selection")
        }
        public static var refresh: LocalizedStringResource {
            LocalizedStringResource("detail.refresh", defaultValue: "Refresh", comment: "Button reloading the worktree list")
        }
        public static func removeSelected(count: Int) -> LocalizedStringResource {
            LocalizedStringResource("detail.removeSelected", defaultValue: "Remove Selected (\(count))", comment: "Destructive button removing the selected worktrees; shows the selection count")
        }
        public static var loading: LocalizedStringResource {
            LocalizedStringResource("detail.loading", defaultValue: "Loading worktrees…", comment: "Progress label while listing worktrees")
        }
        public static func mergeTargetSummary(branches: String) -> LocalizedStringResource {
            LocalizedStringResource("detail.mergeTargetSummary", defaultValue: "Checking merges into: \(branches)", comment: "Summary text showing which branches are configured for the merge-detection feature")
        }
        public static var mergeTargetSummaryEmpty: LocalizedStringResource {
            LocalizedStringResource("detail.mergeTargetSummaryEmpty", defaultValue: "Merge detection not configured", comment: "Summary text shown when no merge target branches are configured yet")
        }
        public static var mergeTargetEdit: LocalizedStringResource {
            LocalizedStringResource("detail.mergeTargetEdit", defaultValue: "Edit…", comment: "Button opening the merge target branches editor sheet")
        }
    }

    public enum MergeTargetEditor {
        public static var title: LocalizedStringResource {
            LocalizedStringResource("mergeTargetEditor.title", defaultValue: "Merge Target Branches", comment: "Title of the sheet for editing merge target branches")
        }
        public static var newBranchPlaceholder: LocalizedStringResource {
            LocalizedStringResource("mergeTargetEditor.newBranchPlaceholder", defaultValue: "Branch name", comment: "Placeholder in the text field for adding a new merge target branch")
        }
        public static var addButton: LocalizedStringResource {
            LocalizedStringResource("mergeTargetEditor.addButton", defaultValue: "Add", comment: "Button adding the entered branch name to the merge target list")
        }
        public static var emptyList: LocalizedStringResource {
            LocalizedStringResource("mergeTargetEditor.emptyList", defaultValue: "No branches added yet.", comment: "Message shown when the merge target branch list is empty")
        }
        public static var saveButton: LocalizedStringResource {
            LocalizedStringResource("mergeTargetEditor.saveButton", defaultValue: "Save", comment: "Button saving the edited merge target branches and closing the sheet")
        }
        public static func branchNotFound(branches: String) -> LocalizedStringResource {
            LocalizedStringResource("mergeTargetEditor.branchNotFound", defaultValue: "Branch not found, not added: \(branches)", comment: "Inline error shown when a newly entered branch name doesn't exist in the repository")
        }
    }

    public enum EmptyState {
        public static var noRepositoriesTitle: LocalizedStringResource {
            LocalizedStringResource("empty.noRepositories.title", defaultValue: "No Repositories", comment: "Empty state title when no repository has been added yet")
        }
        public static var noRepositoriesMessage: LocalizedStringResource {
            LocalizedStringResource("empty.noRepositories.message", defaultValue: "Add a git repository to see its worktrees.", comment: "Empty state message when no repository has been added yet")
        }
        public static var addRepositoryButton: LocalizedStringResource {
            LocalizedStringResource("empty.addRepositoryButton", defaultValue: "Add Repository…", comment: "Button in the empty state that opens the add-repository panel")
        }
        public static var selectRepositoryTitle: LocalizedStringResource {
            LocalizedStringResource("empty.selectRepository.title", defaultValue: "Select a Repository", comment: "Empty state title when repositories exist but none is selected")
        }
        public static var selectRepositoryMessage: LocalizedStringResource {
            LocalizedStringResource("empty.selectRepository.message", defaultValue: "Choose a repository from the sidebar.", comment: "Empty state message when repositories exist but none is selected")
        }
        public static var noWorktreesTitle: LocalizedStringResource {
            LocalizedStringResource("empty.noWorktrees.title", defaultValue: "No Worktrees Found", comment: "Empty state title when the selected repository has no linked worktrees")
        }
        public static var noWorktreesMessage: LocalizedStringResource {
            LocalizedStringResource("empty.noWorktrees.message", defaultValue: "This repository doesn't have any linked worktrees.", comment: "Empty state message when the selected repository has no linked worktrees")
        }
    }

    public enum ConfirmDelete {
        public static func title(count: Int) -> LocalizedStringResource {
            LocalizedStringResource("confirmDelete.title", defaultValue: "Remove \(count) worktree\(count == 1 ? "" : "s")?", comment: "Confirmation dialog title before force-removing selected worktrees")
        }
        public static var message: LocalizedStringResource {
            LocalizedStringResource("confirmDelete.message", defaultValue: "This permanently deletes the selected worktree folders and discards any uncommitted or untracked changes inside them. This cannot be undone.", comment: "Confirmation dialog body warning about force removal")
        }
        public static var removeButton: LocalizedStringResource {
            LocalizedStringResource("confirmDelete.removeButton", defaultValue: "Remove Forcefully", comment: "Destructive confirm button for force-removing worktrees")
        }
        public static var cancelButton: LocalizedStringResource {
            LocalizedStringResource("confirmDelete.cancelButton", defaultValue: "Cancel", comment: "Cancel button in the removal confirmation dialog")
        }
    }

    public enum ErrorAlert {
        public static var title: LocalizedStringResource {
            LocalizedStringResource("error.title", defaultValue: "Error", comment: "Generic error alert title")
        }
        public static var okButton: LocalizedStringResource {
            LocalizedStringResource("error.okButton", defaultValue: "OK", comment: "Dismiss button on the error alert")
        }
        public static var removalFailuresHeader: LocalizedStringResource {
            LocalizedStringResource("error.removalFailuresHeader", defaultValue: "Some worktrees could not be removed:", comment: "Header line above a list of per-worktree removal failures")
        }
        public static var notAGitRepository: LocalizedStringResource {
            LocalizedStringResource("error.notAGitRepository", defaultValue: "The selected folder is not part of a git repository.", comment: "Error shown when the chosen folder has no git repository")
        }
        public static var worktreeListFailed: LocalizedStringResource {
            LocalizedStringResource("error.worktreeListFailed", defaultValue: "git worktree list failed.", comment: "Fallback error when listing worktrees fails without a specific git message")
        }
        public static func removeFailedFallback(path: String) -> LocalizedStringResource {
            LocalizedStringResource("error.removeFailedFallback", defaultValue: "Failed to remove \(path).", comment: "Fallback error when removing a worktree fails without a specific git message")
        }
        public static func gitLaunchFailed(reason: String) -> LocalizedStringResource {
            LocalizedStringResource("error.gitLaunchFailed", defaultValue: "Could not launch git: \(reason)", comment: "Error shown when the git process itself fails to launch")
        }
    }

    public enum Panel {
        public static var addRepositoryPrompt: LocalizedStringResource {
            LocalizedStringResource("panel.addRepository.prompt", defaultValue: "Add", comment: "Confirm button label on the folder picker used to add a repository")
        }
        public static var addRepositoryMessage: LocalizedStringResource {
            LocalizedStringResource("panel.addRepository.message", defaultValue: "Select a folder inside the git repository you want to manage.", comment: "Instructional message on the folder picker used to add a repository")
        }
    }

    public enum Tag {
        public static var main: LocalizedStringResource {
            LocalizedStringResource("tag.main", defaultValue: "main", comment: "Badge marking the repository's primary worktree")
        }
        public static var bare: LocalizedStringResource {
            LocalizedStringResource("tag.bare", defaultValue: "bare", comment: "Badge marking a bare worktree")
        }
        public static var locked: LocalizedStringResource {
            LocalizedStringResource("tag.locked", defaultValue: "locked", comment: "Badge marking a locked worktree")
        }
        public static var prunable: LocalizedStringResource {
            LocalizedStringResource("tag.prunable", defaultValue: "prunable", comment: "Badge marking a prunable worktree")
        }
        public static var merged: LocalizedStringResource {
            LocalizedStringResource("tag.merged", defaultValue: "merged", comment: "Badge marking a worktree whose branch is merged into all configured target branches and is safe to remove")
        }
        public static var notFound: LocalizedStringResource {
            LocalizedStringResource("tag.notFound", defaultValue: "not found", comment: "Badge marking a registered merge target branch that no longer resolves in the repository")
        }
    }
}
