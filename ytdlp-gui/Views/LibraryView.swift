//
//  LibraryView.swift
//  ytdlp-gui
//
//  Download history with search, filtering, and grid/list view
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var searchText: String = ""
    @State private var isGridView: Bool = true
    @State private var selectedItem: LibraryItem?

    private var filteredItems: [LibraryItem] {
        if searchText.isEmpty {
            return dataStore.library
        }
        return dataStore.searchLibrary(query: searchText)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Library")
                            .modernHeader(size: .large)
                        Text("\(dataStore.library.count) downloads")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }

                    Spacer()

                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(ModernColors.textTertiary)
                        TextField("Search...", text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundColor(ModernColors.textPrimary)
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                    .frame(maxWidth: 300)

                    // View toggle
                    Picker("", selection: $isGridView) {
                        Image(systemName: "square.grid.2x2").tag(true)
                        Image(systemName: "list.bullet").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 80)
                }

                // Content
                if filteredItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 50))
                            .foregroundColor(ModernColors.textTertiary)
                        Text(searchText.isEmpty ? "Library is empty" : "No results")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .glassCard()
                } else if isGridView {
                    gridView
                } else {
                    listView
                }
            }
            .padding(32)
        }
    }

    // MARK: - Grid View

    private var gridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
        ], spacing: 16) {
            ForEach(filteredItems) { item in
                libraryGridItem(item)
            }
        }
    }

    private func libraryGridItem(_ item: LibraryItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            if let thumbUrl = item.thumbnailURL, let url = URL(string: thumbUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(12)
                    default:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 120)
                            .overlay(
                                Image(systemName: "film")
                                    .font(.system(size: 24))
                                    .foregroundColor(ModernColors.textTertiary)
                            )
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: item.format == "mp3" || item.format == "flac" ? "music.note" : "film")
                            .font(.system(size: 24))
                            .foregroundColor(ModernColors.textTertiary)
                    )
            }

            Text(item.title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(ModernColors.textPrimary)
                .lineLimit(2)

            HStack {
                if let format = item.format {
                    Text(format.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(ModernColors.cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ModernColors.cyan.opacity(0.15))
                        .cornerRadius(4)
                }

                Text(item.fileSizeFormatted)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(ModernColors.textTertiary)

                Spacer()

                if item.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(ModernColors.yellow)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .contextMenu {
            Button("Open in Finder") {
                if item.fileExists {
                    NSWorkspace.shared.selectFile(item.filePath, inFileViewerRootedAtPath: "")
                }
            }
            Button("Copy URL") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.url, forType: .string)
            }
            Divider()
            Button(item.isFavorite ? "Unfavorite" : "Favorite") {
                dataStore.toggleFavorite(item.id)
            }
            Divider()
            Button("Remove from Library", role: .destructive) {
                dataStore.removeFromLibrary(item.id)
            }
        }
    }

    // MARK: - List View

    private var listView: some View {
        VStack(spacing: 0) {
            ForEach(filteredItems) { item in
                HStack(spacing: 16) {
                    Image(systemName: item.format == "mp3" || item.format == "flac" ? "music.note" : "film")
                        .font(.system(size: 16))
                        .foregroundColor(ModernColors.purple)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)
                            .lineLimit(1)
                        if let uploader = item.uploader {
                            Text(uploader)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(ModernColors.textTertiary)
                        }
                    }

                    Spacer()

                    if let format = item.format {
                        Text(format.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(ModernColors.cyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ModernColors.cyan.opacity(0.15))
                            .cornerRadius(4)
                    }

                    Text(item.fileSizeFormatted)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(ModernColors.textTertiary)
                        .frame(width: 70, alignment: .trailing)

                    if let dur = item.durationFormatted {
                        Text(dur)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(ModernColors.textTertiary)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)

                if item.id != filteredItems.last?.id {
                    Divider()
                        .background(Color.white.opacity(0.05))
                }
            }
        }
        .glassCard()
    }
}
