//
//  RepositoryItemView.swift
//  GitWorktreeCleaner
//

import SwiftUI

struct RepositoryItemView: View {
    let path: String

    private var displayName: String {
        URL(fileURLWithPath: path).lastPathComponent
    }

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .lineLimit(1)
                Text(path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        } icon: {
            Image(systemName: "folder")
        }
        .padding(.vertical, 2)
    }
}
