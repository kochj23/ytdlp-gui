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
    @StateObject private var clipboardMonitor = ClipboardMonitor.shared
    @StateObject private var scheduleManager = ScheduleManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var speedLimiter = SpeedLimiter.shared

    init() {
        NovaAPIServer.shared.start()
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
                .environmentObject(downloadManager)
                .preferredColorScheme(dataStore.settings.theme.colorScheme)
                .onAppear {
                    setupApp()
                }
                .onOpenURL { url in
                    handleURL(url)
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

                Divider()

                Button("Toggle Clipboard Monitor") {
                    if clipboardMonitor.isMonitoring {
                        clipboardMonitor.stopMonitoring()
                    } else {
                        clipboardMonitor.startMonitoring()
                    }
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
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

        // Load speed limiter settings
        speedLimiter.load()

        // Ensure bundled binaries are available
        binaryManager.ensureBinariesExist()

        // Detect binary versions and capabilities
        Task {
            await binaryManager.detectVersions()
            await binaryManager.checkImpersonateSupport()
        }

        // Check for updates on launch
        if dataStore.settings.checkForUpdatesOnLaunch {
            Task {
                try? await binaryManager.updateYTDLP()
            }
        }

        // Start scheduler and subscription monitor
        scheduleManager.startScheduler()
        subscriptionManager.startMonitoring()

        // Initialize Nova session services
        SkipListManager.shared.loadSkipList()
        _ = SessionManager.shared
        if dataStore.sessionConfig.cookieAutoRefreshEnabled {
            CookieRefreshService.shared.startPeriodicCheck()
        }

        // Restore persisted download queue from last session
        DownloadManager.shared.restoreQueue()
    }

    // MARK: - URL Scheme Handler (ytdlp-gui://download?url=...)

    private func handleURL(_ url: URL) {
        guard url.scheme == "ytdlp-gui" else { return }
        if url.host == "download", let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let urlParam = components.queryItems?.first(where: { $0.name == "url" })?.value {
            downloadManager.enqueue(url: urlParam)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let newDownload = Notification.Name("newDownload")
}

// MARK: - AppTheme SwiftUI Helpers

extension AppSettings.AppTheme {
    /// Maps to SwiftUI's ColorScheme. nil means "follow system".
    var colorScheme: ColorScheme? {
        switch self {
        case .dark:   return .dark
        case .light:  return .light
        case .system: return nil
        }
    }
}
