//
//  YTDLPService.swift
//  ytdlp-gui
//
//  Core service for executing yt-dlp commands with real-time progress parsing.
//  Uses Process with readabilityHandler for streaming output (RsyncGUI pattern).
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import os

class YTDLPService: ObservableObject {
    @Published var currentProgress: DownloadProgress = DownloadProgress()
    @Published var isRunning: Bool = false
    @Published var logOutput: [String] = []

    private var process: Process?
    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "YTDLPService")

    // MARK: - Download

    func download(url: String, options: YTDLPOptions, outputDir: String, password: String? = nil) async throws -> DownloadResult {
        let binaryManager = await BinaryManager.shared
        let binaryPath = await binaryManager.ytdlpPath
        let ffmpegPath = await binaryManager.ffmpegPath

        var args = options.toArguments()

        // Always add progress flags for real-time parsing
        args += ["--newline", "--progress"]

        // Set output directory
        args += ["-P", outputDir]

        // Set ffmpeg location
        args += ["--ffmpeg-location", URL(fileURLWithPath: ffmpegPath).deletingLastPathComponent().path]

        // Inject password from Keychain if provided
        if let pwd = password {
            args += ["--password", pwd]
        }

        // Add the URL last
        args.append(url)

        return try await executeProcess(binaryPath: binaryPath, arguments: args)
    }

    // MARK: - Fetch Metadata

    func fetchMetadata(url: String) async throws -> MediaMetadata {
        let binaryManager = await BinaryManager.shared
        let binaryPath = await binaryManager.ytdlpPath

        let args = ["--dump-json", "--no-download", "--no-warnings", url]
        let output = try await executeSimple(binaryPath: binaryPath, arguments: args)

        guard let data = output.data(using: .utf8) else {
            throw YTDLPError.parseError("Failed to convert output to data")
        }

        let decoder = JSONDecoder()
        return try decoder.decode(MediaMetadata.self, from: data)
    }

    // MARK: - Fetch Playlist Info

    func fetchPlaylistInfo(url: String) async throws -> PlaylistInfo {
        let binaryManager = await BinaryManager.shared
        let binaryPath = await binaryManager.ytdlpPath

        let args = ["--flat-playlist", "--dump-single-json", "--no-warnings", url]
        let output = try await executeSimple(binaryPath: binaryPath, arguments: args)

        guard let data = output.data(using: .utf8) else {
            throw YTDLPError.parseError("Failed to convert output to data")
        }

        let decoder = JSONDecoder()
        return try decoder.decode(PlaylistInfo.self, from: data)
    }

    // MARK: - List Formats

    func listFormats(url: String) async throws -> [FormatInfo] {
        let metadata = try await fetchMetadata(url: url)
        return metadata.formats ?? []
    }

    // MARK: - Cancel

    func cancel() {
        process?.terminate()
        isRunning = false
    }

    // MARK: - Process Execution (Real-time streaming)

    private func executeProcess(binaryPath: String, arguments: [String]) async throws -> DownloadResult {
        await MainActor.run {
            isRunning = true
            currentProgress = DownloadProgress()
            logOutput = []
        }

        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(throwing: YTDLPError.cancelled)
                return
            }

            let process = Process()
            self.process = process

            process.executableURL = URL(fileURLWithPath: binaryPath)
            process.arguments = arguments

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            // Thread-safe mutable state wrapper
            class ProcessState: @unchecked Sendable {
                let lock = NSLock()
                let group = DispatchGroup()
                var outputData = Data()
                var errorData = Data()
                var isTerminating = false
                var outputPath: String?
            }
            let state = ProcessState()

            // Real-time output streaming
            outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                state.lock.lock()
                let shouldProcess = !state.isTerminating
                if shouldProcess { state.group.enter() }
                state.lock.unlock()

                guard shouldProcess, let self = self else { return }
                defer { state.group.leave() }

                let data = handle.availableData
                guard !data.isEmpty else { return }

                let dataCopy = Data(data)

                state.lock.lock()
                state.outputData.append(dataCopy)
                state.lock.unlock()

                if let output = String(data: dataCopy, encoding: .utf8) {
                    let lines = output.components(separatedBy: "\n")
                    for line in lines where !line.isEmpty {
                        // Parse progress
                        if let progress = self.parseProgressLine(line) {
                            Task { @MainActor in
                                self.currentProgress = progress
                            }
                        }

                        // Detect output path
                        if line.contains("[download] Destination:") || line.contains("[ExtractAudio] Destination:") {
                            let path = line.components(separatedBy: "Destination: ").last?.trimmingCharacters(in: .whitespaces)
                            if let p = path {
                                state.lock.lock()
                                state.outputPath = p
                                state.lock.unlock()
                            }
                        }

                        // Detect merging
                        if line.contains("[Merger]") || line.contains("Merging formats into") {
                            if let path = line.components(separatedBy: "\"").dropFirst().first {
                                state.lock.lock()
                                state.outputPath = String(path)
                                state.lock.unlock()
                            }
                        }

                        Task { @MainActor in
                            self.logOutput.append(line)
                        }
                    }
                }
            }

            // Error output
            errorPipe.fileHandleForReading.readabilityHandler = { handle in
                state.lock.lock()
                let shouldProcess = !state.isTerminating
                if shouldProcess { state.group.enter() }
                state.lock.unlock()

                guard shouldProcess else { return }
                defer { state.group.leave() }

                let data = handle.availableData
                guard !data.isEmpty else { return }

                state.lock.lock()
                state.errorData.append(Data(data))
                state.lock.unlock()
            }

            // Termination
            process.terminationHandler = { [weak self] proc in
                state.lock.lock()
                state.isTerminating = true
                state.lock.unlock()

                _ = state.group.wait(timeout: .now() + 2.0)

                outputPipe.fileHandleForReading.readabilityHandler = nil
                errorPipe.fileHandleForReading.readabilityHandler = nil

                Task { @MainActor in
                    self?.isRunning = false
                    self?.currentProgress.percentage = proc.terminationStatus == 0 ? 100 : self?.currentProgress.percentage ?? 0
                }

                state.lock.lock()
                let fullOutput = String(data: state.outputData, encoding: .utf8) ?? ""
                let errorOutput = String(data: state.errorData, encoding: .utf8) ?? ""
                let finalOutputPath = state.outputPath
                state.lock.unlock()

                if proc.terminationStatus == 0 {
                    let result = DownloadResult(
                        success: true,
                        outputPath: finalOutputPath,
                        output: fullOutput,
                        errorOutput: errorOutput.isEmpty ? nil : errorOutput
                    )
                    continuation.resume(returning: result)
                } else {
                    // Check for specific error types
                    let combinedOutput = errorOutput + fullOutput
                    if combinedOutput.contains("HTTP Error 429") || combinedOutput.contains("429 Too Many Requests") {
                        continuation.resume(throwing: YTDLPError.rateLimited)
                    } else if combinedOutput.contains("HTTP Error 403")
                                || combinedOutput.contains("403 Forbidden")
                                || combinedOutput.contains("Sign in to confirm")
                                || combinedOutput.contains("confirm you're not a bot")
                                || combinedOutput.contains("bot verification")
                                || combinedOutput.contains("This video is not available") {
                        continuation.resume(throwing: YTDLPError.forbidden)
                    } else {
                        let errorMsg = errorOutput.isEmpty ? fullOutput : errorOutput
                        continuation.resume(throwing: YTDLPError.downloadFailed(errorMsg))
                    }
                }
            }

            do {
                try process.run()
            } catch {
                Task { @MainActor in
                    self.isRunning = false
                }
                continuation.resume(throwing: YTDLPError.executionFailed(error))
            }
        }
    }

    // MARK: - Simple Execution (capture full output)

    private func executeSimple(binaryPath: String, arguments: [String]) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let pipe = Pipe()
            let errorPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: binaryPath)
            process.arguments = arguments
            process.standardOutput = pipe
            process.standardError = errorPipe

            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
                    continuation.resume(throwing: YTDLPError.downloadFailed(errorOutput.isEmpty ? output : errorOutput))
                }
            } catch {
                continuation.resume(throwing: YTDLPError.executionFailed(error))
            }
        }
    }

    // MARK: - Progress Parsing

    /// Parses yt-dlp progress lines:
    /// [download]  45.2% of ~123.45MiB at 5.67MiB/s ETA 00:15
    /// [download]  45.2% of  123.45MiB at 5.67MiB/s ETA 00:15
    /// [download] 100% of  123.45MiB in 00:21
    private func parseProgressLine(_ line: String) -> DownloadProgress? {
        guard line.contains("[download]") && line.contains("%") else { return nil }

        var progress = DownloadProgress()
        progress.statusLine = line

        // Extract percentage
        if let percentRange = line.range(of: #"(\d+\.?\d*)%"#, options: .regularExpression) {
            let percentStr = String(line[percentRange]).replacingOccurrences(of: "%", with: "")
            progress.percentage = Double(percentStr) ?? 0
        }

        // Extract speed
        if let speedRange = line.range(of: #"at\s+([\d.]+\w+/s)"#, options: .regularExpression) {
            let speedStr = String(line[speedRange])
                .replacingOccurrences(of: "at ", with: "")
                .trimmingCharacters(in: .whitespaces)
            progress.speed = parseByteRate(speedStr)
        }

        // Extract ETA
        if let etaRange = line.range(of: #"ETA\s+(\d+:\d+:\d+|\d+:\d+)"#, options: .regularExpression) {
            let etaStr = String(line[etaRange]).replacingOccurrences(of: "ETA ", with: "")
            progress.eta = parseTimeString(etaStr)
        }

        // Extract total size
        if let sizeRange = line.range(of: #"of\s+~?([\d.]+\w+)"#, options: .regularExpression) {
            let sizeStr = String(line[sizeRange])
                .replacingOccurrences(of: "of ", with: "")
                .replacingOccurrences(of: "~", with: "")
                .trimmingCharacters(in: .whitespaces)
            progress.totalBytes = parseByteSize(sizeStr)
        }

        if let totalBytes = progress.totalBytes {
            progress.downloadedBytes = Int64(Double(totalBytes) * progress.percentage / 100.0)
        }

        // Detect post-processing
        if line.contains("[ExtractAudio]") || line.contains("[Merger]") ||
           line.contains("[EmbedThumbnail]") || line.contains("[Metadata]") {
            progress.statusLine = "Post-processing..."
        }

        return progress
    }

    private func parseByteRate(_ str: String) -> Double {
        let cleaned = str.replacingOccurrences(of: "/s", with: "")
        return Double(parseByteSize(cleaned))
    }

    private func parseByteSize(_ str: String) -> Int64 {
        let str = str.trimmingCharacters(in: .whitespaces)

        if str.hasSuffix("GiB") || str.hasSuffix("GB") {
            let num = str.replacingOccurrences(of: "GiB", with: "").replacingOccurrences(of: "GB", with: "")
            return Int64((Double(num) ?? 0) * 1024 * 1024 * 1024)
        }
        if str.hasSuffix("MiB") || str.hasSuffix("MB") {
            let num = str.replacingOccurrences(of: "MiB", with: "").replacingOccurrences(of: "MB", with: "")
            return Int64((Double(num) ?? 0) * 1024 * 1024)
        }
        if str.hasSuffix("KiB") || str.hasSuffix("KB") {
            let num = str.replacingOccurrences(of: "KiB", with: "").replacingOccurrences(of: "KB", with: "")
            return Int64((Double(num) ?? 0) * 1024)
        }
        if str.hasSuffix("B") {
            let num = str.replacingOccurrences(of: "B", with: "")
            return Int64(Double(num) ?? 0)
        }

        return Int64(Double(str) ?? 0)
    }

    private func parseTimeString(_ str: String) -> TimeInterval {
        let parts = str.split(separator: ":").map { Int($0) ?? 0 }
        if parts.count == 3 {
            return TimeInterval(parts[0] * 3600 + parts[1] * 60 + parts[2])
        } else if parts.count == 2 {
            return TimeInterval(parts[0] * 60 + parts[1])
        }
        return 0
    }
}

// MARK: - Result & Error Types

struct DownloadResult {
    var success: Bool
    var outputPath: String?
    var output: String
    var errorOutput: String?
}

enum YTDLPError: LocalizedError {
    case downloadFailed(String)
    case executionFailed(Error)
    case parseError(String)
    case rateLimited
    case forbidden
    case cancelled
    case binaryNotFound

    var errorDescription: String? {
        switch self {
        case .downloadFailed(let msg): return "Download failed: \(msg)"
        case .executionFailed(let err): return "Execution failed: \(err.localizedDescription)"
        case .parseError(let msg): return "Parse error: \(msg)"
        case .rateLimited: return "Rate limited (HTTP 429). Try enabling stealth mode."
        case .forbidden: return "Access forbidden (HTTP 403). Try using cookies or different identity."
        case .cancelled: return "Download was cancelled"
        case .binaryNotFound: return "yt-dlp binary not found"
        }
    }
}

// MARK: - Playlist Info

struct PlaylistInfo: Codable {
    var id: String?
    var title: String?
    var uploader: String?
    var description: String?
    var entries: [PlaylistEntry]?
    var playlistCount: Int?
    var webpageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, title, uploader, description, entries
        case playlistCount = "playlist_count"
        case webpageUrl = "webpage_url"
    }
}

struct PlaylistEntry: Identifiable, Codable {
    var id: String { entryId ?? UUID().uuidString }
    var entryId: String?
    var title: String?
    var url: String?
    var duration: TimeInterval?
    var thumbnailUrl: String?
    var uploader: String?

    enum CodingKeys: String, CodingKey {
        case entryId = "id"
        case title, url, duration, uploader
        case thumbnailUrl = "thumbnail"
    }

    var durationFormatted: String? {
        guard let dur = duration else { return nil }
        let minutes = Int(dur) / 60
        let seconds = Int(dur) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
