//
//  QueueView.swift
//  ytdlp-gui
//
//  Download queue management with per-item controls
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct QueueView: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Download Queue")
                            .modernHeader(size: .large)
                        Text("\(downloadManager.queue.count) items")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }

                    Spacer()

                    // Concurrency control
                    HStack(spacing: 8) {
                        Text("Max concurrent:")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)

                        Picker("", selection: $dataStore.settings.maxConcurrentDownloads) {
                            ForEach(1...10, id: \.self) { n in
                                Text("\(n)").tag(n)
                            }
                        }
                        .frame(width: 60)
                        .onChange(of: dataStore.settings.maxConcurrentDownloads) { _ in
                            dataStore.saveSettings()
                            downloadManager.processQueue()
                        }
                    }

                    HStack(spacing: 8) {
                        Button("Pause All") {
                            downloadManager.pauseAll()
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.orange, style: .outlined))

                        Button("Resume All") {
                            downloadManager.resumeAll()
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.accentGreen, style: .outlined))

                        Button("Clear Done") {
                            downloadManager.clearCompleted()
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.textSecondary, style: .outlined))
                    }
                }

                // Queue items
                if downloadManager.queue.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 50))
                            .foregroundColor(ModernColors.textTertiary)
                        Text("Queue is empty")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                        Text("Add URLs from the New Download page")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .glassCard()
                } else {
                    VStack(spacing: 12) {
                        ForEach(downloadManager.queue) { item in
                            DownloadProgressCard(item: item)
                        }
                    }
                    .glassCard()
                }
            }
            .padding(32)
        }
    }
}
