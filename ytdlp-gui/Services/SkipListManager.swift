//
//  SkipListManager.swift
//  ytdlp-gui
//
//  Persistent skip list — URLs that should never be re-attempted (members-only, geo-blocked, etc.)
//  Inspired by Nova's nova_yt_new_episodes.py skip_list.json pattern.
//  Created by Jordan Koch on 2026-06-02.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import os

@MainActor
class SkipListManager: ObservableObject {
    static let shared = SkipListManager()

    @Published var entries: [SkipListEntry] = []

    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "SkipListManager")

    private var skipListFile: URL {
        DataStore.shared.appSupportDirectory.appendingPathComponent("skiplist.json")
    }

    var count: Int { entries.count }

    // MARK: - Lookup

    func isSkipped(_ url: String) -> Bool {
        guard DataStore.shared.sessionConfig.skipListEnabled else { return false }
        let normalized = normalizeURL(url)
        return entries.contains { normalizeURL($0.url) == normalized }
    }

    func filterSkipped(urls: [String]) -> [String] {
        guard DataStore.shared.sessionConfig.skipListEnabled else { return urls }
        return urls.filter { !isSkipped($0) }
    }

    func reason(for url: String) -> SkipReason? {
        let normalized = normalizeURL(url)
        return entries.first { normalizeURL($0.url) == normalized }?.reason
    }

    // MARK: - Mutations

    func addToSkipList(url: String, reason: SkipReason, source: String? = nil) {
        guard !isSkipped(url) else { return }
        let entry = SkipListEntry(url: url, reason: reason, source: source)
        entries.append(entry)
        saveSkipList()
        logger.info("Skip list +1: \(reason.rawValue) — \(url.prefix(80))")
    }

    func removeFromSkipList(_ id: UUID) {
        entries.removeAll { $0.id == id }
        saveSkipList()
    }

    func removeFromSkipList(url: String) {
        let normalized = normalizeURL(url)
        entries.removeAll { normalizeURL($0.url) == normalized }
        saveSkipList()
    }

    func clearAll() {
        entries.removeAll()
        saveSkipList()
        logger.info("Skip list cleared")
    }

    // MARK: - Persistence

    func loadSkipList() {
        guard FileManager.default.fileExists(atPath: skipListFile.path) else { return }
        do {
            let data = try Data(contentsOf: skipListFile)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            entries = try decoder.decode([SkipListEntry].self, from: data)
            logger.info("Loaded \(self.entries.count) skip list entries")
        } catch {
            logger.error("Failed to load skip list: \(error.localizedDescription)")
        }
    }

    func saveSkipList() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(entries)
            try data.write(to: skipListFile, options: .atomic)
        } catch {
            logger.error("Failed to save skip list: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func normalizeURL(_ url: String) -> String {
        var u = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if u.hasSuffix("/") { u.removeLast() }
        u = u.replacingOccurrences(of: "https://www.youtube.com", with: "https://youtube.com")
        u = u.replacingOccurrences(of: "http://", with: "https://")
        return u.lowercased()
    }
}
