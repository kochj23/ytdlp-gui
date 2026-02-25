//
//  LibraryItem.swift
//  ytdlp-gui
//
//  Persistent download history record
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

struct LibraryItem: Identifiable, Codable {
    let id: UUID
    var url: String
    var title: String
    var uploader: String?
    var duration: TimeInterval?
    var thumbnailPath: String?
    var thumbnailURL: String?
    var filePath: String
    var fileSize: Int64
    var format: String?
    var resolution: String?
    var codec: String?
    var downloadedAt: Date
    var downloadDuration: TimeInterval
    var options: YTDLPOptions
    var tags: [String] = []
    var isFavorite: Bool = false
    var playlistTitle: String?
    var playlistIndex: Int?

    init(from download: DownloadItem, filePath: String, fileSize: Int64) {
        self.id = UUID()
        self.url = download.url
        self.title = download.title ?? "Unknown"
        self.uploader = download.uploader
        self.duration = download.duration
        self.thumbnailURL = download.thumbnailURL
        self.filePath = filePath
        self.fileSize = fileSize
        self.options = download.options
        self.downloadedAt = Date()
        self.downloadDuration = download.startedAt.map { Date().timeIntervalSince($0) } ?? 0
        self.playlistTitle = download.playlistTitle
        self.playlistIndex = download.playlistIndex

        // Derive format info from options
        if download.options.extractAudio {
            self.format = download.options.audioFormat ?? "audio"
        } else {
            self.format = download.options.mergeOutputFormat ?? "mp4"
        }
    }

    // Aliases for convenience
    var originalURL: String { url }
    var videoCodec: String? { codec }
    var audioCodec: String? { nil } // Not tracked separately yet

    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .binary)
    }

    var durationFormatted: String? {
        guard let dur = duration else { return nil }
        let hours = Int(dur) / 3600
        let minutes = (Int(dur) % 3600) / 60
        let seconds = Int(dur) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    var fileExists: Bool {
        FileManager.default.fileExists(atPath: filePath)
    }
}
