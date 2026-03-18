//
//  SharedDataManager.swift
//  ytdlp-gui Widget
//
//  Manages shared data between the main app and widget using App Groups.
//  Created by Jordan Koch on 2026-03-18.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import WidgetKit

final class SharedDataManager {
    static let shared = SharedDataManager()

    private let appGroupIdentifier = "group.com.jordankoch.ytdlp-gui"
    private let widgetDataKey = "ytdlpWidgetData"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // MARK: - Read (Widget)

    func loadWidgetData() -> YTDLPWidgetData {
        guard
            let defaults = sharedDefaults,
            let data = defaults.data(forKey: widgetDataKey),
            let decoded = try? JSONDecoder().decode(YTDLPWidgetData.self, from: data)
        else {
            return .empty
        }
        return decoded
    }

    // MARK: - Write (Main App)

    func saveWidgetData(_ data: YTDLPWidgetData) {
        guard let defaults = sharedDefaults else { return }
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: widgetDataKey)
            defaults.synchronize()
            WidgetCenter.shared.reloadTimelines(ofKind: "YTDLPWidget")
        }
    }

    // MARK: - Deep Link URLs

    static let openAppURL = URL(string: "ytdlp-gui://open")!
    static let addDownloadURL = URL(string: "ytdlp-gui://add")!

    // MARK: - Data Age

    func dataAgeString(for date: Date?) -> String {
        guard let date else { return "Never" }
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        return "\(seconds / 3600)h ago"
    }
}
