//
//  SpeedLimiter.swift
//  ytdlp-gui
//
//  Download speed limiting (per-download and global)
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import os

@MainActor
class SpeedLimiter: ObservableObject {
    static let shared = SpeedLimiter()

    @Published var isEnabled = false
    @Published var globalLimitKBps: Int = 0 // 0 = unlimited
    @Published var perDownloadLimitKBps: Int = 0

    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "SpeedLimiter")

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

    // MARK: - Persistence

    func save() {
        UserDefaults.standard.set(isEnabled, forKey: "speedLimiter.enabled")
        UserDefaults.standard.set(globalLimitKBps, forKey: "speedLimiter.globalLimit")
        UserDefaults.standard.set(perDownloadLimitKBps, forKey: "speedLimiter.perDownloadLimit")
    }

    func load() {
        isEnabled = UserDefaults.standard.bool(forKey: "speedLimiter.enabled")
        globalLimitKBps = UserDefaults.standard.integer(forKey: "speedLimiter.globalLimit")
        perDownloadLimitKBps = UserDefaults.standard.integer(forKey: "speedLimiter.perDownloadLimit")
    }
}
