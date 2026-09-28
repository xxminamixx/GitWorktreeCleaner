//
//  EmptyStateView.swift
//  GitWorktreeCleaner
//

import Foundation
import SwiftUI

/// Generic empty-state placeholder (icon + title + message) shared by the
/// repository detail pane and the worktree list.
struct EmptyStateView: View {
    let systemImage: String
    let title: LocalizedStringResource
    let message: LocalizedStringResource

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
