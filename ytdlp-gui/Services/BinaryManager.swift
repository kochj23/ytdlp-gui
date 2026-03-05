//
//  BinaryManager.swift
//  ytdlp-gui
//
//  Manages yt-dlp and ffmpeg binary locations, bundling, and updates
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import os

@MainActor
class BinaryManager: ObservableObject {
    static let shared = BinaryManager()

    @Published var ytdlpVersion: String = "Unknown"
    @Published var ffmpegVersion: String = "Unknown"
    @Published var isUpdating: Bool = false
    @Published var updateStatus: String = ""

    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "BinaryManager")
    private let fileManager = FileManager.default

    // Cache resolved paths so findBinary() doesn't re-run `which` on every call
    private var binaryPathCache: [String: String] = [:]

    private var appSupportBinDir: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let binDir = appSupport.appendingPathComponent("ytdlp-gui/bin", isDirectory: true)
        try? fileManager.createDirectory(at: binDir, withIntermediateDirectories: true)
        return binDir
    }

    // MARK: - Binary Paths

    var ytdlpPath: String {
        findBinary("yt-dlp")
    }

    var ffmpegPath: String {
        findBinary("ffmpeg")
    }

    /// Searches for a binary in order: app support, bundle, Homebrew (ARM/Intel), PATH via `which`
    private func findBinary(_ name: String) -> String {
        if let cached = binaryPathCache[name] { return cached }

        // 1. App support (updated binary)
        let appSupportPath = appSupportBinDir.appendingPathComponent(name).path
        if fileManager.isExecutableFile(atPath: appSupportPath) {
            binaryPathCache[name] = appSupportPath
            return appSupportPath
        }

        // 2. Bundled binary
        if let bundledPath = Bundle.main.path(forResource: name, ofType: nil, inDirectory: "Binaries"),
           fileManager.isExecutableFile(atPath: bundledPath) {
            binaryPathCache[name] = bundledPath
            return bundledPath
        }

        // 3. Homebrew (Apple Silicon)
        let homebrewARM = "/opt/homebrew/bin/\(name)"
        if fileManager.isExecutableFile(atPath: homebrewARM) {
            binaryPathCache[name] = homebrewARM
            return homebrewARM
        }

        // 4. Homebrew (Intel)
        let homebrewIntel = "/usr/local/bin/\(name)"
        if fileManager.isExecutableFile(atPath: homebrewIntel) {
            binaryPathCache[name] = homebrewIntel
            return homebrewIntel
        }

        // 5. Resolve from PATH using `which`
        if let resolved = resolveFromPATH(name) {
            binaryPathCache[name] = resolved
            return resolved
        }

        // 6. Return best-guess path (caller should check isExecutable)
        logger.warning("\(name) not found in any known location")
        return homebrewARM
    }

    /// Uses /usr/bin/which to find a binary on the user's PATH
    private func resolveFromPATH(_ name: String) -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [name]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   fileManager.isExecutableFile(atPath: path) {
                    return path
                }
            }
        } catch {}
        return nil
    }

    var ffprobePath: String {
        let dir = URL(fileURLWithPath: ffmpegPath).deletingLastPathComponent().path
        return dir + "/ffprobe"
    }

    // MARK: - Version Detection

    func detectVersions() async {
        ytdlpVersion = await getVersion(binary: ytdlpPath, args: ["--version"])
        ffmpegVersion = await getVersion(binary: ffmpegPath, args: ["-version"])
        logger.info("yt-dlp: \(self.ytdlpVersion), ffmpeg: \(self.ffmpegVersion)")
    }

    private func getVersion(binary: String, args: [String]) async -> String {
        return await withCheckedContinuation { continuation in
            let process = Process()
            let pipe = Pipe()

            process.executableURL = URL(fileURLWithPath: binary)
            process.arguments = args
            process.standardOutput = pipe
            process.standardError = pipe

            // Use terminationHandler so we don't block a Swift concurrency thread
            process.terminationHandler = { proc in
                guard proc.terminationStatus == 0 else {
                    continuation.resume(returning: "Not Found")
                    return
                }
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                guard let output = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) else {
                    continuation.resume(returning: "Not Found")
                    return
                }
                // ffmpeg outputs a long string — grab the version from the first line
                let firstLine = output.components(separatedBy: "\n").first ?? output
                if firstLine.contains("ffmpeg version") {
                    let parts = firstLine.components(separatedBy: " ")
                    if parts.count >= 3 {
                        continuation.resume(returning: parts[2])
                        return
                    }
                }
                continuation.resume(returning: firstLine)
            }

            do {
                try process.run()
            } catch {
                logger.error("Failed to get version for \(binary): \(error.localizedDescription)")
                continuation.resume(returning: "Not Found")
            }
        }
    }

    // MARK: - Binary Availability

    var isYTDLPAvailable: Bool {
        fileManager.isExecutableFile(atPath: ytdlpPath)
    }

    var isFFmpegAvailable: Bool {
        fileManager.isExecutableFile(atPath: ffmpegPath)
    }

    /// Check if --impersonate is available (requires curl_cffi)
    @Published var impersonateAvailable: Bool = false

    func checkImpersonateSupport() async {
        let result = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: ytdlpPath)
            process.arguments = ["--list-impersonate-targets"]
            process.standardOutput = pipe
            process.standardError = pipe

            // Use terminationHandler so we don't block a Swift concurrency thread
            process.terminationHandler = { proc in
                guard proc.terminationStatus == 0 else {
                    continuation.resume(returning: false)
                    return
                }
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                let hasAvailable = output.contains("Chrome") && !output.contains("(unavailable)")
                    || output.contains("Safari") && !output.split(separator: "\n").filter { $0.contains("Safari") }.allSatisfy { $0.contains("unavailable") }
                continuation.resume(returning: hasAvailable)
            }

            do {
                try process.run()
            } catch {
                continuation.resume(returning: false)
            }
        }
        impersonateAvailable = result
        if !result {
            logger.info("TLS impersonation unavailable (curl_cffi not installed)")
        }
    }

    // MARK: - Update from GitHub

    func updateYTDLP() async throws {
        isUpdating = true
        updateStatus = "Checking for updates..."
        defer { isUpdating = false }

        do {
            let output: String = try await withCheckedThrowingContinuation { continuation in
                let process = Process()
                let pipe = Pipe()

                process.executableURL = URL(fileURLWithPath: ytdlpPath)
                process.arguments = ["--update"]
                process.standardOutput = pipe
                process.standardError = pipe

                // Use terminationHandler so we don't block a Swift concurrency thread
                process.terminationHandler = { proc in
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    if proc.terminationStatus == 0 {
                        continuation.resume(returning: output)
                    } else {
                        continuation.resume(throwing: YTDLPError.downloadFailed(output))
                    }
                }

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: YTDLPError.executionFailed(error))
                }
            }
            updateStatus = "Updated successfully"
            logger.info("yt-dlp update output: \(output)")
        } catch {
            updateStatus = "Update failed: \(error.localizedDescription)"
            logger.error("yt-dlp update failed: \(error.localizedDescription)")
            throw error
        }

        // Invalidate path cache so next lookup picks up the new binary
        binaryPathCache.removeValue(forKey: "yt-dlp")
        await detectVersions()
    }

    // MARK: - Ensure Bundled Binaries

    func ensureBinariesExist() {
        // Copy bundled binaries to app support if they don't exist
        let binaries = ["yt-dlp", "ffmpeg", "ffprobe"]

        for binary in binaries {
            let destPath = appSupportBinDir.appendingPathComponent(binary)
            guard !fileManager.fileExists(atPath: destPath.path) else { continue }

            if let bundledPath = Bundle.main.path(forResource: binary, ofType: nil, inDirectory: "Binaries") {
                do {
                    try fileManager.copyItem(atPath: bundledPath, toPath: destPath.path)
                    // Make executable
                    try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destPath.path)
                    logger.info("Copied bundled \(binary) to app support")
                } catch {
                    logger.error("Failed to copy \(binary): \(error.localizedDescription)")
                }
            }
        }

        // Invalidate cache so newly copied binaries are picked up
        binaryPathCache.removeAll()
    }
}
