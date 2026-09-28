//
//  WorktreeRow.swift
//  GitWorktreeCleaner
//

import Foundation
import SwiftUI

struct WorktreeRow: View {
    let worktree: Worktree
    let isSelected: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        Button {
            onToggle(!isSelected)
        } label: {
            HStack(spacing: 12) {
                Toggle("", isOn: .constant(isSelected))
                    .labelsHidden()
                    .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(worktree.displayName)
                            .font(.headline)
                        if worktree.isMain {
                            StatusTag(text: Constant.Tag.main, color: .blue)
                        }
                        if worktree.isBare {
                            StatusTag(text: Constant.Tag.bare, color: .gray)
                        }
                        if worktree.isLocked {
                            StatusTag(text: Constant.Tag.locked, color: .orange)
                        }
                        if worktree.isPrunable {
                            StatusTag(text: Constant.Tag.prunable, color: .red)
                        }
                    }
                    Text(worktree.path)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(worktree.branchDisplay)
                        .font(.subheadline.monospaced())
                    Text(worktree.shortSHA)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(worktree.isMain)
        .opacity(worktree.isMain ? 0.6 : 1.0)
    }
}

private struct StatusTag: View {
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
