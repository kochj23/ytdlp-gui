//
//  ClipboardMonitor.swift
//  ytdlp-gui
//
//  Monitors clipboard for video URLs and offers quick download
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import AppKit
import os
import UserNotifications

@MainActor
class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()

    @Published var isMonitoring = false
    @Published var lastDetectedURL: String?
    @Published var showQuickDownload = false
    @Published var detectedMetadata: MediaMetadata?

    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "ClipboardMonitor")
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var ignoredURLs: Set<String> = []

    // Known video URL patterns
    private static let videoPatterns: [String] = [
        "youtube.com/watch",
        "youtu.be/",
        "youtube.com/playlist",
        "youtube.com/shorts",
        "vimeo.com/",
        "dailymotion.com/video",
        "twitch.tv/videos",
        "twitter.com/", "x.com/",
        "instagram.com/reel",
        "instagram.com/p/",
        "tiktok.com/",
        "facebook.com/watch",
        "reddit.com/r/",
        "soundcloud.com/",
        "bandcamp.com/",
        "bilibili.com/video",
        "nicovideo.jp/watch",
        "crunchyroll.com/watch",
    ]

    // MARK: - Start / Stop

    func startMonitoring() {
        guard !isMonitoring else { return }
        lastChangeCount = NSPasteboard.general.changeCount
        isMonitoring = true

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkClipboard()
            }
        }

        logger.info("Clipboard monitoring started")
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
        logger.info("Clipboard monitoring stopped")
    }

    // MARK: - Check Clipboard

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        guard let content = pasteboard.string(forType: .string) else { return }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isVideoURL(trimmed), !ignoredURLs.contains(trimmed) else { return }

        lastDetectedURL = trimmed
        showQuickDownload = true
        logger.info("Detected video URL: \(trimmed)")

        // Send notification
        sendDetectionNotification(url: trimmed)

        // Auto-fetch metadata
        if DataStore.shared.settings.autoFetchMetadata {
            Task {
                do {
                    detectedMetadata = try await MetadataService.shared.fetchMetadata(url: trimmed)
                } catch {
                    logger.debug("Auto-fetch metadata failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func isVideoURL(_ string: String) -> Bool {
        guard string.hasPrefix("http://") || string.hasPrefix("https://") else { return false }
        let lowered = string.lowercased()
        return Self.videoPatterns.contains { lowered.contains($0) }
    }

    // MARK: - Quick Actions

    func downloadDetected(preset: DownloadPreset? = nil) {
        guard let url = lastDetectedURL else { return }
        let options = preset?.options ?? YTDLPOptions()
        DownloadManager.shared.enqueue(url: url, options: options, presetName: preset?.name)
        dismissQuickDownload()
    }

    func dismissQuickDownload() {
        showQuickDownload = false
        if let url = lastDetectedURL {
            ignoredURLs.insert(url)
        }
        lastDetectedURL = nil
        detectedMetadata = nil
    }

    // MARK: - Notification

    private func sendDetectionNotification(url: String) {
        let content = UNMutableNotificationContent()
        content.title = "Video URL Detected"
        // Show domain only — full URLs can contain session tokens or tracking
        // parameters visible to anyone glancing at Notification Center.
        content.body = URL(string: url)?.host ?? "Tap to download"
        content.sound = .default
        content.categoryIdentifier = "CLIPBOARD_URL"

        let request = UNNotificationRequest(identifier: "clipboard-\(UUID().uuidString)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Reset

    func clearIgnored() {
        ignoredURLs.removeAll()
    }
}
