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

    // Per-channel output routing
    var customOutputDirectory: String?
    var outputTemplate: OutputRouting = .default

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

    enum OutputRouting: String, Codable, CaseIterable, Identifiable {
        case `default` = "Default"
        case channelFolder = "Channel Folder"
        case plexShow = "Plex (Show/Season)"
        case plexMovie = "Plex (Movies)"
        case dateFolder = "Date Folder"
        case custom = "Custom Template"

        var id: String { rawValue }

        func outputTemplate(channelName: String) -> String {
            switch self {
            case .default:
                return "%(title)s.%(ext)s"
            case .channelFolder:
                return "\(channelName)/%(title)s.%(ext)s"
            case .plexShow:
                return "\(channelName)/Season 01/\(channelName) - S01E%(playlist_index|00)s - %(title)s.%(ext)s"
            case .plexMovie:
                return "\(channelName) (%(upload_date>%Y)s)/%(title)s.%(ext)s"
            case .dateFolder:
                return "%(upload_date>%Y-%m-%d)s/%(title)s.%(ext)s"
            case .custom:
                return "%(title)s.%(ext)s"
            }
        }
    }

    func effectiveOutputDirectory(fallback: String) -> String {
        customOutputDirectory ?? fallback
    }

    var effectiveOutputTemplate: String {
        outputTemplate.outputTemplate(channelName: name)
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
