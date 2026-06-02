//
//  DownloadItem.swift
//  ytdlp-gui
//
//  Represents a single download job in the queue
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

struct DownloadItem: Identifiable, Codable {
    let id: UUID
    var url: String
    var title: String?
    var uploader: String?
    var duration: TimeInterval?
    var thumbnailURL: String?
    var options: YTDLPOptions
    var presetName: String?

    // Status
    var status: DownloadStatus = .queued
    var progress: DownloadProgress = DownloadProgress()
    var errorMessage: String?
    var outputPath: String?

    // Timing
    var addedAt: Date = Date()
    var startedAt: Date?
    var completedAt: Date?

    // Retry (retry limit is controlled by StealthProfile.maxRetries)
    var retryCount: Int = 0

    // Per-channel output routing
    var outputDirectoryOverride: String?

    // Playlist context
    var playlistTitle: String?
    var playlistIndex: Int?
    var playlistTotal: Int?

    init(url: String, options: YTDLPOptions = YTDLPOptions()) {
        self.id = UUID()
        self.url = url
        self.options = options
    }
}

enum DownloadStatus: String, Codable, CaseIterable {
    case queued = "Queued"
    case fetchingMetadata = "Fetching Info"
    case downloading = "Downloading"
    case postProcessing = "Processing"
    case completed = "Completed"
    case failed = "Failed"
    case cancelled = "Cancelled"
    case paused = "Paused"
    case retrying = "Retrying"
    case skipped = "Skipped"

    var isActive: Bool {
        switch self {
        case .downloading, .fetchingMetadata, .postProcessing, .retrying:
            return true
        default:
            return false
        }
    }

    var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled, .skipped:
            return true
        default:
            return false
        }
    }
}

struct DownloadProgress: Codable {
    var percentage: Double = 0
    var downloadedBytes: Int64 = 0
    var totalBytes: Int64?
    var speed: Double = 0
    var eta: TimeInterval?
    var currentFragment: Int?
    var totalFragments: Int?
    var currentFile: String?
    var statusLine: String?

    var speedFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(speed), countStyle: .binary) + "/s"
    }

    var downloadedFormatted: String {
        ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .binary)
    }

    var totalFormatted: String? {
        guard let total = totalBytes else { return nil }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .binary)
    }

    var etaFormatted: String? {
        guard let eta = eta, eta > 0 else { return nil }
        let minutes = Int(eta) / 60
        let seconds = Int(eta) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return "\(seconds)s"
    }
}

struct MediaMetadata: Codable {
    var id: String?
    var title: String?
    var description: String?
    var uploader: String?
    var uploaderId: String?
    var uploaderUrl: String?
    var channel: String?
    var duration: TimeInterval?
    var viewCount: Int?
    var likeCount: Int?
    var uploadDate: String?
    var thumbnailUrl: String?
    var webpageUrl: String?
    var formats: [FormatInfo]?
    var isPlaylist: Bool = false
    var playlistCount: Int?
    var playlistTitle: String?
    var categories: [String]?
    var tags: [String]?

    enum CodingKeys: String, CodingKey {
        case id, title, description, uploader, channel, duration, categories, tags, formats
        case uploaderId = "uploader_id"
        case uploaderUrl = "uploader_url"
        case viewCount = "view_count"
        case likeCount = "like_count"
        case uploadDate = "upload_date"
        case thumbnailUrl = "thumbnail"
        case webpageUrl = "webpage_url"
        case isPlaylist = "_type"
        case playlistCount = "playlist_count"
        case playlistTitle = "playlist_title"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        uploader = try container.decodeIfPresent(String.self, forKey: .uploader)
        uploaderId = try container.decodeIfPresent(String.self, forKey: .uploaderId)
        uploaderUrl = try container.decodeIfPresent(String.self, forKey: .uploaderUrl)
        channel = try container.decodeIfPresent(String.self, forKey: .channel)
        duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
        viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount)
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount)
        uploadDate = try container.decodeIfPresent(String.self, forKey: .uploadDate)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        webpageUrl = try container.decodeIfPresent(String.self, forKey: .webpageUrl)
        playlistCount = try container.decodeIfPresent(Int.self, forKey: .playlistCount)
        playlistTitle = try container.decodeIfPresent(String.self, forKey: .playlistTitle)
        categories = try container.decodeIfPresent([String].self, forKey: .categories)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        formats = try container.decodeIfPresent([FormatInfo].self, forKey: .formats)

        // Check if this is a playlist
        if let typeStr = try container.decodeIfPresent(String.self, forKey: .isPlaylist) {
            isPlaylist = typeStr == "playlist"
        } else {
            isPlaylist = false
        }
    }

    init() {}
}

struct FormatInfo: Identifiable, Codable {
    var id: String { formatId }
    var formatId: String = ""
    var ext: String = ""
    var resolution: String?
    var width: Int?
    var height: Int?
    var fps: Double?
    var vcodec: String?
    var acodec: String?
    var filesize: Int64?
    var filesizeApprox: Int64?
    var tbr: Double?
    var vbr: Double?
    var abr: Double?
    var asr: Int?
    var formatNote: String?
    var hasVideo: Bool { vcodec != nil && vcodec != "none" }
    var hasAudio: Bool { acodec != nil && acodec != "none" }

    enum CodingKeys: String, CodingKey {
        case formatId = "format_id"
        case ext, resolution, width, height, fps, vcodec, acodec, filesize, tbr, vbr, abr, asr
        case filesizeApprox = "filesize_approx"
        case formatNote = "format_note"
    }

    var displaySize: String {
        if let size = filesize ?? filesizeApprox {
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .binary)
        }
        return "Unknown"
    }

    var displayResolution: String {
        if let h = height {
            if h >= 2160 { return "4K" }
            if h >= 1440 { return "1440p" }
            return "\(h)p"
        }
        return resolution ?? "Audio"
    }

    var displayCodec: String {
        var parts: [String] = []
        if let v = vcodec, v != "none" { parts.append(v) }
        if let a = acodec, a != "none" { parts.append(a) }
        return parts.joined(separator: " + ")
    }
}
