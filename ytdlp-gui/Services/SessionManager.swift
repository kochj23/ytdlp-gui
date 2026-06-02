//
//  SessionManager.swift
//  ytdlp-gui
//
//  Session-level orchestration: batch sizing, block detection, session pause, delays.
//  Nova pattern: consecutive failures halt the session; downloads are batched with long pauses.
//  Created by Jordan Koch on 2026-06-02.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import os

@MainActor
class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published var sessionState: SessionState = .active
    @Published var consecutiveHardBlocks: Int = 0
    @Published var consecutiveRateLimits: Int = 0
    @Published var currentBatchSize: Int = 0
    @Published var downloadsInCurrentBatch: Int = 0
    @Published var sessionPausedUntil: Date?
    @Published var lastChannelURL: String?

    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "SessionManager")

    enum SessionState: String {
        case active = "Active"
        case paused = "Session Paused"
        case waitingBatch = "Batch Delay"
        case waitingZeroBatch = "Zero-Batch Idle"
    }

    enum SessionAction {
        case continueQueue
        case skipAndContinue(SkipReason)
        case pauseSession
        case haltSession
    }

    var config: SessionConfig { DataStore.shared.sessionConfig }

    // MARK: - Success/Failure Reporting

    func reportSuccess() {
        consecutiveHardBlocks = 0
        consecutiveRateLimits = 0
        downloadsInCurrentBatch += 1
    }

    func reportHardBlock(url: String, error: YTDLPError) -> SessionAction {
        consecutiveHardBlocks += 1
        consecutiveRateLimits += 1
        logger.warning("Hard block #\(self.consecutiveHardBlocks): \(url.prefix(60))")

        guard config.blockDetectionEnabled else { return .continueQueue }

        if config.sessionRateLimitEnabled && consecutiveRateLimits >= config.maxConsecutiveRateLimits {
            logger.error("Session halt: \(self.consecutiveRateLimits) consecutive rate limits")
            pauseSession(hours: config.hardBlockPauseDurationHours)
            return .pauseSession
        }

        if consecutiveHardBlocks >= config.maxConsecutiveHardBlocks {
            logger.error("Session halt: \(self.consecutiveHardBlocks) consecutive hard blocks")
            pauseSession(hours: config.hardBlockPauseDurationHours)
            return .haltSession
        }

        return .continueQueue
    }

    func reportSoftError(url: String, reason: SkipReason) -> SessionAction {
        // Soft errors don't affect consecutive counters — they're per-URL problems
        if config.skipListEnabled {
            SkipListManager.shared.addToSkipList(url: url, reason: reason)
        }
        return .skipAndContinue(reason)
    }

    // MARK: - Delay Calculations

    func nextInterDownloadDelay() -> TimeInterval {
        guard config.realisticDelaysEnabled else {
            let stealth = DataStore.shared.stealthProfile
            return stealth.randomDelayEnabled
                ? Double.random(in: stealth.minDelay...stealth.maxDelay)
                : 0
        }
        return Double.random(in: config.interDownloadMinDelay...config.interDownloadMaxDelay)
    }

    func nextInterBatchDelay() -> TimeInterval {
        guard config.realisticDelaysEnabled else { return 0 }
        return Double.random(in: config.interBatchMinDelay...config.interBatchMaxDelay)
    }

    func channelSwitchDelay(for url: String) -> TimeInterval {
        guard config.realisticDelaysEnabled else { return 0 }
        let currentChannel = extractChannel(from: url)
        let previousChannel = lastChannelURL.flatMap { extractChannel(from: $0) }
        lastChannelURL = url

        if let prev = previousChannel, prev != currentChannel {
            return Double.random(in: config.channelSwitchMinDelay...config.channelSwitchMaxDelay)
        }
        return 0
    }

    // MARK: - Batch Management

    func shouldStartNewBatch() -> Bool {
        guard config.batchingEnabled else { return false }
        return downloadsInCurrentBatch >= currentBatchSize
    }

    func generateBatchSize() -> Int {
        guard config.batchingEnabled else { return Int.max }
        let size = Int.random(in: config.minBatchSize...config.maxBatchSize)
        currentBatchSize = size
        downloadsInCurrentBatch = 0
        if size == 0 {
            sessionState = .waitingZeroBatch
            logger.info("Zero-batch generated — deliberate idle period")
        } else {
            sessionState = .active
            logger.info("New batch: \(size) downloads")
        }
        return size
    }

    func completeBatch() {
        sessionState = .waitingBatch
        logger.info("Batch complete (\(self.downloadsInCurrentBatch)/\(self.currentBatchSize)), entering inter-batch delay")
    }

    // MARK: - Session Pause/Resume

    func pauseSession(hours: Double) {
        let until = Date().addingTimeInterval(hours * 3600)
        sessionPausedUntil = until
        sessionState = .paused
        logger.warning("Session paused until \(until)")
    }

    func resumeSession() {
        sessionPausedUntil = nil
        sessionState = .active
        consecutiveHardBlocks = 0
        consecutiveRateLimits = 0
        logger.info("Session resumed manually")
    }

    var isSessionPaused: Bool {
        guard sessionState == .paused else { return false }
        if let until = sessionPausedUntil, Date() >= until {
            sessionState = .active
            sessionPausedUntil = nil
            consecutiveHardBlocks = 0
            consecutiveRateLimits = 0
            logger.info("Session auto-resumed (pause expired)")
            return false
        }
        return true
    }

    func resetSession() {
        consecutiveHardBlocks = 0
        consecutiveRateLimits = 0
        currentBatchSize = 0
        downloadsInCurrentBatch = 0
        sessionPausedUntil = nil
        sessionState = .active
        lastChannelURL = nil
    }

    // MARK: - Helpers

    private func extractChannel(from url: String) -> String? {
        if url.contains("/channel/") || url.contains("/@") {
            let parts = url.split(separator: "/")
            if let idx = parts.firstIndex(where: { $0 == "channel" || $0.hasPrefix("@") }) {
                return String(parts[idx])
            }
        }
        return nil
    }
}
