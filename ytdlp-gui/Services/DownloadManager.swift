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
    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "DownloadManager")

    var activeCount: Int {
        queue.filter { $0.status.isActive }.count
    }

    var queuedCount: Int {
        queue.filter { $0.status == .queued }.count
    }

    // MARK: - Enqueue

    func enqueue(url: String, options: YTDLPOptions = YTDLPOptions(), presetName: String? = nil) {
        var item = DownloadItem(url: url, options: options)
        item.presetName = presetName
        queue.append(item)
        logger.info("Enqueued: \(url)")
        processQueue()
    }

    func enqueueMultiple(urls: [String], options: YTDLPOptions = YTDLPOptions()) {
        for url in urls {
            let item = DownloadItem(url: url, options: options)
            queue.append(item)
        }
        processQueue()
    }

    // MARK: - Queue Processing

    func processQueue() {
        let settings = DataStore.shared.settings
        let active = queue.filter { $0.status.isActive }.count
        let available = settings.maxConcurrentDownloads - active
        guard available > 0 else { return }

        let pending = queue.filter { $0.status == .queued }
        for item in pending.prefix(available) {
            startDownload(item.id)
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
        let outputDir = DataStore.shared.settings.outputDirectory

        // Apply stealth if enabled
        var options = item.options
        let stealth = DataStore.shared.stealthProfile
        if stealth.isEnabled {
            if stealth.rotateUserAgents {
                options.userAgent = StealthManager.shared.nextUserAgent()
            }
            if let target = stealth.impersonateTarget, !target.isEmpty {
                options.impersonate = target
            }
            if let browserCookie = stealth.cookieSource.ytdlpValue {
                options.cookiesFromBrowser = browserCookie
            }
            if stealth.proxyEnabled, let proxy = StealthManager.shared.nextProxy() {
                options.proxy = proxy
            }
        }

        let task = Task {
            // Apply random delay if stealth enabled
            if stealth.isEnabled && stealth.randomDelayEnabled {
                let delay = StealthManager.shared.randomDelay()
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            do {
                let result = try await service.download(url: item.url, options: options, outputDir: outputDir)

                await MainActor.run {
                    if let idx = self.queue.firstIndex(where: { $0.id == id }) {
                        self.queue[idx].status = .completed
                        self.queue[idx].completedAt = Date()
                        self.queue[idx].outputPath = result.outputPath
                        self.queue[idx].progress.percentage = 100
                        self.totalCompleted += 1

                        // Add to library
                        let fileSize = self.getFileSize(path: result.outputPath)
                        let libraryItem = LibraryItem(from: self.queue[idx], filePath: result.outputPath ?? "", fileSize: fileSize)
                        DataStore.shared.addToLibrary(libraryItem)

                        // Send notification
                        self.sendCompletionNotification(title: self.queue[idx].title ?? "Download", success: true)
                    }
                    self.cleanupDownload(id)
                    self.processQueue()
                }
            } catch let error as YTDLPError {
                await MainActor.run {
                    if let idx = self.queue.firstIndex(where: { $0.id == id }) {
                        if error == .rateLimited && stealth.retryOn429 && self.queue[idx].retryCount < stealth.maxRetries {
                            // Auto-retry with identity rotation
                            self.queue[idx].retryCount += 1
                            self.queue[idx].status = .retrying
                            self.logger.info("Rate limited, retrying (\(self.queue[idx].retryCount)/\(stealth.maxRetries))")

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

        // Observe progress
        Task {
            for await _ in service.$currentProgress.values {
                if let idx = queue.firstIndex(where: { $0.id == id }) {
                    queue[idx].progress = service.currentProgress
                }
                updateTotalSpeed()
            }
        }
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

    // MARK: - Helpers

    private func cleanupDownload(_ id: UUID) {
        activeServices.removeValue(forKey: id)
        activeTasks.removeValue(forKey: id)
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

// MARK: - Equatable for YTDLPError
extension YTDLPError: Equatable {
    static func == (lhs: YTDLPError, rhs: YTDLPError) -> Bool {
        switch (lhs, rhs) {
        case (.rateLimited, .rateLimited): return true
        case (.forbidden, .forbidden): return true
        case (.cancelled, .cancelled): return true
        case (.binaryNotFound, .binaryNotFound): return true
        default: return false
        }
    }
}
