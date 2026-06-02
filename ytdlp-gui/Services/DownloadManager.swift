//
//  DownloadManager.swift
//  ytdlp-gui
//
//  Download queue manager with concurrency control, pause/resume/cancel
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import os
import UserNotifications

@MainActor
class DownloadManager: ObservableObject {
    static let shared = DownloadManager()

    @Published var queue: [DownloadItem] = []
    @Published var totalSpeed: Double = 0
    @Published var totalCompleted: Int = 0
    @Published var totalFailed: Int = 0

    private var activeServices: [UUID: YTDLPService] = [:]
    private var activeTasks: [UUID: Task<Void, Never>] = [:]
    private var progressTasks: [UUID: Task<Void, Never>] = [:]
    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "DownloadManager")

    var activeCount: Int {
        queue.filter { $0.status.isActive }.count
    }

    var queuedCount: Int {
        queue.filter { $0.status == .queued }.count
    }

    // MARK: - Enqueue

    @discardableResult
    func enqueue(url: String, options: YTDLPOptions = YTDLPOptions(), presetName: String? = nil, outputDir: String? = nil) -> UUID {
        var item = DownloadItem(url: url, options: options)
        item.presetName = presetName
        item.outputDirectoryOverride = outputDir
        queue.append(item)
        logger.info("Enqueued: \(url)")
        saveQueue()
        processQueue()
        return item.id
    }

    func enqueueMultiple(urls: [String], options: YTDLPOptions = YTDLPOptions()) {
        // Pre-compute stealth configuration once for the entire batch instead
        // of calling StealthManager.shared.nextUserAgent() per-download in startDownload.
        // Each item gets a frozen user agent so the pool isn't exhausted during enqueue.
        let stealth = DataStore.shared.stealthProfile
        let batchUserAgent: String? = (stealth.isEnabled && stealth.rotateUserAgents)
            ? StealthManager.shared.nextUserAgent() : nil

        for url in urls {
            var batchOptions = options
            if let ua = batchUserAgent {
                batchOptions.userAgent = ua
            }
            let item = DownloadItem(url: url, options: batchOptions)
            queue.append(item)
        }
        processQueue()
    }

    // MARK: - Queue Processing

    func processQueue() {
        // Session-level pause check
        if SessionManager.shared.isSessionPaused { return }

        let settings = DataStore.shared.settings
        let active = queue.filter { $0.status.isActive }.count
        let available = settings.maxConcurrentDownloads - active
        guard available > 0 else { return }

        // Skip-list filtering: mark skip-listed items before processing
        let sessionConfig = DataStore.shared.sessionConfig
        if sessionConfig.skipListEnabled {
            for i in queue.indices where queue[i].status == .queued {
                if SkipListManager.shared.isSkipped(queue[i].url) {
                    queue[i].status = .skipped
                    queue[i].errorMessage = SkipListManager.shared.reason(for: queue[i].url)?.rawValue
                }
            }
        }

        // Batch gating: if batch limit reached, don't start more until batch resets
        if sessionConfig.batchingEnabled && SessionManager.shared.shouldStartNewBatch() {
            SessionManager.shared.completeBatch()
            Task {
                let batchDelay = SessionManager.shared.nextInterBatchDelay()
                logger.info("Inter-batch delay: \(String(format: "%.1f", batchDelay))s")
                try? await Task.sleep(nanoseconds: UInt64(batchDelay * 1_000_000_000))
                await MainActor.run {
                    let newSize = SessionManager.shared.generateBatchSize()
                    if newSize > 0 {
                        self.processQueue()
                    } else {
                        // Zero-batch: wait again then generate a new batch
                        Task {
                            let zeroDelay = SessionManager.shared.nextInterBatchDelay()
                            self.logger.info("Zero-batch idle: \(String(format: "%.1f", zeroDelay))s")
                            try? await Task.sleep(nanoseconds: UInt64(zeroDelay * 1_000_000_000))
                            await MainActor.run {
                                _ = SessionManager.shared.generateBatchSize()
                                self.processQueue()
                            }
                        }
                    }
                }
            }
            return
        }

        let pending = queue.filter { $0.status == .queued }
        for item in pending.prefix(available) {
            startDownload(item.id)
        }
    }

    func processQueueWithCookieCheck() {
        let sessionConfig = DataStore.shared.sessionConfig
        if sessionConfig.cookieAutoRefreshEnabled {
            Task {
                _ = await CookieRefreshService.shared.ensureFreshCookies()
                await MainActor.run { self.processQueue() }
            }
        } else {
            processQueue()
        }
    }

    // MARK: - Start Download

    private func startDownload(_ id: UUID) {
        guard let index = queue.firstIndex(where: { $0.id == id }) else { return }

        queue[index].status = .downloading
        queue[index].startedAt = Date()

        let service = YTDLPService()
        activeServices[id] = service

        let item = queue[index]
        let outputDir = item.outputDirectoryOverride ?? DataStore.shared.settings.outputDirectory

        // Apply stealth — Nova strategy: cookies + player_client is the core.
        // Identity spoofing (user-agent, referer, consent cookie) is COUNTERPRODUCTIVE
        // when valid session cookies are present — YouTube detects the mismatch.
        var options = item.options
        let stealth = DataStore.shared.stealthProfile
        if stealth.isEnabled {
            // 1. Cookies — use --cookies-from-browser directly (file export goes stale instantly
            // because YouTube rotates tokens on access; subprocess inherits keychain access)
            if let browserCookie = stealth.cookieSource.ytdlpValue {
                options.cookiesFromBrowser = browserCookie
            } else if stealth.cookieSource == .file, let path = stealth.cookieFilePath, !path.isEmpty {
                options.cookies = path
            }

            // 2. Player client (Nova uses "web,default" — never rotate when using cookies)
            let hasCookies = options.cookies != nil || options.cookiesFromBrowser != nil
            if hasCookies {
                options.extractorArgs.append("youtube:player_client=web,default")
            } else {
                // No cookies — use full stealth suite (anonymous mode)
                if stealth.rotateUserAgents {
                    options.userAgent = StealthManager.shared.nextUserAgent()
                }
                if let target = stealth.impersonateTarget, !target.isEmpty,
                   BinaryManager.shared.impersonateAvailable {
                    options.impersonate = target
                }
                if stealth.usePlayerClientRotation {
                    let client = stealth.playerClients.randomElement() ?? "web"
                    options.extractorArgs.append("youtube:player_client=\(client)")
                }
                if stealth.setReferer {
                    options.referer = "https://www.youtube.com/"
                }
                if stealth.sendConsentCookie {
                    options.addHeaders.append("Cookie:CONSENT=PENDING+999")
                }
            }

            // 3. PO token (overrides player client when set)
            if let poToken = stealth.poToken, !poToken.isEmpty {
                options.extractorArgs = options.extractorArgs.filter { !$0.contains("player_client") }
                var parts = "player_client=web;po_token=\(poToken)"
                if let visitorData = stealth.visitorData, !visitorData.isEmpty {
                    parts += ";visitor_data=\(visitorData)"
                }
                options.extractorArgs.append("youtube:\(parts)")
            }

            // 4. Proxy (independent of cookie state)
            if stealth.proxyEnabled, let proxy = StealthManager.shared.nextProxy() {
                options.proxy = proxy
            }
        }

        // Apply speed limiter
        if let rateLimit = SpeedLimiter.shared.rateLimitArgument() {
            options.limitRate = rateLimit
        }

        // Smart audio extraction: detect music and route to audio output
        let audioConfig = DataStore.shared.audioConfig
        var effectiveOutputDir = outputDir
        if audioConfig.enabled && audioConfig.autoDetectMusic {
            let title = item.title ?? item.url
            let isMusicContent = audioConfig.isMusicContent(
                title: title,
                channel: item.uploader,
                duration: item.duration
            )
            if isMusicContent {
                options.extractAudio = true
                options.audioFormat = audioConfig.format.ytdlpCodec
                options.audioQuality = audioConfig.quality.ytdlpValue
                if audioConfig.embedThumbnail { options.embedThumbnail = true }
                if audioConfig.embedMetadata { options.embedMetadata = true }
                effectiveOutputDir = audioConfig.outputDirectory

                // Parse artist/title for output template
                let (artist, parsedTitle) = audioConfig.parseArtistAndTitle(from: title)
                if let artist = artist {
                    options.outputTemplate = "\(artist) - \(parsedTitle ?? title).%(ext)s"
                }

                logger.info("Music detected: routing to audio extraction → \(effectiveOutputDir)")
            }
        }

        let sessionConfig = DataStore.shared.sessionConfig
        let task = Task {
            // Apply delay: use Nova-style realistic delays if enabled, otherwise standard stealth delay
            let delay = SessionManager.shared.nextInterDownloadDelay()
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            // Channel-switch delay (additional pause when switching between channels)
            let channelDelay = SessionManager.shared.channelSwitchDelay(for: item.url)
            if channelDelay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(channelDelay * 1_000_000_000))
            }

            do {
                let result = try await service.download(url: item.url, options: options, outputDir: effectiveOutputDir)

                await MainActor.run {
                    if let idx = self.queue.firstIndex(where: { $0.id == id }) {
                        self.queue[idx].status = .completed
                        self.queue[idx].completedAt = Date()
                        self.queue[idx].outputPath = result.outputPath
                        self.queue[idx].progress.percentage = 100
                        self.totalCompleted += 1

                        // Report success to session manager (resets consecutive failure counters)
                        SessionManager.shared.reportSuccess()

                        // Add to library
                        let fileSize = self.getFileSize(path: result.outputPath)
                        let libraryItem = LibraryItem(from: self.queue[idx], filePath: result.outputPath ?? "", fileSize: fileSize)
                        DataStore.shared.addToLibrary(libraryItem)

                        // Execute post-download actions
                        if let outputPath = result.outputPath {
                            PostDownloadManager.shared.executeActions(for: outputPath, metadata: self.queue[idx])
                        }

                        // Send notification
                        self.sendCompletionNotification(title: self.queue[idx].title ?? "Download", success: true)
                    }
                    self.cleanupDownload(id)
                    self.processQueue()
                }
            } catch let error as YTDLPError {
                await MainActor.run {
                    if let idx = self.queue.firstIndex(where: { $0.id == id }) {
                        // Handle soft blocks: skip and add to skip list
                        if case .softBlocked = error {
                            let action = SessionManager.shared.reportSoftError(url: item.url, reason: error.skipReason ?? .unavailable)
                            self.queue[idx].status = .skipped
                            self.queue[idx].errorMessage = error.localizedDescription
                            self.cleanupDownload(id)
                            self.processQueue()
                            return
                        }

                        // Handle hard blocks: report to session manager
                        let isRetryable = error.isHardBlock
                        if isRetryable {
                            let action = SessionManager.shared.reportHardBlock(url: item.url, error: error)
                            switch action {
                            case .pauseSession, .haltSession:
                                self.queue[idx].status = .failed
                                self.queue[idx].errorMessage = error.localizedDescription
                                self.totalFailed += 1
                                self.cleanupDownload(id)
                                self.pauseAll()
                                return
                            default:
                                break
                            }
                        }

                        // Standard retry logic (unchanged)
                        if isRetryable && stealth.retryOn429 && self.queue[idx].retryCount < stealth.maxRetries {
                            self.queue[idx].retryCount += 1
                            self.queue[idx].status = .retrying
                            let errorCode = error == .rateLimited ? "429" : "403"
                            self.logger.info("HTTP \(errorCode), rotating identity and retrying (\(self.queue[idx].retryCount)/\(stealth.maxRetries))")

                            StealthManager.shared.rotateIdentity()

                            Task {
                                let backoff = StealthManager.shared.exponentialBackoff(attempt: self.queue[idx].retryCount)
                                try? await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                                await MainActor.run {
                                    if let idx = self.queue.firstIndex(where: { $0.id == id }) {
                                        self.queue[idx].status = .queued
                                        self.cleanupDownload(id)
                                        self.processQueue()
                                    }
                                }
                            }
                        } else {
                            self.queue[idx].status = .failed
                            self.queue[idx].errorMessage = error.localizedDescription
                            self.totalFailed += 1
                            self.sendCompletionNotification(title: self.queue[idx].title ?? "Download", success: false)
                        }
                    }
                    self.cleanupDownload(id)
                    self.processQueue()
                }
            } catch {
                await MainActor.run {
                    if let idx = self.queue.firstIndex(where: { $0.id == id }) {
                        self.queue[idx].status = .failed
                        self.queue[idx].errorMessage = error.localizedDescription
                        self.totalFailed += 1
                    }
                    self.cleanupDownload(id)
                    self.processQueue()
                }
            }
        }

        activeTasks[id] = task

        // Observe progress — store the task so it can be cancelled when the download ends
        let progressTask = Task { [weak self] in
            for await _ in service.$currentProgress.values {
                guard let self = self, !Task.isCancelled else { break }
                if let idx = self.queue.firstIndex(where: { $0.id == id }) {
                    self.queue[idx].progress = service.currentProgress
                }
                self.updateTotalSpeed()
            }
        }
        progressTasks[id] = progressTask
    }

    // MARK: - Queue Controls

    func pause(_ id: UUID) {
        guard let index = queue.firstIndex(where: { $0.id == id }) else { return }
        activeServices[id]?.cancel()
        queue[index].status = .paused
        cleanupDownload(id)
        processQueue()
    }

    func resume(_ id: UUID) {
        guard let index = queue.firstIndex(where: { $0.id == id }),
              queue[index].status == .paused else { return }
        queue[index].status = .queued
        processQueue()
    }

    func cancelDownload(_ id: UUID) {
        guard let index = queue.firstIndex(where: { $0.id == id }) else { return }
        activeServices[id]?.cancel()
        activeTasks[id]?.cancel()
        queue[index].status = .cancelled
        cleanupDownload(id)
        processQueue()
    }

    func removeFromQueue(_ id: UUID) {
        activeServices[id]?.cancel()
        activeTasks[id]?.cancel()
        cleanupDownload(id)
        queue.removeAll { $0.id == id }
    }

    func clearCompleted() {
        queue.removeAll { $0.status.isTerminal }
    }

    func pauseAll() {
        for item in queue where item.status.isActive {
            pause(item.id)
        }
    }

    func resumeAll() {
        for item in queue where item.status == .paused {
            resume(item.id)
        }
    }

    func retryFailed(_ id: UUID) {
        guard let index = queue.firstIndex(where: { $0.id == id }),
              queue[index].status == .failed else { return }
        queue[index].status = .queued
        queue[index].errorMessage = nil
        queue[index].retryCount = 0
        processQueue()
    }

    // MARK: - Queue Persistence

    private var queueFile: URL {
        DataStore.shared.appSupportDirectory.appendingPathComponent("queue.json")
    }

    func saveQueue() {
        let saveable = queue.filter { !$0.status.isTerminal }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(saveable)
            try data.write(to: queueFile, options: .atomic)
        } catch {
            logger.error("Failed to save queue: \(error.localizedDescription)")
        }
    }

    func restoreQueue() {
        guard FileManager.default.fileExists(atPath: queueFile.path) else { return }
        do {
            let data = try Data(contentsOf: queueFile)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            var restored = try decoder.decode([DownloadItem].self, from: data)
            // Reset active/retrying items to queued so they restart
            for i in restored.indices {
                if restored[i].status.isActive || restored[i].status == .retrying {
                    restored[i].status = .queued
                    restored[i].progress = DownloadProgress()
                }
            }
            let restoredCount = restored.filter { $0.status == .queued || $0.status == .paused }.count
            if restoredCount > 0 {
                queue = restored
                logger.info("Restored \(restoredCount) queued items from disk")
                processQueue()
            }
        } catch {
            logger.error("Failed to restore queue: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func cleanupDownload(_ id: UUID) {
        activeServices.removeValue(forKey: id)
        activeTasks.removeValue(forKey: id)
        progressTasks.removeValue(forKey: id)?.cancel()
        saveQueue()
    }

    private func updateTotalSpeed() {
        totalSpeed = activeServices.values.reduce(0) { $0 + $1.currentProgress.speed }
    }

    private func getFileSize(path: String?) -> Int64 {
        guard let path = path else { return 0 }
        return (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int64) ?? 0
    }

    private func sendCompletionNotification(title: String, success: Bool) {
        guard DataStore.shared.settings.showNotificationsOnComplete else { return }

        let content = UNMutableNotificationContent()
        content.title = success ? "Download Complete" : "Download Failed"
        content.body = title
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Service Access (for progress binding in views)

    func service(for id: UUID) -> YTDLPService? {
        activeServices[id]
    }
}

