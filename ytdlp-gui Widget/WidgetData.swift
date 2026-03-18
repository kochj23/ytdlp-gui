//
//  WidgetData.swift
//  ytdlp-gui Widget
//
//  Shared data models for the ytdlp-gui macOS widget.
//  Created by Jordan Koch on 2026-03-18.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

// MARK: - Widget Download Data

/// Snapshot of the download queue state for widget display
struct YTDLPWidgetData: Codable {
    var activeDownloads: [WidgetDownloadItem]
    var queuedCount: Int
    var completedToday: Int
    var failedCount: Int
    var totalBytesDownloadedToday: Int64
    var currentSpeedBytesPerSecond: Double
    var stealthModeActive: Bool
    var lastUpdated: Date

    static var placeholder: YTDLPWidgetData {
        YTDLPWidgetData(
            activeDownloads: [
                WidgetDownloadItem(
                    id: UUID().uuidString,
                    title: "How to Build Great Apps",
                    uploader: "WWDC",
                    progress: 0.62,
                    status: "Downloading",
                    speedBytesPerSecond: 4_500_000,
                    etaSeconds: 42
                )
            ],
            queuedCount: 3,
            completedToday: 7,
            failedCount: 0,
            totalBytesDownloadedToday: 2_400_000_000,
            currentSpeedBytesPerSecond: 4_500_000,
            stealthModeActive: false,
            lastUpdated: Date()
        )
    }

    static var empty: YTDLPWidgetData {
        YTDLPWidgetData(
            activeDownloads: [],
            queuedCount: 0,
            completedToday: 0,
            failedCount: 0,
            totalBytesDownloadedToday: 0,
            currentSpeedBytesPerSecond: 0,
            stealthModeActive: false,
            lastUpdated: Date()
        )
    }
}

/// Lightweight download item for widget display
struct WidgetDownloadItem: Codable, Identifiable {
    let id: String
    var title: String
    var uploader: String?
    var progress: Double       // 0.0 – 1.0
    var status: String
    var speedBytesPerSecond: Double
    var etaSeconds: Int?
}

// MARK: - Formatting Helpers

extension YTDLPWidgetData {
    var formattedSpeed: String {
        formatBytes(currentSpeedBytesPerSecond) + "/s"
    }

    var formattedTotalToday: String {
        formatBytes(Double(totalBytesDownloadedToday))
    }

    private func formatBytes(_ bytes: Double) -> String {
        if bytes >= 1_073_741_824 {
            return String(format: "%.1f GB", bytes / 1_073_741_824)
        } else if bytes >= 1_048_576 {
            return String(format: "%.1f MB", bytes / 1_048_576)
        } else if bytes >= 1024 {
            return String(format: "%.0f KB", bytes / 1024)
        }
        return String(format: "%.0f B", bytes)
    }
}

extension WidgetDownloadItem {
    var formattedETA: String? {
        guard let eta = etaSeconds, eta > 0 else { return nil }
        if eta < 60 { return "\(eta)s" }
        if eta < 3600 { return "\(eta / 60)m \(eta % 60)s" }
        return "\(eta / 3600)h \(eta % 3600 / 60)m"
    }
}
