//
//  PlaylistService.swift
//  ytdlp-gui
//
//  Detect and fetch playlist information
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import os

@MainActor
class PlaylistService: ObservableObject {
    static let shared = PlaylistService()

    @Published var isFetching = false
    @Published var currentPlaylist: PlaylistInfo?

    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "PlaylistService")

    // Known playlist URL patterns
    private static let playlistPatterns: [String] = [
        "list=",
        "/playlist",
        "/sets/",
        "/album/",
        "/channel/",
        "/c/",
        "/@",
    ]

    // MARK: - Playlist Detection

    func isPlaylistURL(_ url: String) -> Bool {
        let lowered = url.lowercased()
        return Self.playlistPatterns.contains { lowered.contains($0) }
    }

    // MARK: - Fetch Playlist

    func fetchPlaylist(url: String) async throws -> PlaylistInfo {
        isFetching = true
        defer { isFetching = false }

        let service = YTDLPService()
        let info = try await service.fetchPlaylistInfo(url: url)
        currentPlaylist = info
        logger.info("Fetched playlist: \(info.title ?? "Unknown") with \(info.entries?.count ?? 0) entries")
        return info
    }

    // MARK: - Download Selected Entries

    func downloadSelected(from playlist: PlaylistInfo, selectedIndices: Set<Int>, options: YTDLPOptions) {
        let manager = DownloadManager.shared
        let entries = playlist.entries ?? []

        for index in selectedIndices.sorted() {
            guard index < entries.count else { continue }
            let entry = entries[index]
            guard let url = entry.url else { continue }
            manager.enqueue(url: url, options: options)
        }

        logger.info("Enqueued \(selectedIndices.count) items from playlist")
    }

    func clear() {
        currentPlaylist = nil
    }
}
