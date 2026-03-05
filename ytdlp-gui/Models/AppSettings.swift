//
//  AppSettings.swift
//  ytdlp-gui
//
//  Global application settings
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

struct AppSettings: Codable {
    var outputDirectory: String = NSHomeDirectory() + "/Downloads"
    var maxConcurrentDownloads: Int = 3
    var showNotificationsOnComplete: Bool = true
    var autoFetchMetadata: Bool = true
    var autoDetectPlaylists: Bool = true
    var defaultPresetId: UUID?
    var keepDownloadHistory: Bool = true
    var maxHistoryItems: Int = 1000
    var thumbnailCacheEnabled: Bool = true
    var thumbnailCacheSizeMB: Int = 500
    var checkForUpdatesOnLaunch: Bool = true
    var stealthModeEnabled: Bool = true
    var defaultOutputTemplate: String = "%(title)s.%(ext)s"
    var theme: AppTheme = .dark

    // Speed limiter (migrated from UserDefaults)
    var speedLimiterEnabled: Bool = false
    var speedLimiterGlobalKBps: Int = 0
    var speedLimiterPerDownloadKBps: Int = 0

    enum AppTheme: String, Codable, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
    }
}
