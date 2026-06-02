//
//  DownloadProgressCard.swift
//  ytdlp-gui
//
//  Individual download progress card with controls
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct DownloadProgressCard: View {
    let item: DownloadItem
    @EnvironmentObject var downloadManager: DownloadManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title ?? item.url)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(ModernColors.textPrimary)
                        .lineLimit(1)

                    if let uploader = item.uploader {
                        Text(uploader)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Status badge
                statusBadge
            }

            // Progress bar
            if item.status == .downloading || item.status == .retrying {
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(progressColor)
                                .frame(width: geo.size.width * CGFloat(item.progress.percentage / 100.0), height: 6)
                                .shadow(color: progressColor.opacity(0.5), radius: 4)
                        }
                    }
                    .frame(height: 6)

                    // Stats row
                    HStack {
                        Text(String(format: "%.1f%%", item.progress.percentage))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(progressColor)

                        Spacer()

                        if item.progress.speed > 0 {
                            Text(item.progress.speedFormatted)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(ModernColors.textSecondary)
                        }

                        if let eta = item.progress.etaFormatted {
                            Text("ETA \(eta)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(ModernColors.textTertiary)
                        }

                        if let total = item.progress.totalFormatted {
                            Text("\(item.progress.downloadedFormatted) / \(total)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(ModernColors.textTertiary)
                        }
                    }
                }
            }

            // Error message
            if let error = item.errorMessage {
                Text(error)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(ModernColors.statusCritical)
                    .lineLimit(5)
                    .textSelection(.enabled)
                    .help(error)
            }

            // Controls
            if !item.status.isTerminal {
                HStack(spacing: 8) {
                    Spacer()

                    if item.status == .downloading {
                        Button {
                            downloadManager.pause(item.id)
                        } label: {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.orange, style: .outlined))
                    }

                    if item.status == .paused {
                        Button {
                            downloadManager.resume(item.id)
                        } label: {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.accentGreen, style: .outlined))
                    }

                    if item.status == .failed {
                        Button {
                            downloadManager.retryFailed(item.id)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12))
                                Text("Retry")
                            }
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.orange, style: .outlined))
                    }

                    Button {
                        downloadManager.cancelDownload(item.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.red, style: .outlined))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var statusBadge: some View {
        Text(item.status.rawValue)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.15))
            .cornerRadius(8)
    }

    private var statusColor: Color {
        switch item.status {
        case .queued: return ModernColors.textSecondary
        case .fetchingMetadata: return ModernColors.teal
        case .downloading: return ModernColors.cyan
        case .postProcessing: return ModernColors.purple
        case .completed: return ModernColors.accentGreen
        case .failed: return ModernColors.statusCritical
        case .cancelled: return ModernColors.textTertiary
        case .paused: return ModernColors.orange
        case .retrying: return ModernColors.yellow
        case .skipped: return ModernColors.textTertiary
        }
    }

    private var progressColor: Color {
        ModernColors.heatColor(percentage: 100 - item.progress.percentage) // Inverts: green at 100%
    }
}
