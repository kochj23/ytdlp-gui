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

    private var appSupportBinDir: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let binDir = appSupport.appendingPathComponent("ytdlp-gui/bin", isDirectory: true)
        try? fileManager.createDirectory(at: binDir, withIntermediateDirectories: true)
        return binDir
    }

    // MARK: - Binary Paths

    var ytdlpPath: String {
        // 1. Check app support for updated binary
        let appSupportPath = appSupportBinDir.appendingPathComponent("yt-dlp").path
        if fileManager.isExecutableFile(atPath: appSupportPath) {
            return appSupportPath
        }

        // 2. Check bundled binary
        if let bundledPath = Bundle.main.path(forResource: "yt-dlp", ofType: nil, inDirectory: "Binaries") {
            if fileManager.isExecutableFile(atPath: bundledPath) {
                return bundledPath
            }
        }

        // 3. Check Homebrew (Apple Silicon)
        if fileManager.isExecutableFile(atPath: "/opt/homebrew/bin/yt-dlp") {
            return "/opt/homebrew/bin/yt-dlp"
        }

        // 4. Check Homebrew (Intel)
        if fileManager.isExecutableFile(atPath: "/usr/local/bin/yt-dlp") {
            return "/usr/local/bin/yt-dlp"
        }

        // 5. Try PATH
        return "/opt/homebrew/bin/yt-dlp"
    }

    var ffmpegPath: String {
        let appSupportPath = appSupportBinDir.appendingPathComponent("ffmpeg").path
        if fileManager.isExecutableFile(atPath: appSupportPath) {
            return appSupportPath
        }

        if let bundledPath = Bundle.main.path(forResource: "ffmpeg", ofType: nil, inDirectory: "Binaries") {
            if fileManager.isExecutableFile(atPath: bundledPath) {
                return bundledPath
            }
        }

        if fileManager.isExecutableFile(atPath: "/opt/homebrew/bin/ffmpeg") {
            return "/opt/homebrew/bin/ffmpeg"
        }

        if fileManager.isExecutableFile(atPath: "/usr/local/bin/ffmpeg") {
            return "/usr/local/bin/ffmpeg"
        }

        return "/opt/homebrew/bin/ffmpeg"
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

            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) {
                    // ffmpeg outputs a long string, grab first line
                    let firstLine = output.components(separatedBy: "\n").first ?? output
                    if firstLine.contains("ffmpeg version") {
                        // Parse: "ffmpeg version 7.1 Copyright..."
                        let parts = firstLine.components(separatedBy: " ")
                        if parts.count >= 3 {
                            continuation.resume(returning: parts[2])
                            return
                        }
                    }
                    continuation.resume(returning: firstLine)
                    return
                }
            } catch {
                logger.error("Failed to get version for \(binary): \(error.localizedDescription)")
            }
            continuation.resume(returning: "Not Found")
        }
    }

    // MARK: - Binary Availability

    var isYTDLPAvailable: Bool {
        fileManager.isExecutableFile(atPath: ytdlpPath)
    }

    var isFFmpegAvailable: Bool {
        fileManager.isExecutableFile(atPath: ffmpegPath)
    }

    // MARK: - Update from GitHub

    func updateYTDLP() async throws {
        isUpdating = true
        updateStatus = "Checking for updates..."
        defer { isUpdating = false }

        // Use yt-dlp's built-in update mechanism
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: ytdlpPath)
        process.arguments = ["--update"]
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        if process.terminationStatus == 0 {
            updateStatus = "Updated successfully"
            logger.info("yt-dlp update output: \(output)")
        } else {
            updateStatus = "Update failed: \(output)"
            logger.error("yt-dlp update failed: \(output)")
        }

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
    }
}
