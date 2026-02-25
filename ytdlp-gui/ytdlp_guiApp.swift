//
//  ytdlp_guiApp.swift
//  ytdlp-gui
//
//  A modern macOS GUI for yt-dlp with full stealth capabilities
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI
import UserNotifications

@main
struct ytdlp_guiApp: App {
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var downloadManager = DownloadManager.shared
    @StateObject private var binaryManager = BinaryManager.shared

    init() {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
                .environmentObject(downloadManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    setupApp()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1400, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Download") {
                    NotificationCenter.default.post(name: .newDownload, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandMenu("Downloads") {
                Button("Pause All") {
                    downloadManager.pauseAll()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])

                Button("Resume All") {
                    downloadManager.resumeAll()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])

                Divider()

                Button("Clear Completed") {
                    downloadManager.clearCompleted()
                }
            }

            CommandMenu("Tools") {
                Button("Check for yt-dlp Updates") {
                    Task {
                        try? await binaryManager.updateYTDLP()
                    }
                }
                .keyboardShortcut("u", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView()
                .environmentObject(dataStore)
        }
    }

    private func setupApp() {
        // Load persisted data
        dataStore.loadData()

        // Ensure bundled binaries are available
        binaryManager.ensureBinariesExist()

        // Detect binary versions
        Task {
            await binaryManager.detectVersions()
        }

        // Check for updates on launch
        if dataStore.settings.checkForUpdatesOnLaunch {
            Task {
                try? await binaryManager.updateYTDLP()
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let newDownload = Notification.Name("newDownload")
}
