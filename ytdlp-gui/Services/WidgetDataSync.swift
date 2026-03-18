//
//  WidgetDataSync.swift
//  ytdlp-gui
//
//  Writes current download queue state to the App Group container
//  so the Widget Extension can display live data.
//  Call updateWidget() whenever queue state changes.
//
//  Created by Jordan Koch on 2026-03-18.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import WidgetKit

final class WidgetDataSync {
    static let shared = WidgetDataSync()

    private let appGroupIdentifier = "group.com.jordankoch.ytdlp-gui"
    private let widgetDataKey = "ytdlpWidgetData"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // MARK: - Public API

    /// Call this whenever queue state changes (item added, progress update, completion, failure).
    /// Throttled to max once per second to avoid excessive widget reloads.
    private var lastSync: Date = .distantPast

    func updateWidget(
        activeDownloads: [WidgetDownloadItem],
        queuedCount: Int,
        completedToday: Int,
        failedCount: Int,
        totalBytesDownloadedToday: Int64,
        currentSpeedBPS: Double,
        stealthModeActive: Bool
    ) {
        let now = Date()
        guard now.timeIntervalSince(lastSync) >= 1.0 else { return }
        lastSync = now

        let data = YTDLPWidgetData(
            activeDownloads: activeDownloads,
            queuedCount: queuedCount,
            completedToday: completedToday,
            failedCount: failedCount,
            totalBytesDownloadedToday: totalBytesDownloadedToday,
            currentSpeedBytesPerSecond: currentSpeedBPS,
            stealthModeActive: stealthModeActive,
            lastUpdated: now
        )

        guard let defaults = sharedDefaults else { return }
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: widgetDataKey)
            defaults.synchronize()
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "YTDLPWidget")
    }

    /// Build a WidgetDownloadItem from a DownloadItem
    static func widgetItem(from item: DownloadItem) -> WidgetDownloadItem {
        WidgetDownloadItem(
            id: item.id.uuidString,
            title: item.title ?? item.url,
            uploader: item.uploader,
            progress: item.progress.percentage / 100.0,
            status: item.status.rawValue,
            speedBytesPerSecond: item.progress.speed,
            etaSeconds: item.progress.eta.map { Int($0) }
        )
    }
}
