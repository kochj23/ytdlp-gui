//
//  LogView.swift
//  ytdlp-gui
//
//  Raw yt-dlp output log viewer
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct LogView: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @State private var selectedDownloadId: UUID?
    @State private var autoScroll = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Log Viewer")
                    .modernHeader(size: .medium)
                Spacer()
                Toggle("Auto-scroll", isOn: $autoScroll)
                    .toggleStyle(.switch)
            }
            .padding(20)

            // Log content
            if let id = selectedDownloadId, let service = downloadManager.service(for: id) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(Array(service.logOutput.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(logColor(for: line))
                                .textSelection(.enabled)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 2)
                        }
                    }
                }
                .background(Color.black.opacity(0.3))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "terminal")
                        .font(.system(size: 40))
                        .foregroundColor(ModernColors.textTertiary)
                    Text("Select an active download to view its log")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Download selector
            HStack {
                Text("Download:")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)

                Picker("", selection: $selectedDownloadId) {
                    Text("None").tag(nil as UUID?)
                    ForEach(downloadManager.queue.filter { $0.status.isActive }) { item in
                        Text(item.title ?? item.url).tag(item.id as UUID?)
                    }
                }
                .frame(maxWidth: 400)

                Spacer()
            }
            .padding(12)
            .background(Color.white.opacity(0.03))
        }
    }

    private func logColor(for line: String) -> Color {
        if line.contains("[error]") || line.contains("ERROR") { return ModernColors.statusCritical }
        if line.contains("[warning]") || line.contains("WARNING") { return ModernColors.yellow }
        if line.contains("[download]") { return ModernColors.cyan }
        if line.contains("[info]") { return ModernColors.accentGreen }
        if line.contains("[ExtractAudio]") || line.contains("[Merger]") { return ModernColors.purple }
        return ModernColors.textSecondary
    }
}
