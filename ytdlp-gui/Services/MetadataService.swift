//
//  MetadataService.swift
//  ytdlp-gui
//
//  Fetch video metadata and thumbnails using yt-dlp --dump-json
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import AppKit
import os

@MainActor
class MetadataService: ObservableObject {
    static let shared = MetadataService()

    @Published var isFetching = false

    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "MetadataService")
    private var thumbnailCache: [String: NSImage] = [:]

    // MARK: - Fetch Metadata

    func fetchMetadata(url: String) async throws -> MediaMetadata {
        isFetching = true
        defer { isFetching = false }

        let service = YTDLPService()
        let metadata = try await service.fetchMetadata(url: url)
        logger.info("Fetched metadata for: \(metadata.title ?? "Unknown")")
        return metadata
    }

    // MARK: - Fetch Available Formats

    func fetchFormats(url: String) async throws -> [FormatInfo] {
        let service = YTDLPService()
        let metadata = try await service.fetchMetadata(url: url)
        return metadata.formats ?? []
    }

    // MARK: - Thumbnail Loading

    func loadThumbnail(url: String) async -> NSImage? {
        if let cached = thumbnailCache[url] {
            return cached
        }

        guard let imageURL = URL(string: url) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            if let image = NSImage(data: data) {
                thumbnailCache[url] = image
                return image
            }
        } catch {
            logger.debug("Failed to load thumbnail: \(error.localizedDescription)")
        }

        return nil
    }

    // MARK: - Cache Management

    func clearThumbnailCache() {
        thumbnailCache.removeAll()
        logger.info("Thumbnail cache cleared")
    }

    var cacheSize: Int {
        thumbnailCache.count
    }
}
