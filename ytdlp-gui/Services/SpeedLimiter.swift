//
//  SpeedLimiter.swift
//  ytdlp-gui
//
//  Download speed limiting (per-download and global)
//  Persists via DataStore/AppSettings (consistent with all other settings).
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import os

@MainActor
class SpeedLimiter: ObservableObject {
    static let shared = SpeedLimiter()

    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "SpeedLimiter")

    @Published var isEnabled: Bool = false {
        didSet {
            DataStore.shared.settings.speedLimiterEnabled = isEnabled
            DataStore.shared.saveSettings()
        }
    }

    @Published var globalLimitKBps: Int = 0 {
        didSet {
            DataStore.shared.settings.speedLimiterGlobalKBps = globalLimitKBps
            DataStore.shared.saveSettings()
        }
    }

    @Published var perDownloadLimitKBps: Int = 0 {
        didSet {
            DataStore.shared.settings.speedLimiterPerDownloadKBps = perDownloadLimitKBps
            DataStore.shared.saveSettings()
        }
    }

    // Preset speed limits
    static let presets: [(String, Int)] = [
        ("Unlimited", 0),
        ("512 KB/s", 512),
        ("1 MB/s", 1024),
        ("2 MB/s", 2048),
        ("5 MB/s", 5120),
        ("10 MB/s", 10240),
        ("25 MB/s", 25600),
        ("50 MB/s", 51200),
    ]

    // MARK: - yt-dlp Arguments

    /// Returns --limit-rate argument for yt-dlp
    func rateLimitArgument() -> String? {
        guard isEnabled else { return nil }

        let limit: Int
        if perDownloadLimitKBps > 0 {
            limit = perDownloadLimitKBps
        } else if globalLimitKBps > 0 {
            // Divide global limit by active download count
            let active = max(DownloadManager.shared.activeCount, 1)
            limit = globalLimitKBps / active
        } else {
            return nil
        }

        return "\(limit)K"
    }

    // MARK: - Display

    static func formatSpeed(_ kbps: Int) -> String {
        if kbps == 0 { return "Unlimited" }
        if kbps >= 1024 {
            return String(format: "%.1f MB/s", Double(kbps) / 1024.0)
        }
        return "\(kbps) KB/s"
    }

    // MARK: - Persistence (backed by DataStore)

    func load() {
        isEnabled = DataStore.shared.settings.speedLimiterEnabled
        globalLimitKBps = DataStore.shared.settings.speedLimiterGlobalKBps
        perDownloadLimitKBps = DataStore.shared.settings.speedLimiterPerDownloadKBps
    }

    func save() {
        // No-op: saves happen automatically in @Published didSet blocks.
        // Kept for API compatibility.
    }
}
