//
//  SettingsView.swift
//  ytdlp-gui
//
//  Application settings
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Text("Settings")
                        .modernHeader(size: .large)
                    Spacer()
                }

                // General
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "gearshape")
                            .foregroundColor(ModernColors.cyan)
                        Text("General")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)
                    }

                    HStack {
                        Text("Default Output Directory")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                        Spacer()

                        TextField("~/Downloads", text: $dataStore.settings.outputDirectory)
                            .formTextField()
                            .frame(maxWidth: 400)

                        Button("Browse") {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            if panel.runModal() == .OK, let url = panel.url {
                                dataStore.settings.outputDirectory = url.path
                                dataStore.saveSettings()
                            }
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.teal, style: .outlined))
                    }

                    HStack {
                        Text("Max Concurrent Downloads")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                        Spacer()
                        Picker("", selection: $dataStore.settings.maxConcurrentDownloads) {
                            ForEach(1...10, id: \.self) { n in
                                Text("\(n)").tag(n)
                            }
                        }
                        .frame(width: 80)
                        .onChange(of: dataStore.settings.maxConcurrentDownloads) { _ in
                            dataStore.saveSettings()
                        }
                    }

                    HStack {
                        Text("Default Output Template")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                        Spacer()
                        TextField("%(title)s.%(ext)s", text: $dataStore.settings.defaultOutputTemplate)
                            .formTextField()
                            .frame(maxWidth: 400)
                            .onChange(of: dataStore.settings.defaultOutputTemplate) { _ in
                                dataStore.saveSettings()
                            }
                    }
                }
                .glassCard()

                // Behavior
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(ModernColors.orange)
                        Text("Behavior")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)
                    }

                    Toggle("Show notifications on completion", isOn: $dataStore.settings.showNotificationsOnComplete)
                        .onChange(of: dataStore.settings.showNotificationsOnComplete) { _ in dataStore.saveSettings() }
                    Toggle("Auto-fetch metadata when URL is pasted", isOn: $dataStore.settings.autoFetchMetadata)
                        .onChange(of: dataStore.settings.autoFetchMetadata) { _ in dataStore.saveSettings() }
                    Toggle("Auto-detect playlists", isOn: $dataStore.settings.autoDetectPlaylists)
                        .onChange(of: dataStore.settings.autoDetectPlaylists) { _ in dataStore.saveSettings() }
                    Toggle("Enable stealth mode by default", isOn: $dataStore.settings.stealthModeEnabled)
                        .onChange(of: dataStore.settings.stealthModeEnabled) { _ in dataStore.saveSettings() }
                    Toggle("Check for yt-dlp updates on launch", isOn: $dataStore.settings.checkForUpdatesOnLaunch)
                        .onChange(of: dataStore.settings.checkForUpdatesOnLaunch) { _ in dataStore.saveSettings() }
                }
                .glassCard()

                // Library
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "books.vertical")
                            .foregroundColor(ModernColors.purple)
                        Text("Library")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)
                    }

                    Toggle("Keep download history", isOn: $dataStore.settings.keepDownloadHistory)
                        .onChange(of: dataStore.settings.keepDownloadHistory) { _ in dataStore.saveSettings() }

                    HStack {
                        Text("Max history items")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                        Spacer()
                        Picker("", selection: $dataStore.settings.maxHistoryItems) {
                            Text("100").tag(100)
                            Text("500").tag(500)
                            Text("1000").tag(1000)
                            Text("5000").tag(5000)
                        }
                        .frame(width: 100)
                        .onChange(of: dataStore.settings.maxHistoryItems) { _ in dataStore.saveSettings() }
                    }

                    Toggle("Enable thumbnail cache", isOn: $dataStore.settings.thumbnailCacheEnabled)
                        .onChange(of: dataStore.settings.thumbnailCacheEnabled) { _ in dataStore.saveSettings() }
                }
                .glassCard()

                // About
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(ModernColors.teal)
                        Text("About")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)
                    }

                    Text("ytdlp-gui v1.0.0")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(ModernColors.textPrimary)
                    Text("A modern macOS GUI for yt-dlp")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)
                    Text("Created by Jordan Koch")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)
                }
                .glassCard()
            }
            .padding(32)
        }
    }
}
