//
//  MainViewModelTests.swift
//  GitWorktreeCleaner
//

import Dependencies
import Foundation
import Testing
@testable import WorktreeFeature

@MainActor
struct MainViewModelTests {
    @Test func initWithNoPersistedDataStartsEmpty() {
        let viewModel = withDependencies {
            $0.userDefaultsClient.string = { _ in nil }
            $0.userDefaultsClient.data = { _ in nil }
        } operation: {
            MainViewModel()
        }

        #expect(viewModel.selectedRepository == nil)
        #expect(viewModel.hasRepositories == false)
        #expect(viewModel.mergeTargetBranchList(for: "/repo") == [])
    }

    @Test func initRestoresPersistedSelectionAndMergeTargets() throws {
        let stored = ["/repo/a": ["main", "develop"]]
        let data = try JSONEncoder().encode(stored)

        let viewModel = withDependencies {
            $0.userDefaultsClient.string = { _ in "/repo/a" }
            $0.userDefaultsClient.data = { _ in data }
            // @Published's synthesized setter runs didSet even for this
            // init-time self-assignment, so setString gets called once here.
            $0.userDefaultsClient.setString = { _, _ in }
        } operation: {
            MainViewModel()
        }

        #expect(viewModel.selectedRepository == "/repo/a")
        #expect(viewModel.mergeTargetBranchList(for: "/repo/a") == ["main", "develop"])
    }

    @Test func settingSelectedRepositoryPersistsOnlyOnActualChange() {
        let persistedValues = Box<[String?]>([])
        let viewModel = withDependencies {
            $0.userDefaultsClient.string = { _ in nil }
            $0.userDefaultsClient.data = { _ in nil }
            $0.userDefaultsClient.setString = { _, value in persistedValues.value.append(value) }
        } operation: {
            MainViewModel()
        }

        viewModel.selectedRepository = "/repo/a"
        viewModel.selectedRepository = "/repo/a"
        viewModel.selectedRepository = "/repo/b"

        #expect(persistedValues.value == ["/repo/a", "/repo/b"])
    }

    @Test func repositoryListDidChangeSelectsFirstWhenCurrentSelectionRemoved() {
        let viewModel = withDependencies {
            $0.userDefaultsClient.string = { _ in "/repo/gone" }
            $0.userDefaultsClient.data = { _ in nil }
            $0.userDefaultsClient.setString = { _, _ in }
        } operation: {
            MainViewModel()
        }

        viewModel.repositoryListDidChange(["/repo/a", "/repo/b"])

        #expect(viewModel.hasRepositories == true)
        #expect(viewModel.selectedRepository == "/repo/a")
    }

    @Test func repositoryListDidChangeSelectsFirstWhenNoneSelectedYet() {
        let viewModel = withDependencies {
            $0.userDefaultsClient.string = { _ in nil }
            $0.userDefaultsClient.data = { _ in nil }
            $0.userDefaultsClient.setString = { _, _ in }
        } operation: {
            MainViewModel()
        }

        viewModel.repositoryListDidChange(["/repo/a"])

        #expect(viewModel.selectedRepository == "/repo/a")
    }

    @Test func repositoryListDidChangeWithNoneSetsHasRepositoriesFalseAndClearsSelection() {
        let viewModel = withDependencies {
            $0.userDefaultsClient.string = { _ in nil }
            $0.userDefaultsClient.data = { _ in nil }
        } operation: {
            MainViewModel()
        }

        viewModel.repositoryListDidChange([])

        #expect(viewModel.hasRepositories == false)
        #expect(viewModel.selectedRepository == nil)
    }

    @Test func repositoryListDidChangeKeepsValidSelectionAndPrunesStaleMergeTargets() throws {
        let stored = ["/repo/a": ["main"], "/repo/gone": ["develop"]]
        let data = try JSONEncoder().encode(stored)
        let persistedData = Box<Data?>(nil)

        let viewModel = withDependencies {
            $0.userDefaultsClient.string = { _ in "/repo/a" }
            $0.userDefaultsClient.data = { _ in data }
            $0.userDefaultsClient.setString = { _, _ in }
            $0.userDefaultsClient.setData = { _, value in persistedData.value = value }
        } operation: {
            MainViewModel()
        }

        viewModel.repositoryListDidChange(["/repo/a"])

        #expect(viewModel.selectedRepository == "/repo/a")
        #expect(viewModel.mergeTargetBranchList(for: "/repo/a") == ["main"])
        #expect(viewModel.mergeTargetBranchList(for: "/repo/gone") == [])
        #expect(persistedData.value != nil)
    }

    @Test func setMergeTargetBranchListStoresNonEmptyAndRemovesEmpty() {
        let persistedCalls = Box<Int>(0)
        let viewModel = withDependencies {
            $0.userDefaultsClient.string = { _ in nil }
            $0.userDefaultsClient.data = { _ in nil }
            $0.userDefaultsClient.setData = { _, _ in persistedCalls.value += 1 }
        } operation: {
            MainViewModel()
        }

        viewModel.setMergeTargetBranchList(["main"], for: "/repo/a")
        #expect(viewModel.mergeTargetBranchList(for: "/repo/a") == ["main"])

        viewModel.setMergeTargetBranchList([], for: "/repo/a")
        #expect(viewModel.mergeTargetBranchList(for: "/repo/a") == [])
        #expect(persistedCalls.value == 2)
    }
}
