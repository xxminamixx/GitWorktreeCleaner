//
//  RepositoryListViewModel.swift
//  GitWorktreeCleaner
//

import AppKit
import Combine
import Dependencies
import Foundation
import Localization
import UserDefaultsClient

/// Backs `RepositoryListView`. Owns only the registered-repository list
/// (add/remove/persist); selection and per-repo merge-target branches live
/// in `MainViewModel` instead, since those are shared with `MainScreen`.
@MainActor
final class RepositoryListViewModel: ObservableObject {
    @Published private(set) var repositories: [String] = []

    @Dependency(\.userDefaultsClient) private var userDefaults

    private static let repositoriesKey = "GitWorktreeCleaner.repositories"

    init() {
        let saved = userDefaults.stringArray(Self.repositoriesKey) ?? []
        let existing = saved.filter { FileManager.default.fileExists(atPath: $0) }
        repositories = existing
        if existing.count != saved.count {
            userDefaults.setStringArray(Self.repositoriesKey, existing)
        }
    }

    /// Returns the newly added (or already-registered) path, or `nil` if the
    /// panel was cancelled.
    @discardableResult
    func addRepository() -> String? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = String(localized: Constant.Panel.addRepositoryPrompt)
        panel.message = String(localized: Constant.Panel.addRepositoryMessage)

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        let path = url.path
        if !repositories.contains(path) {
            repositories.append(path)
            persistRepositories()
        }
        return path
    }

    func removeRepository(_ path: String) {
        repositories.removeAll { $0 == path }
        persistRepositories()
    }

    private func persistRepositories() {
        userDefaults.setStringArray(Self.repositoriesKey, repositories)
    }
}
