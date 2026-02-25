//
//  BinaryManagerView.swift
//  ytdlp-gui
//
//  yt-dlp and ffmpeg binary management
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct BinaryManagerView: View {
    @StateObject private var binaryManager = BinaryManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Text("Binary Management")
                        .modernHeader(size: .large)
                    Spacer()
                }

                HStack(spacing: 24) {
                    // yt-dlp
                    binaryCard(
                        name: "yt-dlp",
                        version: binaryManager.ytdlpVersion,
                        path: binaryManager.ytdlpPath,
                        available: binaryManager.isYTDLPAvailable,
                        icon: "arrow.down.circle",
                        color: ModernColors.cyan
                    ) {
                        Task {
                            try? await binaryManager.updateYTDLP()
                        }
                    }

                    // ffmpeg
                    binaryCard(
                        name: "ffmpeg",
                        version: binaryManager.ffmpegVersion,
                        path: binaryManager.ffmpegPath,
                        available: binaryManager.isFFmpegAvailable,
                        icon: "film",
                        color: ModernColors.purple
                    ) {
                        // ffmpeg update not yet implemented
                    }
                }

                // Status
                if binaryManager.isUpdating {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text(binaryManager.updateStatus)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    .glassCard()
                }
            }
            .padding(32)
        }
        .onAppear {
            Task {
                await binaryManager.detectVersions()
            }
        }
    }

    private func binaryCard(name: String, version: String, path: String, available: Bool, icon: String, color: Color, update: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(ModernColors.textPrimary)
                    Text(available ? "Available" : "Not Found")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(available ? ModernColors.accentGreen : ModernColors.statusCritical)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Version:")
                        .foregroundColor(ModernColors.textSecondary)
                    Text(version)
                        .foregroundColor(ModernColors.textPrimary)
                }
                .font(.system(size: 13, design: .monospaced))

                HStack {
                    Text("Path:")
                        .foregroundColor(ModernColors.textSecondary)
                    Text(path)
                        .foregroundColor(ModernColors.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(.system(size: 12, design: .monospaced))
            }

            Button("Check for Updates") {
                update()
            }
            .buttonStyle(ModernButtonStyle(color: color, style: .outlined))
            .disabled(binaryManager.isUpdating)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}
