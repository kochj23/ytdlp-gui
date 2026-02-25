//
//  ClipboardMonitorView.swift
//  ytdlp-gui
//
//  Clipboard monitoring settings and quick download popup
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct ClipboardMonitorView: View {
    @StateObject private var monitor = ClipboardMonitor.shared
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clipboard Monitor")
                            .modernHeader(size: .large)
                        Text("Automatically detect video URLs when copied")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    Spacer()

                    Toggle("Active", isOn: Binding(
                        get: { monitor.isMonitoring },
                        set: { $0 ? monitor.startMonitoring() : monitor.stopMonitoring() }
                    ))
                    .toggleStyle(.switch)
                }

                // Status card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Circle()
                            .fill(monitor.isMonitoring ? ModernColors.accentGreen : ModernColors.textTertiary)
                            .frame(width: 10, height: 10)
                        Text(monitor.isMonitoring ? "Monitoring clipboard for video URLs" : "Monitoring paused")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)
                    }

                    Text("Supported: YouTube, Vimeo, TikTok, Instagram, Twitter/X, SoundCloud, Twitch, and more")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)
                }
                .glassCard()

                // Quick download popup (shown when URL detected)
                if monitor.showQuickDownload, let url = monitor.lastDetectedURL {
                    quickDownloadCard(url: url)
                }

                // Settings
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(ModernColors.teal)
                        Text("Settings")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)
                    }

                    Toggle("Auto-fetch metadata on detection", isOn: $dataStore.settings.autoFetchMetadata)
                        .onChange(of: dataStore.settings.autoFetchMetadata) { _ in
                            dataStore.saveSettings()
                        }

                    HStack {
                        Button("Clear Ignored URLs") {
                            monitor.clearIgnored()
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.textSecondary, style: .outlined))
                    }
                }
                .glassCard()
            }
            .padding(32)
        }
    }

    private func quickDownloadCard(url: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "link.badge.plus")
                    .foregroundColor(ModernColors.accentGreen)
                    .font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Video URL Detected!")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(ModernColors.accentGreen)
                    Text(url)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(ModernColors.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
            }

            // Metadata preview if available
            if let meta = monitor.detectedMetadata {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meta.title ?? "Unknown Title")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)
                        if let uploader = meta.uploader {
                            Text(uploader)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(ModernColors.textSecondary)
                        }
                    }
                }
            }

            // Quick preset buttons
            HStack(spacing: 8) {
                ForEach(dataStore.presets.prefix(4)) { preset in
                    Button(preset.name) {
                        monitor.downloadDetected(preset: preset)
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.cyan, style: .outlined))
                }

                Spacer()

                Button("Download") {
                    monitor.downloadDetected()
                }
                .buttonStyle(ModernButtonStyle(color: ModernColors.accentGreen, style: .filled))

                Button("Dismiss") {
                    monitor.dismissQuickDownload()
                }
                .buttonStyle(ModernButtonStyle(color: ModernColors.textSecondary, style: .outlined))
            }
        }
        .glassCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ModernColors.accentGreen.opacity(0.3), lineWidth: 1)
        )
    }
}
