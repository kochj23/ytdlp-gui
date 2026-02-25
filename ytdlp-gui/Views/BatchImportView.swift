//
//  BatchImportView.swift
//  ytdlp-gui
//
//  Import multiple URLs from text files, pasted text, or HTML
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct BatchImportView: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var dataStore: DataStore

    @State private var urlText: String = ""
    @State private var parsedURLs: [String] = []
    @State private var selectedURLs: Set<String> = []
    @State private var selectedPreset: DownloadPreset?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Batch Import")
                            .modernHeader(size: .large)
                        Text("Import multiple URLs at once")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    Spacer()
                }

                // Input area
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(ModernColors.yellow)
                        Text("Paste URLs")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)
                        Spacer()

                        Button("Import File") {
                            importFromFile()
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.teal, style: .outlined))

                        Button("Paste") {
                            if let content = NSPasteboard.general.string(forType: .string) {
                                urlText = content
                                parseURLs()
                            }
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.cyan, style: .outlined))
                    }

                    TextEditor(text: $urlText)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(height: 120)
                        .padding(8)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)

                    HStack {
                        Button("Parse URLs") {
                            parseURLs()
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.orange, style: .filled))

                        Button("Clear") {
                            urlText = ""
                            parsedURLs = []
                            selectedURLs = []
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.textSecondary, style: .outlined))

                        Spacer()

                        Text("Supports: plain text, one URL per line, HTML, JSON arrays")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                    }
                }
                .glassCard()

                // Parsed URLs
                if !parsedURLs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("\(parsedURLs.count) URLs found")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(ModernColors.textPrimary)

                            Spacer()

                            Button("Select All") {
                                selectedURLs = Set(parsedURLs)
                            }
                            .buttonStyle(ModernButtonStyle(color: ModernColors.cyan, style: .outlined))

                            Button("Deselect All") {
                                selectedURLs.removeAll()
                            }
                            .buttonStyle(ModernButtonStyle(color: ModernColors.textSecondary, style: .outlined))
                        }

                        // URL list with checkboxes
                        VStack(spacing: 0) {
                            ForEach(parsedURLs, id: \.self) { url in
                                HStack(spacing: 10) {
                                    Button {
                                        if selectedURLs.contains(url) {
                                            selectedURLs.remove(url)
                                        } else {
                                            selectedURLs.insert(url)
                                        }
                                    } label: {
                                        Image(systemName: selectedURLs.contains(url) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedURLs.contains(url) ? ModernColors.cyan : ModernColors.textTertiary)
                                    }
                                    .buttonStyle(.plain)

                                    Text(url)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(ModernColors.textSecondary)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if selectedURLs.contains(url) {
                                        selectedURLs.remove(url)
                                    } else {
                                        selectedURLs.insert(url)
                                    }
                                }

                                if url != parsedURLs.last {
                                    Divider().background(Color.white.opacity(0.05))
                                }
                            }
                        }
                    }
                    .glassCard()

                    // Download controls
                    HStack(spacing: 12) {
                        // Preset picker
                        HStack(spacing: 8) {
                            Text("Preset:")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(ModernColors.textTertiary)
                            ForEach(dataStore.presets.prefix(4)) { preset in
                                Button(preset.name) {
                                    selectedPreset = preset
                                }
                                .font(.system(size: 11, weight: selectedPreset?.id == preset.id ? .bold : .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(selectedPreset?.id == preset.id ? ModernColors.cyan.opacity(0.2) : Color.white.opacity(0.05))
                                .foregroundColor(selectedPreset?.id == preset.id ? ModernColors.cyan : ModernColors.textSecondary)
                                .cornerRadius(6)
                            }
                        }

                        Spacer()

                        Button("Download Selected (\(selectedURLs.count))") {
                            let options = selectedPreset?.options ?? YTDLPOptions()
                            downloadManager.enqueueMultiple(urls: Array(selectedURLs), options: options)
                            parsedURLs = []
                            selectedURLs = []
                            urlText = ""
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.accentGreen, style: .filled))
                        .disabled(selectedURLs.isEmpty)
                    }
                    .glassCard()
                }
            }
            .padding(32)
        }
    }

    // MARK: - URL Parsing

    private func parseURLs() {
        var urls: [String] = []

        // Split by newlines, commas, spaces
        let separators = CharacterSet.newlines.union(CharacterSet(charactersIn: ",; "))
        let parts = urlText.components(separatedBy: separators)

        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
                if !urls.contains(trimmed) {
                    urls.append(trimmed)
                }
            }
        }

        // Also try to extract URLs from HTML
        let hrefPattern = try? NSRegularExpression(pattern: "href=[\"']([^\"']+)[\"']", options: .caseInsensitive)
        if let matches = hrefPattern?.matches(in: urlText, range: NSRange(urlText.startIndex..., in: urlText)) {
            for match in matches {
                if let range = Range(match.range(at: 1), in: urlText) {
                    let href = String(urlText[range])
                    if (href.hasPrefix("http://") || href.hasPrefix("https://")) && !urls.contains(href) {
                        urls.append(href)
                    }
                }
            }
        }

        parsedURLs = urls
        selectedURLs = Set(urls)
    }

    private func importFromFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.text, .plainText, .html]

        if panel.runModal() == .OK, let url = panel.url {
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                urlText = content
                parseURLs()
            }
        }
    }
}
