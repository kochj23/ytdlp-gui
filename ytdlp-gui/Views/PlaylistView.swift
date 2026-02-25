//
//  PlaylistView.swift
//  ytdlp-gui
//
//  Playlist browser with selective download
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct PlaylistView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var downloadManager: DownloadManager
    @StateObject private var playlistService = PlaylistService.shared
    @State private var url: String = ""
    @State private var selectedIndices: Set<Int> = []
    @State private var errorMessage: String?
    @State private var customOptions = YTDLPOptions()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Playlist Browser")
                            .modernHeader(size: .large)
                        Text("Fetch playlist entries and download selectively")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    Spacer()
                }

                // URL input
                HStack(spacing: 12) {
                    TextField("Paste playlist URL...", text: $url)
                        .formTextField()

                    Button("Fetch Playlist") {
                        fetchPlaylist()
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.blue, style: .filled))
                    .disabled(url.isEmpty || playlistService.isFetching)
                }
                .glassCard()

                if playlistService.isFetching {
                    ProgressView("Fetching playlist entries...")
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .glassCard()
                }

                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(ModernColors.orange)
                        Text(error)
                            .foregroundColor(ModernColors.orange)
                    }
                    .glassCard()
                }

                if let playlist = playlistService.currentPlaylist {
                    // Playlist header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(playlist.title ?? "Untitled Playlist")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)

                        HStack(spacing: 16) {
                            if let uploader = playlist.uploader {
                                Label(uploader, systemImage: "person")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(ModernColors.textSecondary)
                            }
                            Label("\((playlist.entries ?? []).count) entries", systemImage: "list.number")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(ModernColors.textSecondary)
                            Label("\(selectedIndices.count) selected", systemImage: "checkmark.circle")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(ModernColors.cyan)
                        }
                    }
                    .glassCard()

                    // Selection controls
                    HStack(spacing: 8) {
                        Button("Select All") {
                            selectedIndices = Set(0..<(playlist.entries ?? []).count)
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.cyan, style: .outlined))

                        Button("Deselect All") {
                            selectedIndices.removeAll()
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.textSecondary, style: .outlined))

                        Spacer()

                        Button("Download Selected (\(selectedIndices.count))") {
                            playlistService.downloadSelected(from: playlist, selectedIndices: selectedIndices, options: customOptions)
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.accentGreen, style: .filled))
                        .disabled(selectedIndices.isEmpty)
                    }
                    .glassCard()

                    // Entries list
                    VStack(spacing: 0) {
                        ForEach(Array((playlist.entries ?? []).enumerated()), id: \.offset) { index, entry in
                            PlaylistEntryRow(
                                entry: entry,
                                index: index,
                                isSelected: selectedIndices.contains(index),
                                onToggle: {
                                    if selectedIndices.contains(index) {
                                        selectedIndices.remove(index)
                                    } else {
                                        selectedIndices.insert(index)
                                    }
                                }
                            )

                            if index < (playlist.entries ?? []).count - 1 {
                                Divider().background(Color.white.opacity(0.05))
                            }
                        }
                    }
                    .glassCard()
                }
            }
            .padding(32)
        }
    }

    private func fetchPlaylist() {
        errorMessage = nil
        Task {
            do {
                let playlist = try await playlistService.fetchPlaylist(url: url)
                selectedIndices = Set(0..<(playlist.entries ?? []).count)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct PlaylistEntryRow: View {
    let entry: PlaylistEntry
    let index: Int
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? ModernColors.cyan : ModernColors.textTertiary)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)

            Text("\(index + 1)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(ModernColors.textTertiary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title ?? "Entry \(index + 1)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? ModernColors.textPrimary : ModernColors.textSecondary)
                    .lineLimit(1)

                if let duration = entry.duration {
                    Text(formatDuration(duration))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(ModernColors.textTertiary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? ModernColors.cyan.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
