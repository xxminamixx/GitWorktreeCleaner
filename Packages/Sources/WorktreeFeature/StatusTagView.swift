//
//  StatusTagView.swift
//  GitWorktreeCleaner
//

import SwiftUI

/// Small pill-shaped badge used to mark worktree/branch status (main, locked,
/// merged, not found, ...) across list rows and the merge target editor.
struct StatusTagView: View {
    let text: LocalizedStringResource
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
