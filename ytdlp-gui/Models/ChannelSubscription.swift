//
//  ChannelSubscription.swift
//  ytdlp-gui
//
//  Channel/playlist subscription for automatic downloads
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

struct ChannelSubscription: Identifiable, Codable {
    let id: UUID
    var name: String
    var url: String
    var checkInterval: CheckInterval
    var options: YTDLPOptions
    var isEnabled: Bool
    var lastCheckedAt: Date?
    var lastVideoId: String?
    var downloadedVideoIds: [String]
    var maxDownloadsPerCheck: Int
    var autoDownload: Bool
    var createdAt: Date

    init(name: String, url: String, checkInterval: CheckInterval = .sixHours, options: YTDLPOptions = YTDLPOptions()) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.checkInterval = checkInterval
        self.options = options
        self.isEnabled = true
        self.downloadedVideoIds = []
        self.maxDownloadsPerCheck = 5
        self.autoDownload = true
        self.createdAt = Date()
    }

    enum CheckInterval: String, Codable, CaseIterable, Identifiable {
        case thirtyMinutes = "30 min"
        case oneHour = "1 hour"
        case threeHours = "3 hours"
        case sixHours = "6 hours"
        case twelveHours = "12 hours"
        case daily = "Daily"
        case weekly = "Weekly"

        var id: String { rawValue }

        var seconds: TimeInterval {
            switch self {
            case .thirtyMinutes: return 1800
            case .oneHour: return 3600
            case .threeHours: return 10800
            case .sixHours: return 21600
            case .twelveHours: return 43200
            case .daily: return 86400
            case .weekly: return 604800
            }
        }
    }

    var isDueForCheck: Bool {
        guard isEnabled else { return false }
        guard let lastCheck = lastCheckedAt else { return true }
        return Date().timeIntervalSince(lastCheck) >= checkInterval.seconds
    }
}
