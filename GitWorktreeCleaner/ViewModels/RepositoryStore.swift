//
//  RepositoryStore.swift
//  GitWorktreeCleaner
//

import AppKit
import Combine
import Foundation

/// Keeps the user's registered local repositories in UserDefaults so the
/// sidebar can list them across launches.
@MainActor
final class RepositoryStore: ObservableObject {
    @Published private(set) var repositories: [String] = []
    @Published var selectedRepository: String?

    static let repositoriesKey = "GitWorktreeCleaner.repositories"
    static let selectedRepositoryKey = "GitWorktreeCleaner.selectedRepository"

    init() {
        let saved = UserDefaults.standard.stringArray(forKey: Self.repositoriesKey) ?? []
        let existing = saved.filter { FileManager.default.fileExists(atPath: $0) }
        repositories = existing
        if existing.count != saved.count {
            UserDefaults.standard.set(existing, forKey: Self.repositoriesKey)
        }

        if let savedSelection = UserDefaults.standard.string(forKey: Self.selectedRepositoryKey),
           existing.contains(savedSelection) {
            selectedRepository = savedSelection
        } else {
            selectedRepository = existing.first
        }
    }

    func addRepository() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = String(localized: Constant.Panel.addRepositoryPrompt)
        panel.message = String(localized: Constant.Panel.addRepositoryMessage)

        guard panel.runModal() == .OK, let url = panel.url else { return }
        let path = url.path
        if !repositories.contains(path) {
            repositories.append(path)
            persistRepositories()
        }
        selectedRepository = path
    }

    func removeRepository(_ path: String) {
        repositories.removeAll { $0 == path }
        persistRepositories()
        if selectedRepository == path {
            selectedRepository = repositories.first
        }
    }

    /// Called by the view whenever `selectedRepository` changes, including
    /// changes made directly through a sidebar selection binding.
    func persistSelection() {
        UserDefaults.standard.set(selectedRepository, forKey: Self.selectedRepositoryKey)
    }

    private func persistRepositories() {
        UserDefaults.standard.set(repositories, forKey: Self.repositoriesKey)
    }
}
