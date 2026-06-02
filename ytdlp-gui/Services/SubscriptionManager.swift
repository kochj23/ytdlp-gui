//
//  SubscriptionManager.swift
//  ytdlp-gui
//
//  Manages channel/playlist subscriptions for automatic downloads
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import os

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var subscriptions: [ChannelSubscription] = []
    @Published var isChecking = false

    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "SubscriptionManager")
    private var checkTimer: Timer?

    // MARK: - Start / Stop

    func startMonitoring() {
        loadSubscriptions()
        checkTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkDueSubscriptions()
            }
        }
        // Check immediately
        checkDueSubscriptions()
        logger.info("Subscription monitor started with \(self.subscriptions.count) subscriptions")
    }

    func stopMonitoring() {
        checkTimer?.invalidate()
        checkTimer = nil
    }

    // MARK: - Subscription Management

    func addSubscription(name: String, url: String, interval: ChannelSubscription.CheckInterval = .sixHours, options: YTDLPOptions = YTDLPOptions()) {
        var sub = ChannelSubscription(name: name, url: url, checkInterval: interval, options: options)
        sub.autoDownload = true
        subscriptions.append(sub)
        saveSubscriptions()
        logger.info("Added subscription: \(name)")
    }

    func removeSubscription(_ id: UUID) {
        subscriptions.removeAll { $0.id == id }
        saveSubscriptions()
    }

    func toggleSubscription(_ id: UUID) {
        if let index = subscriptions.firstIndex(where: { $0.id == id }) {
            subscriptions[index].isEnabled.toggle()
            saveSubscriptions()
        }
    }

    // MARK: - Check for New Content

    func checkDueSubscriptions() {
        let due = subscriptions.filter(\.isDueForCheck)
        guard !due.isEmpty else { return }

        isChecking = true
        logger.info("Checking \(due.count) subscriptions for new content")

        for sub in due {
            Task {
                await checkSubscription(sub.id)
            }
        }
    }

    func checkSubscription(_ id: UUID) async {
        guard let index = subscriptions.firstIndex(where: { $0.id == id }) else { return }

        let sub = subscriptions[index]
        let service = YTDLPService()

        do {
            let playlist = try await service.fetchPlaylistInfo(url: sub.url)
            let entries = playlist.entries ?? []

            // Find new entries not already downloaded
            let newEntries = entries.filter { entry in
                guard let entryId = entry.entryId else { return false }
                return !sub.downloadedVideoIds.contains(entryId)
            }

            if !newEntries.isEmpty && sub.autoDownload {
                let toDownload = Array(newEntries.prefix(sub.maxDownloadsPerCheck))
                for entry in toDownload {
                    if let url = entry.url {
                        // Skip-list check: don't enqueue known-bad URLs
                        guard !SkipListManager.shared.isSkipped(url) else { continue }

                        // Apply per-channel output routing
                        var opts = sub.options
                        opts.outputTemplate = sub.effectiveOutputTemplate
                        let subOutputDir = sub.effectiveOutputDirectory(fallback: DataStore.shared.settings.outputDirectory)
                        DownloadManager.shared.enqueue(
                            url: url,
                            options: opts,
                            outputDir: subOutputDir
                        )
                        if let entryId = entry.entryId {
                            subscriptions[index].downloadedVideoIds.append(entryId)
                        }
                    }
                }
                logger.info("Subscription '\(sub.name)': found \(newEntries.count) new, downloading \(toDownload.count)")
            }

            subscriptions[index].lastCheckedAt = Date()
            if let firstId = entries.first?.entryId {
                subscriptions[index].lastVideoId = firstId
            }

            saveSubscriptions()
        } catch {
            logger.error("Subscription check failed for '\(sub.name)': \(error.localizedDescription)")
        }

        if subscriptions.allSatisfy({ !$0.isDueForCheck }) {
            isChecking = false
        }
    }

    func forceCheckAll() {
        for index in subscriptions.indices {
            subscriptions[index].lastCheckedAt = nil
        }
        checkDueSubscriptions()
    }

    // MARK: - Persistence

    private var subscriptionFile: URL {
        DataStore.shared.appSupportDirectory.appendingPathComponent("subscriptions.json")
    }

    private func loadSubscriptions() {
        guard FileManager.default.fileExists(atPath: subscriptionFile.path) else { return }
        do {
            let data = try Data(contentsOf: subscriptionFile)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            subscriptions = try decoder.decode([ChannelSubscription].self, from: data)
        } catch {
            logger.error("Failed to load subscriptions: \(error.localizedDescription)")
        }
    }

    private func saveSubscriptions() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(subscriptions)
            try data.write(to: subscriptionFile, options: .atomic)
        } catch {
            logger.error("Failed to save subscriptions: \(error.localizedDescription)")
        }
    }
}
