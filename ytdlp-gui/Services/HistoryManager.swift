//
//  HistoryManager.swift
//  ytdlp-gui
//
//  Persistent download history with search, filter, and statistics
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import os

@MainActor
class HistoryManager: ObservableObject {
    static let shared = HistoryManager()

    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "HistoryManager")

    // MARK: - Statistics

    var totalDownloads: Int {
        DataStore.shared.library.count
    }

    var totalSize: Int64 {
        DataStore.shared.library.reduce(0) { $0 + $1.fileSize }
    }

    var favoriteCount: Int {
        DataStore.shared.library.filter(\.isFavorite).count
    }

    // MARK: - Search & Filter

    func search(query: String, in library: [LibraryItem]) -> [LibraryItem] {
        guard !query.isEmpty else { return library }
        let lowered = query.lowercased()
        return library.filter { item in
            item.title.lowercased().contains(lowered) ||
            (item.uploader?.lowercased().contains(lowered) ?? false) ||
            item.originalURL.lowercased().contains(lowered) ||
            item.tags.contains { $0.lowercased().contains(lowered) }
        }
    }

    func filterByDate(from: Date?, to: Date?, in library: [LibraryItem]) -> [LibraryItem] {
        library.filter { item in
            if let from = from, item.downloadedAt < from { return false }
            if let to = to, item.downloadedAt > to { return false }
            return true
        }
    }

    func filterByFavorites(in library: [LibraryItem]) -> [LibraryItem] {
        library.filter(\.isFavorite)
    }

    // MARK: - Bulk Operations

    func removeOldItems(olderThan days: Int) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let ids = Set(DataStore.shared.library.filter { $0.downloadedAt < cutoff }.map(\.id))
        guard !ids.isEmpty else { return }
        DataStore.shared.batchRemoveFromLibrary(ids: ids)
        logger.info("Removed \(ids.count) items older than \(days) days")
    }

    func exportHistory(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(DataStore.shared.library)
        try data.write(to: url)
        logger.info("Exported \(DataStore.shared.library.count) items to \(url.path)")
    }

    func importHistory(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let items = try decoder.decode([LibraryItem].self, from: data)

        for item in items {
            if !DataStore.shared.library.contains(where: { $0.id == item.id }) {
                DataStore.shared.addToLibrary(item)
            }
        }

        logger.info("Imported \(items.count) items from \(url.path)")
    }

    // MARK: - Format Statistics

    func formatBreakdown() -> [(String, Int)] {
        var counts: [String: Int] = [:]
        for item in DataStore.shared.library {
            let ext = (item.filePath as NSString).pathExtension.lowercased()
            counts[ext, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }
    }

    // MARK: - Formatted Size

    static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
