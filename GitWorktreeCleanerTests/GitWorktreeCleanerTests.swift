//
//  GitWorktreeCleanerTests.swift
//  GitWorktreeCleanerTests
//
//  Created by minami kyohei on 2026/09/28.
//

import Testing
import WorktreeFeature

struct GitWorktreeCleanerTests {
    /// Confirms WorktreeFeature (and, transitively, Models/GitService/Localization)
    /// link correctly into the app target.
    @Test
    @MainActor
    func modulesAreLinked() {
        _ = MainScreen()
    }
}
