//
//  CookieRefreshService.swift
//  ytdlp-gui
//
//  Automated cookie lifecycle management — checks staleness, refreshes via yt-dlp.
//  Nova pattern: cookies expire after 6h, auto-refresh by re-exporting from browser.
//  Created by Jordan Koch on 2026-06-02.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import os

@MainActor
class CookieRefreshService: ObservableObject {
    static let shared = CookieRefreshService()

    @Published var lastRefreshAt: Date?
    @Published var isRefreshing: Bool = false
    @Published var lastRefreshStatus: String?
    @Published var cookieFileAge: TimeInterval?

    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "CookieRefresh")
    private var periodicTask: Task<Void, Never>?

    var cookieFilePath: URL {
        DataStore.shared.appSupportDirectory.appendingPathComponent("cookies.txt")
    }

    // MARK: - Staleness Check

    func cookiesAreStale() -> Bool {
        guard let age = currentCookieFileAge() else { return true }
        let ttl = DataStore.shared.sessionConfig.cookieTTLSeconds
        return age > ttl
    }

    func currentCookieFileAge() -> TimeInterval? {
        let path = cookieFilePath.path
        guard FileManager.default.fileExists(atPath: path),
              let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let modDate = attrs[.modificationDate] as? Date else { return nil }
        let age = Date().timeIntervalSince(modDate)
        cookieFileAge = age
        return age
    }

    var cookieAgeFormatted: String? {
        guard let age = cookieFileAge else { return nil }
        let hours = Int(age) / 3600
        let minutes = (Int(age) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m old" }
        return "\(minutes)m old"
    }

    // MARK: - Refresh

    func ensureFreshCookies() async -> Bool {
        guard DataStore.shared.sessionConfig.cookieAutoRefreshEnabled else { return true }
        guard cookiesAreStale() else { return true }
        return await refreshCookies()
    }

    func refreshCookies() async -> Bool {
        guard !isRefreshing else { return false }
        isRefreshing = true
        defer { isRefreshing = false }

        let config = DataStore.shared.sessionConfig
        guard let browserValue = config.cookieRefreshBrowser.ytdlpValue else {
            lastRefreshStatus = "No browser configured"
            return false
        }

        let binary = BinaryManager.shared.ytdlpPath ?? "/opt/homebrew/bin/yt-dlp"
        let outputPath = cookieFilePath.path

        logger.info("Refreshing cookies from \(browserValue)...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binary)
        process.arguments = [
            "--cookies-from-browser", browserValue,
            "--cookies", outputPath,
            "--skip-download",
            "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        ]
        process.environment = ProcessInfo.processInfo.environment
        if var path = process.environment?["PATH"] {
            path = "/opt/homebrew/bin:/usr/local/bin:" + path
            process.environment?["PATH"] = path
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 && FileManager.default.fileExists(atPath: outputPath) {
                try FileManager.default.setAttributes(
                    [.posixPermissions: 0o600],
                    ofItemAtPath: outputPath
                )
                lastRefreshAt = Date()
                lastRefreshStatus = "Refreshed successfully"
                _ = currentCookieFileAge()
                logger.info("Cookie refresh succeeded")
                return true
            } else {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                lastRefreshStatus = "Refresh failed: \(output.prefix(100))"
                logger.error("Cookie refresh failed (exit \(process.terminationStatus))")
                return false
            }
        } catch {
            lastRefreshStatus = "Error: \(error.localizedDescription)"
            logger.error("Cookie refresh error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Periodic Check

    func startPeriodicCheck() {
        stopPeriodicCheck()
        periodicTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30 * 60 * 1_000_000_000) // 30 minutes
                guard !Task.isCancelled else { break }
                if cookiesAreStale() {
                    _ = await refreshCookies()
                }
            }
        }
        logger.info("Cookie periodic check started (30-min interval)")
    }

    func stopPeriodicCheck() {
        periodicTask?.cancel()
        periodicTask = nil
    }
}
