//
//  DataStore.swift
//  ytdlp-gui
//
//  Central JSON-based persistence manager (OneOnOne pattern)
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import os

@MainActor
class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published var library: [LibraryItem] = []
    @Published var presets: [DownloadPreset] = []
    @Published var settings: AppSettings = AppSettings()
    @Published var stealthProfile: StealthProfile = StealthProfile()
    @Published var sessionConfig: SessionConfig = SessionConfig()
    @Published var isLoading: Bool = false

    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "DataStore")
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    var appSupportDirectory: URL { dataDirectory }

    private var dataDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let appDir = appSupport.appendingPathComponent("ytdlp-gui", isDirectory: true)
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir
    }

    var thumbnailCacheDir: URL {
        let dir = dataDirectory.appendingPathComponent("thumbnails", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // JSON file paths
    private var libraryFile: URL { dataDirectory.appendingPathComponent("library.json") }
    private var presetsFile: URL { dataDirectory.appendingPathComponent("presets.json") }
    private var settingsFile: URL { dataDirectory.appendingPathComponent("settings.json") }
    private var stealthFile: URL { dataDirectory.appendingPathComponent("stealth.json") }
    private var sessionConfigFile: URL { dataDirectory.appendingPathComponent("session_config.json") }

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Load All Data

    func loadData() {
        isLoading = true
        defer { isLoading = false }

        library = loadJSON(from: libraryFile) ?? []
        settings = loadJSON(from: settingsFile) ?? AppSettings()
        stealthProfile = loadJSON(from: stealthFile) ?? StealthProfile()
        sessionConfig = loadJSON(from: sessionConfigFile) ?? SessionConfig()

        // Load presets, merging with built-ins
        let savedPresets: [DownloadPreset] = loadJSON(from: presetsFile) ?? []
        let builtIns = DownloadPreset.builtInPresets
        let customPresets = savedPresets.filter { !$0.isBuiltIn }
        presets = builtIns + customPresets

        logger.info("Loaded \(self.library.count) library items, \(self.presets.count) presets")
    }

    // MARK: - Save All Data

    func saveData() {
        saveJSON(library, to: libraryFile)
        saveJSON(presets, to: presetsFile)
        saveJSON(settings, to: settingsFile)
        saveJSON(stealthProfile, to: stealthFile)
    }

    // MARK: - Library Operations

    func addToLibrary(_ item: LibraryItem) {
        library.insert(item, at: 0)
        if library.count > settings.maxHistoryItems {
            library = Array(library.prefix(settings.maxHistoryItems))
        }
        saveJSON(library, to: libraryFile)
    }

    func removeFromLibrary(_ id: UUID) {
        library.removeAll { $0.id == id }
        saveJSON(library, to: libraryFile)
    }

    func batchRemoveFromLibrary(ids: Set<UUID>) {
        library.removeAll { ids.contains($0.id) }
        saveJSON(library, to: libraryFile)
    }

    func toggleFavorite(_ id: UUID) {
        if let index = library.firstIndex(where: { $0.id == id }) {
            library[index].isFavorite.toggle()
            saveJSON(library, to: libraryFile)
        }
    }

    func searchLibrary(query: String) -> [LibraryItem] {
        guard !query.isEmpty else { return library }
        let lowered = query.lowercased()
        return library.filter { item in
            item.title.lowercased().contains(lowered) ||
            (item.uploader?.lowercased().contains(lowered) ?? false) ||
            item.url.lowercased().contains(lowered) ||
            item.tags.contains(where: { $0.lowercased().contains(lowered) })
        }
    }

    // MARK: - Preset Operations

    func addPreset(_ preset: DownloadPreset) {
        presets.append(preset)
        saveJSON(presets, to: presetsFile)
    }

    func removePreset(_ id: UUID) {
        presets.removeAll { $0.id == id && !$0.isBuiltIn }
        saveJSON(presets, to: presetsFile)
    }

    // MARK: - Settings

    func saveSettings() {
        saveJSON(settings, to: settingsFile)
    }

    func saveStealthProfile() {
        saveJSON(stealthProfile, to: stealthFile)
    }

    func saveSessionConfig() {
        saveJSON(sessionConfig, to: sessionConfigFile)
    }

    // MARK: - JSON Helpers

    private func loadJSON<T: Decodable>(from url: URL) -> T? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.error("Failed to load \(url.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
    }

    private func saveJSON<T: Encodable>(_ value: T, to url: URL) {
        do {
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            logger.error("Failed to save \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }
}
