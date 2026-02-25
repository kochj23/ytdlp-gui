//
//  DashboardView.swift
//  ytdlp-gui
//
//  Dashboard with stats, active downloads, and quick actions
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard")
                            .modernHeader(size: .large)
                        Text("Monitor your downloads")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    Spacer()
                }

                // Stats Row
                HStack(spacing: 16) {
                    statCard(
                        title: "Active",
                        value: "\(downloadManager.activeCount)",
                        icon: "arrow.down.circle.fill",
                        color: ModernColors.cyan
                    )
                    statCard(
                        title: "Queued",
                        value: "\(downloadManager.queuedCount)",
                        icon: "clock.fill",
                        color: ModernColors.orange
                    )
                    statCard(
                        title: "Completed",
                        value: "\(downloadManager.totalCompleted)",
                        icon: "checkmark.circle.fill",
                        color: ModernColors.accentGreen
                    )
                    statCard(
                        title: "Library",
                        value: "\(dataStore.library.count)",
                        icon: "books.vertical.fill",
                        color: ModernColors.purple
                    )
                }

                // Two-column layout
                HStack(alignment: .top, spacing: 24) {
                    // Left: Active Downloads
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                                .foregroundColor(ModernColors.cyan)
                            Text("Active Downloads")
                                .modernHeader(size: .small)
                            Spacer()

                            if downloadManager.totalSpeed > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "speedometer")
                                        .font(.system(size: 12))
                                    Text(ByteCountFormatter.string(fromByteCount: Int64(downloadManager.totalSpeed), countStyle: .binary) + "/s")
                                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                }
                                .foregroundColor(ModernColors.cyan)
                            }
                        }

                        if downloadManager.queue.filter({ $0.status.isActive }).isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 40))
                                    .foregroundColor(ModernColors.textTertiary)
                                Text("No active downloads")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(ModernColors.textTertiary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                        } else {
                            ForEach(downloadManager.queue.filter { $0.status.isActive }) { item in
                                DownloadProgressCard(item: item)
                            }
                        }
                    }
                    .glassCard()
                    .frame(maxWidth: .infinity)

                    // Right: Recent Library + Speed Gauge
                    VStack(spacing: 24) {
                        // Speed Gauge
                        VStack(spacing: 12) {
                            CircularGauge(
                                value: min(downloadManager.totalSpeed / 1_048_576.0 * 10, 100), // Scale: 10MB/s = 100%
                                color: ModernColors.heatColor(percentage: min(downloadManager.totalSpeed / 1_048_576.0 * 10, 100)),
                                size: 120,
                                lineWidth: 12,
                                showValue: false,
                                label: nil
                            )

                            VStack(spacing: 2) {
                                Text(formatSpeed(downloadManager.totalSpeed))
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(ModernColors.textPrimary)
                                Text("Download Speed")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(ModernColors.textSecondary)
                            }
                        }
                        .glassCard()

                        // Recent downloads
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(ModernColors.purple)
                                Text("Recent")
                                    .modernHeader(size: .small)
                                Spacer()
                            }

                            if dataStore.library.isEmpty {
                                Text("No downloads yet")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(ModernColors.textTertiary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 20)
                            } else {
                                ForEach(dataStore.library.prefix(5)) { item in
                                    HStack(spacing: 12) {
                                        Image(systemName: item.format == "mp3" || item.format == "flac" ? "music.note" : "film")
                                            .foregroundColor(ModernColors.purple)
                                            .frame(width: 20)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.title)
                                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                                .foregroundColor(ModernColors.textPrimary)
                                                .lineLimit(1)
                                            Text(item.fileSizeFormatted)
                                                .font(.system(size: 11, design: .rounded))
                                                .foregroundColor(ModernColors.textTertiary)
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
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .glassCard()
                    }
                    .frame(maxWidth: 300)
                }
            }
            .padding(32)
        }
    }

    // MARK: - Components

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(ModernColors.textPrimary)

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(ModernColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond >= 1_073_741_824 {
            return String(format: "%.1f GB/s", bytesPerSecond / 1_073_741_824)
        } else if bytesPerSecond >= 1_048_576 {
            return String(format: "%.1f MB/s", bytesPerSecond / 1_048_576)
        } else if bytesPerSecond >= 1024 {
            return String(format: "%.0f KB/s", bytesPerSecond / 1024)
        } else if bytesPerSecond > 0 {
            return String(format: "%.0f B/s", bytesPerSecond)
        }
        return "0 B/s"
    }
}
