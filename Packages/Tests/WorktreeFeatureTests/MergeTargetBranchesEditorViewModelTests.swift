//
//  MergeTargetBranchesEditorViewModelTests.swift
//  GitWorktreeCleaner
//

import Dependencies
import Testing
@testable import WorktreeFeature

@MainActor
struct MergeTargetBranchesEditorViewModelTests {
    @Test func checkNotFoundBranchesFlagsOnlyMissingOnes() {
        let viewModel = withDependencies {
            $0.gitWorktreeServiceClient.branchExists = { branch, _ in branch == "main" }
        } operation: {
            MergeTargetBranchesEditorViewModel(repoPath: "/repo", branchList: ["main", "gone"])
        }

        viewModel.checkNotFoundBranches()

        #expect(viewModel.notFoundBranchList == ["gone"])
    }

    @Test func addBranchAddsValidEntriesAndSkipsExistingDuplicates() {
        let viewModel = withDependencies {
            $0.gitWorktreeServiceClient.branchExists = { _, _ in true }
        } operation: {
            MergeTargetBranchesEditorViewModel(repoPath: "/repo", branchList: ["main"])
        }

        let succeeded = viewModel.addBranch("main, develop")

        #expect(succeeded == true)
        #expect(viewModel.draft == ["main", "develop"])
        #expect(viewModel.addErrorMessage == nil)
    }

    @Test func addBranchReportsMissingEntriesButKeepsValidOnes() {
        let viewModel = withDependencies {
            $0.gitWorktreeServiceClient.branchExists = { branch, _ in branch == "develop" }
        } operation: {
            MergeTargetBranchesEditorViewModel(repoPath: "/repo", branchList: [])
        }

        let succeeded = viewModel.addBranch("develop, ghost")

        #expect(succeeded == false)
        #expect(viewModel.draft == ["develop"])
        #expect(viewModel.addErrorMessage?.contains("ghost") == true)
    }

    @Test func addBranchWithOnlyBlankEntriesIsNoOp() {
        let viewModel = withDependencies {
            $0.gitWorktreeServiceClient.branchExists = { _, _ in true }
        } operation: {
            MergeTargetBranchesEditorViewModel(repoPath: "/repo", branchList: [])
        }

        #expect(viewModel.addBranch("   ,  ,") == false)
        #expect(viewModel.draft.isEmpty)
    }

    @Test func removeBranchRemovesFromDraftAndNotFoundBranchList() {
        let viewModel = withDependencies {
            $0.gitWorktreeServiceClient.branchExists = { _, _ in false }
        } operation: {
            MergeTargetBranchesEditorViewModel(repoPath: "/repo", branchList: ["main", "develop"])
        }
        viewModel.checkNotFoundBranches()
        #expect(viewModel.notFoundBranchList == ["main", "develop"])

        viewModel.removeBranch("main")

        #expect(viewModel.draft == ["develop"])
        #expect(viewModel.notFoundBranchList == ["develop"])
    }
}
