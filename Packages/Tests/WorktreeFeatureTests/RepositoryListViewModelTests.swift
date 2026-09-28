//
//  RepositoryListViewModelTests.swift
//  GitWorktreeCleaner
//

import Dependencies
import Foundation
import Testing
@testable import WorktreeFeature

@MainActor
struct RepositoryListViewModelTests {
    @Test func initFiltersOutMissingDirectoriesAndPersistsFilteredList() throws {
        let existingDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: existingDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: existingDir) }

        let missingPath = "/nonexistent/\(UUID().uuidString)"
        let persisted = Box<[String]?>(nil)

        let viewModel = withDependencies {
            $0.userDefaultsClient.stringArray = { _ in [existingDir.path, missingPath] }
            $0.userDefaultsClient.setStringArray = { _, value in persisted.value = value }
        } operation: {
            RepositoryListViewModel()
        }

        #expect(viewModel.repositoryList == [existingDir.path])
        #expect(persisted.value == [existingDir.path])
    }

    @Test func initDoesNotPersistWhenAllSavedPathsStillExist() throws {
        let existingDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: existingDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: existingDir) }

        let persistCallCount = Box(0)

        let viewModel = withDependencies {
            $0.userDefaultsClient.stringArray = { _ in [existingDir.path] }
            $0.userDefaultsClient.setStringArray = { _, _ in persistCallCount.value += 1 }
        } operation: {
            RepositoryListViewModel()
        }

        #expect(viewModel.repositoryList == [existingDir.path])
        #expect(persistCallCount.value == 0)
    }

    @Test func removeRepositoryRemovesAndPersists() throws {
        let existingDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: existingDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: existingDir) }

        let persistedCalls = Box<[[String]]>([])
        let viewModel = withDependencies {
            $0.userDefaultsClient.stringArray = { _ in [existingDir.path] }
            $0.userDefaultsClient.setStringArray = { _, value in persistedCalls.value.append(value ?? []) }
        } operation: {
            RepositoryListViewModel()
        }

        viewModel.removeRepository(existingDir.path)

        #expect(viewModel.repositoryList.isEmpty)
        #expect(persistedCalls.value == [[]])
    }

    @Test func removeRepositoryIsNoOpForUnknownPath() throws {
        let existingDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: existingDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: existingDir) }

        let persistedCalls = Box<Int>(0)
        let viewModel = withDependencies {
            $0.userDefaultsClient.stringArray = { _ in [existingDir.path] }
            $0.userDefaultsClient.setStringArray = { _, _ in persistedCalls.value += 1 }
        } operation: {
            RepositoryListViewModel()
        }

        viewModel.removeRepository("/somewhere/else")

        #expect(viewModel.repositoryList == [existingDir.path])
        #expect(persistedCalls.value == 1)
    }
}
