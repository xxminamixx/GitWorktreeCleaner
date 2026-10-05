//
//  WorktreeItemView.swift
//  GitWorktreeCleaner
//

import Foundation
import Localization
import AppKit
import Models
import SwiftUI

struct WorktreeItemView: View {
    let worktree: Worktree
    let isSelected: Bool
    let isMerged: Bool
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
                            StatusTagView(text: Constant.Tag.main, color: .blue)
                        }
                        if worktree.isBare {
                            StatusTagView(text: Constant.Tag.bare, color: .gray)
                        }
                        if worktree.isLocked {
                            StatusTagView(text: Constant.Tag.locked, color: .orange)
                        }
                        if worktree.isPrunable {
                            StatusTagView(text: Constant.Tag.prunable, color: .red)
                        }
                        if isMerged {
                            StatusTagView(text: Constant.Tag.merged, color: .purple)
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
        .contextMenu {
            Button(Constant.WorktreeMenu.copyName) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(worktree.displayName, forType: .string)
            }
        }
    }
}
