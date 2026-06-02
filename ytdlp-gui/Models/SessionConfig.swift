//
//  SessionConfig.swift
//  ytdlp-gui
//
//  Nova-derived session orchestration config: batching, delays, block detection, cookie refresh.
//  Separate from StealthProfile which governs per-request identity.
//  Created by Jordan Koch on 2026-06-02.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

struct SessionConfig: Codable {
    // MARK: - Cookie Auto-Refresh
    var cookieAutoRefreshEnabled: Bool = false
    var cookieTTLSeconds: TimeInterval = 21600 // 6 hours
    var cookieRefreshBrowser: CookieSource = .chrome

    // MARK: - Hard/Soft Block Detection
    var blockDetectionEnabled: Bool = true
    var maxConsecutiveHardBlocks: Int = 3
    var hardBlockPauseDurationHours: Double = 24.0

    // MARK: - Realistic Inter-Download Delays
    var realisticDelaysEnabled: Bool = false
    var interDownloadMinDelay: Double = 5.0
    var interDownloadMaxDelay: Double = 75.0
    var interBatchMinDelay: Double = 60.0
    var interBatchMaxDelay: Double = 188.5
    var channelSwitchMinDelay: Double = 5.0
    var channelSwitchMaxDelay: Double = 20.0

    // MARK: - Batch Sizing
    var batchingEnabled: Bool = false
    var minBatchSize: Int = 0
    var maxBatchSize: Int = 4

    // MARK: - Session-Level Rate Limit Awareness
    var sessionRateLimitEnabled: Bool = true
    var maxConsecutiveRateLimits: Int = 3

    // MARK: - Skip List
    var skipListEnabled: Bool = true
}
