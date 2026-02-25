//
//  LibraryDetailView.swift
//  ytdlp-gui
//
//  Single library item detail view
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct LibraryDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    let item: LibraryItem

    @State private var thumbnail: NSImage?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero section
                ZStack(alignment: .bottomLeading) {
                    if let thumb = thumbnail {
                        Image(nsImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 300)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [.clear, Color.black.opacity(0.8)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [ModernColors.gradientStart, ModernColors.gradientEnd]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 200)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.title)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        if let uploader = item.uploader {
                            Text(uploader)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(24)
                }
                .cornerRadius(12)

                // Info cards
                HStack(spacing: 16) {
                    InfoCard(title: "File Size", value: HistoryManager.formatFileSize(item.fileSize), icon: "doc", color: ModernColors.cyan)
                    InfoCard(title: "Format", value: (item.filePath as NSString).pathExtension.uppercased(), icon: "film", color: ModernColors.pink)
                    if let duration = item.duration {
                        InfoCard(title: "Duration", value: formatDuration(duration), icon: "clock", color: ModernColors.purple)
                    }
                    InfoCard(title: "Downloaded", value: formatDate(item.downloadedAt), icon: "calendar", color: ModernColors.accentGreen)
                }

                // Details
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(ModernColors.teal)
                        Text("Details")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)
                    }

                    DetailRow(label: "File Path", value: item.filePath)
                    DetailRow(label: "Original URL", value: item.originalURL)

                    if let resolution = item.resolution {
                        DetailRow(label: "Resolution", value: resolution)
                    }

                    if let vcodec = item.videoCodec {
                        DetailRow(label: "Video Codec", value: vcodec)
                    }

                    if let acodec = item.audioCodec {
                        DetailRow(label: "Audio Codec", value: acodec)
                    }
                }
                .glassCard()

                // Actions
                HStack(spacing: 12) {
                    Button("Open in Finder") {
                        NSWorkspace.shared.selectFile(item.filePath, inFileViewerRootedAtPath: "")
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.blue, style: .filled))

                    Button("Play") {
                        NSWorkspace.shared.open(URL(fileURLWithPath: item.filePath))
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.accentGreen, style: .filled))

                    Button("Copy URL") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(item.originalURL, forType: .string)
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.cyan, style: .outlined))

                    Button("Re-download") {
                        DownloadManager.shared.enqueue(url: item.originalURL)
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.orange, style: .outlined))

                    Spacer()

                    Button(item.isFavorite ? "Unfavorite" : "Favorite") {
                        dataStore.toggleFavorite(item.id)
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.yellow, style: item.isFavorite ? .filled : .outlined))
                }
                .glassCard()
            }
            .padding(32)
        }
        .task {
            if let thumbURL = item.thumbnailURL {
                thumbnail = await MetadataService.shared.loadThumbnail(url: thumbURL)
            }
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(ModernColors.textPrimary)
            Text(title)
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(ModernColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(ModernColors.textTertiary)
                .frame(width: 120, alignment: .trailing)
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(ModernColors.textSecondary)
                .textSelection(.enabled)
            Spacer()
        }
    }
}
