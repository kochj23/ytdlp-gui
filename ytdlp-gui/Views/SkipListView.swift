//
//  SkipListView.swift
//  ytdlp-gui
//
//  Manage the persistent skip list — URLs that will never be re-attempted.
//  Created by Jordan Koch on 2026-06-02.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct SkipListView: View {
    @ObservedObject var skipListManager = SkipListManager.shared
    @State private var searchText = ""
    @State private var filterReason: SkipReason?

    var filteredEntries: [SkipListEntry] {
        var entries = skipListManager.entries
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            entries = entries.filter {
                $0.url.lowercased().contains(query) ||
                $0.reason.rawValue.lowercased().contains(query) ||
                ($0.source?.lowercased().contains(query) ?? false)
            }
        }
        if let reason = filterReason {
            entries = entries.filter { $0.reason == reason }
        }
        return entries.sorted { $0.addedAt > $1.addedAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Skip List")
                    .font(.headline)
                Spacer()
                Text("\(skipListManager.count) URLs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            // Search & Filter
            HStack {
                TextField("Search URLs...", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                Picker("Filter", selection: $filterReason) {
                    Text("All").tag(SkipReason?.none)
                    ForEach(SkipReason.allCases) { reason in
                        Label(reason.rawValue, systemImage: reason.icon).tag(Optional(reason))
                    }
                }
                .frame(width: 160)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            // List
            if filteredEntries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(searchText.isEmpty ? "No skipped URLs" : "No matches")
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredEntries) { entry in
                        HStack {
                            Image(systemName: entry.reason.icon)
                                .foregroundStyle(.orange)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.url)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(1)
                                    .truncationMode(.middle)

                                HStack(spacing: 8) {
                                    Text(entry.reason.rawValue)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.orange.opacity(0.15))
                                        .clipShape(Capsule())

                                    if let source = entry.source {
                                        Text(source)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Text(entry.addedAt, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            Spacer()

                            Button(role: .destructive) {
                                skipListManager.removeFromSkipList(entry.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // Footer actions
            HStack {
                Button("Clear All", role: .destructive) {
                    skipListManager.clearAll()
                }
                .disabled(skipListManager.entries.isEmpty)

                Spacer()

                Button("Done") {
                    // Dismiss handled by parent
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}
