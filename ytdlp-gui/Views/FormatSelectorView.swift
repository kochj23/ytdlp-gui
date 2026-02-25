//
//  FormatSelectorView.swift
//  ytdlp-gui
//
//  Visual format picker with quality comparison
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct FormatSelectorView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var url: String = ""
    @State private var formats: [FormatInfo] = []
    @State private var selectedFormatID: String?
    @State private var isFetching = false
    @State private var errorMessage: String?
    @State private var filterVideo = true
    @State private var filterAudio = true

    var filteredFormats: [FormatInfo] {
        formats.filter { format in
            if filterVideo && filterAudio { return true }
            if filterVideo { return format.vcodec != nil && format.vcodec != "none" }
            if filterAudio { return format.acodec != nil && format.acodec != "none" }
            return true
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Format Selector")
                            .modernHeader(size: .large)
                        Text("Fetch available formats for a URL and pick the best one")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    Spacer()
                }

                // URL Input
                HStack(spacing: 12) {
                    TextField("Enter URL to fetch formats...", text: $url)
                        .formTextField()

                    Button("Fetch Formats") {
                        fetchFormats()
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.pink, style: .filled))
                    .disabled(url.isEmpty || isFetching)
                }
                .glassCard()

                if isFetching {
                    ProgressView("Fetching available formats...")
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

                if !formats.isEmpty {
                    // Filters
                    HStack(spacing: 16) {
                        Text("Filter:")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)

                        Toggle("Video", isOn: $filterVideo)
                            .toggleStyle(.switch)
                        Toggle("Audio", isOn: $filterAudio)
                            .toggleStyle(.switch)

                        Spacer()

                        Text("\(filteredFormats.count) formats")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(ModernColors.textTertiary)
                    }
                    .glassCard()

                    // Quick presets
                    HStack(spacing: 8) {
                        Text("Quick:")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)

                        FormatPresetButton(label: "Best", format: "bv*+ba/b", color: ModernColors.cyan)
                        FormatPresetButton(label: "1080p", format: "bv*[height<=1080]+ba/b[height<=1080]", color: ModernColors.accentGreen)
                        FormatPresetButton(label: "720p", format: "bv*[height<=720]+ba/b[height<=720]", color: ModernColors.blue)
                        FormatPresetButton(label: "Audio", format: "ba/b", color: ModernColors.purple)

                        Spacer()
                    }
                    .glassCard()

                    // Format table
                    VStack(spacing: 0) {
                        // Header
                        HStack(spacing: 0) {
                            Text("ID").frame(width: 60, alignment: .leading)
                            Text("Ext").frame(width: 50, alignment: .leading)
                            Text("Resolution").frame(width: 100, alignment: .leading)
                            Text("FPS").frame(width: 40, alignment: .trailing)
                            Text("Video").frame(width: 80, alignment: .leading)
                            Text("Audio").frame(width: 80, alignment: .leading)
                            Text("Size").frame(width: 80, alignment: .trailing)
                            Text("Note").frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(ModernColors.textTertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)

                        Divider().background(Color.white.opacity(0.1))

                        // Rows
                        ForEach(filteredFormats) { format in
                            FormatRow(format: format, isSelected: selectedFormatID == format.formatId)
                                .onTapGesture {
                                    selectedFormatID = format.formatId
                                }
                        }
                    }
                    .glassCard()
                }
            }
            .padding(32)
        }
    }

    private func fetchFormats() {
        isFetching = true
        errorMessage = nil
        formats = []

        Task {
            do {
                let fetched = try await MetadataService.shared.fetchFormats(url: url)
                formats = fetched.sorted { ($0.height ?? 0) > ($1.height ?? 0) }
            } catch {
                errorMessage = error.localizedDescription
            }
            isFetching = false
        }
    }
}

struct FormatRow: View {
    let format: FormatInfo
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 0) {
            Text(format.formatId).frame(width: 60, alignment: .leading)
            Text(format.ext).frame(width: 50, alignment: .leading)
            Text(format.resolution ?? "-").frame(width: 100, alignment: .leading)
            Text(format.fps.map { "\(Int($0))" } ?? "-").frame(width: 40, alignment: .trailing)
            Text(format.vcodec ?? "none").frame(width: 80, alignment: .leading)
            Text(format.acodec ?? "none").frame(width: 80, alignment: .leading)
            Text(format.displaySize).frame(width: 80, alignment: .trailing)
            Text(format.formatNote ?? "").frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(size: 11, design: .monospaced))
        .foregroundColor(isSelected ? ModernColors.cyan : ModernColors.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? ModernColors.cyan.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
    }
}

struct FormatPresetButton: View {
    let label: String
    let format: String
    let color: Color

    var body: some View {
        Button(label) {
            // Apply format to new download options
        }
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(6)
    }
}
