//
//  NewDownloadView.swift
//  ytdlp-gui
//
//  URL input, metadata preview, format selection, and download initiation
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct NewDownloadView: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var dataStore: DataStore

    @State private var urlText: String = ""
    @State private var metadata: MediaMetadata?
    @State private var formats: [FormatInfo] = []
    @State private var isFetchingMetadata = false
    @State private var errorMessage: String?
    @State private var selectedPreset: DownloadPreset?
    @State private var customOptions = YTDLPOptions()
    @State private var outputDirectory: String = ""
    @State private var isPlaylist = false
    @State private var playlistInfo: PlaylistInfo?

    private let metadataService = YTDLPService()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("New Download")
                            .modernHeader(size: .large)
                        Text("Paste a URL to get started")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    Spacer()
                }

                // URL Input
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(ModernColors.cyan)
                        Text("URL")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)
                    }

                    HStack(spacing: 12) {
                        TextField("https://youtube.com/watch?v=...", text: $urlText)
                            .formTextField()
                            .onSubmit {
                                fetchMetadata()
                            }

                        Button {
                            if let clipboard = NSPasteboard.general.string(forType: .string) {
                                urlText = clipboard
                                fetchMetadata()
                            }
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 16))
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.teal, style: .outlined))

                        Button {
                            fetchMetadata()
                        } label: {
                            HStack(spacing: 6) {
                                if isFetchingMetadata {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "magnifyingglass")
                                }
                                Text("Fetch")
                            }
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.cyan, style: .filled))
                        .disabled(urlText.isEmpty || isFetchingMetadata)
                    }
                }
                .glassCard()

                // Error
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(ModernColors.statusCritical)
                        Text(error)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(ModernColors.statusCritical)
                        Spacer()
                        Button("Dismiss") {
                            errorMessage = nil
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ModernColors.textSecondary)
                    }
                    .glassCard()
                }

                // Metadata Preview
                if let meta = metadata {
                    metadataCard(meta)
                }

                // Preset Selection
                presetSection

                // Output Directory
                outputDirectorySection

                // Download Button
                Button {
                    startDownload()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 18))
                        Text("Download")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(ModernButtonStyle(color: ModernColors.accentGreen, style: .filled))
                .disabled(urlText.isEmpty)
            }
            .padding(32)
        }
        .onAppear {
            outputDirectory = dataStore.settings.outputDirectory
        }
    }

    // MARK: - Metadata Card

    private func metadataCard(_ meta: MediaMetadata) -> some View {
        HStack(spacing: 20) {
            // Thumbnail placeholder
            if let thumbUrl = meta.thumbnailUrl, let url = URL(string: thumbUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(width: 200, height: 112)
                            .cornerRadius(12)
                    case .failure:
                        thumbnailPlaceholder
                    case .empty:
                        ProgressView()
                            .frame(width: 200, height: 112)
                    @unknown default:
                        thumbnailPlaceholder
                    }
                }
            } else {
                thumbnailPlaceholder
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(meta.title ?? "Unknown Title")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)
                    .lineLimit(2)

                if let uploader = meta.uploader ?? meta.channel {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 11))
                        Text(uploader)
                            .font(.system(size: 13, design: .rounded))
                    }
                    .foregroundColor(ModernColors.textSecondary)
                }

                HStack(spacing: 16) {
                    if let duration = meta.duration {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text(formatDuration(duration))
                                .font(.system(size: 12, design: .monospaced))
                        }
                        .foregroundColor(ModernColors.textTertiary)
                    }

                    if let views = meta.viewCount {
                        HStack(spacing: 4) {
                            Image(systemName: "eye")
                                .font(.system(size: 11))
                            Text(formatCount(views))
                                .font(.system(size: 12, design: .rounded))
                        }
                        .foregroundColor(ModernColors.textTertiary)
                    }

                    if !formats.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "film")
                                .font(.system(size: 11))
                            Text("\(formats.count) formats")
                                .font(.system(size: 12, design: .rounded))
                        }
                        .foregroundColor(ModernColors.textTertiary)
                    }
                }

                if isPlaylist, let count = meta.playlistCount {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 11))
                        Text("Playlist: \(count) videos")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(ModernColors.orange)
                }
            }

            Spacer()
        }
        .glassCard()
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.05))
            .frame(width: 200, height: 112)
            .overlay(
                Image(systemName: "film")
                    .font(.system(size: 30))
                    .foregroundColor(ModernColors.textTertiary)
            )
    }

    // MARK: - Preset Selection

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(ModernColors.orange)
                Text("Quick Presets")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                ForEach(dataStore.presets.filter { $0.isBuiltIn }) { preset in
                    presetButton(preset)
                }
            }
        }
        .glassCard()
    }

    private func presetButton(_ preset: DownloadPreset) -> some View {
        Button {
            selectedPreset = preset
            customOptions = preset.options
        } label: {
            VStack(spacing: 8) {
                Image(systemName: preset.icon)
                    .font(.system(size: 22))
                Text(preset.name)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selectedPreset?.id == preset.id ? Color.white.opacity(0.1) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedPreset?.id == preset.id ? ModernColors.cyan : Color.white.opacity(0.1), lineWidth: 1.5)
                    )
            )
            .foregroundColor(selectedPreset?.id == preset.id ? ModernColors.cyan : ModernColors.textSecondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Output Directory

    private var outputDirectorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(ModernColors.teal)
                Text("Output Directory")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)
            }

            HStack(spacing: 12) {
                TextField("~/Downloads", text: $outputDirectory)
                    .formTextField()

                Button("Browse") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        outputDirectory = url.path
                    }
                }
                .buttonStyle(ModernButtonStyle(color: ModernColors.teal, style: .outlined))
            }
        }
        .glassCard()
    }

    // MARK: - Actions

    private func fetchMetadata() {
        guard !urlText.isEmpty else { return }
        isFetchingMetadata = true
        errorMessage = nil
        metadata = nil
        formats = []
        isPlaylist = false

        Task {
            do {
                let cookieArgs = ["--cookies-from-browser", "chrome"]
                let meta = try await metadataService.fetchMetadata(url: urlText, cookieArgs: cookieArgs)
                await MainActor.run {
                    metadata = meta
                    formats = meta.formats ?? []
                    isPlaylist = meta.isPlaylist
                    isFetchingMetadata = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isFetchingMetadata = false
                }
            }
        }
    }

    private func startDownload() {
        let options = customOptions

        // Update settings with chosen output dir
        dataStore.settings.outputDirectory = outputDirectory
        dataStore.saveSettings()

        // Capture the ID returned by enqueue so we can patch the correct item
        // even if another download was added concurrently between the append
        // and the index lookup.
        let enqueuedID = downloadManager.enqueue(
            url: urlText,
            options: options,
            presetName: selectedPreset?.name
        )

        // Update the queued item with pre-fetched metadata
        if let metadata = metadata,
           let idx = downloadManager.queue.firstIndex(where: { $0.id == enqueuedID }) {
            downloadManager.queue[idx].title = metadata.title
            downloadManager.queue[idx].uploader = metadata.uploader ?? metadata.channel
            downloadManager.queue[idx].duration = metadata.duration
            downloadManager.queue[idx].thumbnailURL = metadata.thumbnailUrl
        }

        // Reset form
        urlText = ""
        metadata = nil
        formats = []
        selectedPreset = nil
        customOptions = YTDLPOptions()
    }

    // MARK: - Formatting

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}
