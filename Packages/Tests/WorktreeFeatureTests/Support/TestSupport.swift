//
//  TestSupport.swift
//  GitWorktreeCleaner
//

import Foundation
import Models

/// Records values written by mocked `@Sendable` dependency closures. The
/// tests never write concurrently (each call happens synchronously on
/// `MainActor` from the test's own call stack), so a lock isn't needed.
final class Box<Value>: @unchecked Sendable {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }
}

func makeWorktree(path: String, branch: String? = nil, isMain: Bool = false) -> Worktree {
    Worktree(
        path: path,
        headSHA: "abc123",
        branch: branch,
        isBare: false,
        isDetached: false,
        isLocked: false,
        lockReason: nil,
        isPrunable: false,
        prunableReason: nil,
        isMain: isMain
    )
}

/// Polls `condition` until it's true or `timeout` elapses, for observing the
/// end state of a ViewModel's fire-and-forget `Task { ... }` work.
@MainActor
func waitUntil(
    timeout: Duration = .seconds(2),
    _ condition: @MainActor () -> Bool
) async {
    let deadline = ContinuousClock.now + timeout
    while !condition(), ContinuousClock.now < deadline {
        try? await Task.sleep(for: .milliseconds(5))
    }
}
