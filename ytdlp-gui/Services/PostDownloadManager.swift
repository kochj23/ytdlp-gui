//
//  PostDownloadManager.swift
//  ytdlp-gui
//
//  Executes post-download actions (move, script, convert, etc.)
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import AppKit
import os

@MainActor
class PostDownloadManager: ObservableObject {
    static let shared = PostDownloadManager()

    @Published var actions: [PostDownloadAction] = []
    @Published var lastActionResult: String?

    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "PostDownloadManager")

    init() {
        loadActions()
    }

    // MARK: - Execute Actions

    func executeActions(for filePath: String, metadata: DownloadItem) {
        let enabledActions = actions.filter(\.isEnabled).sorted { $0.order < $1.order }

        for action in enabledActions {
            executeAction(action, filePath: filePath, metadata: metadata)
        }
    }

    private func executeAction(_ action: PostDownloadAction, filePath: String, metadata: DownloadItem) {
        switch action.actionType {
        case .moveToFolder:
            moveFile(filePath: filePath, config: action.configuration)
        case .runScript:
            runScript(filePath: filePath, config: action.configuration, metadata: metadata)
        case .convertFormat:
            convertFormat(filePath: filePath, config: action.configuration)
        case .addToMusic:
            addToMusic(filePath: filePath)
        case .addToPhotos:
            addToPhotos(filePath: filePath)
        case .openWith:
            openWith(filePath: filePath, config: action.configuration)
        case .notify:
            // Already handled by DownloadManager
            break
        case .tagFile:
            tagFile(filePath: filePath, config: action.configuration)
        }
    }

    // MARK: - Action Implementations

    private func moveFile(filePath: String, config: PostDownloadAction.ActionConfig) {
        guard let dest = config.destinationFolder else { return }
        let fm = FileManager.default
        try? fm.createDirectory(atPath: dest, withIntermediateDirectories: true)

        let fileName = (filePath as NSString).lastPathComponent
        let destPath = (dest as NSString).appendingPathComponent(fileName)

        do {
            if fm.fileExists(atPath: destPath) {
                try fm.removeItem(atPath: destPath)
            }
            try fm.moveItem(atPath: filePath, toPath: destPath)
            logger.info("Moved file to: \(destPath)")
            lastActionResult = "Moved to \(dest)"
        } catch {
            logger.error("Move failed: \(error.localizedDescription)")
            lastActionResult = "Move failed: \(error.localizedDescription)"
        }
    }

    private func runScript(filePath: String, config: PostDownloadAction.ActionConfig, metadata: DownloadItem) {
        guard let scriptPath = config.scriptPath else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")

        var args = [scriptPath, filePath]
        if let extraArgs = config.scriptArguments {
            args.append(contentsOf: extraArgs.components(separatedBy: " "))
        }
        process.arguments = ["-c", args.joined(separator: " ")]

        // Environment with metadata
        var env = ProcessInfo.processInfo.environment
        env["YTDLP_FILE"] = filePath
        env["YTDLP_TITLE"] = metadata.title ?? ""
        env["YTDLP_URL"] = metadata.url
        env["YTDLP_UPLOADER"] = metadata.uploader ?? ""
        process.environment = env

        do {
            try process.run()
            process.waitUntilExit()
            logger.info("Script executed: \(scriptPath) (exit: \(process.terminationStatus))")
            lastActionResult = "Script completed (exit: \(process.terminationStatus))"
        } catch {
            logger.error("Script failed: \(error.localizedDescription)")
            lastActionResult = "Script failed: \(error.localizedDescription)"
        }
    }

    private func convertFormat(filePath: String, config: PostDownloadAction.ActionConfig) {
        guard let targetFormat = config.targetFormat else { return }
        let ffmpegPath = BinaryManager.shared.ffmpegPath
        guard FileManager.default.isExecutableFile(atPath: ffmpegPath) else {
            logger.error("ffmpeg not found for format conversion")
            return
        }

        let outputPath = (filePath as NSString).deletingPathExtension + "." + targetFormat
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = ["-i", filePath, "-y", outputPath]

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                logger.info("Converted to \(targetFormat): \(outputPath)")
                lastActionResult = "Converted to \(targetFormat)"
            }
        } catch {
            logger.error("Convert failed: \(error.localizedDescription)")
        }
    }

    private func addToMusic(filePath: String) {
        NSWorkspace.shared.open(
            [URL(fileURLWithPath: filePath)],
            withApplicationAt: URL(fileURLWithPath: "/System/Applications/Music.app"),
            configuration: NSWorkspace.OpenConfiguration()
        )
        logger.info("Added to Apple Music: \(filePath)")
    }

    private func addToPhotos(filePath: String) {
        NSWorkspace.shared.open(
            [URL(fileURLWithPath: filePath)],
            withApplicationAt: URL(fileURLWithPath: "/System/Applications/Photos.app"),
            configuration: NSWorkspace.OpenConfiguration()
        )
        logger.info("Added to Photos: \(filePath)")
    }

    private func openWith(filePath: String, config: PostDownloadAction.ActionConfig) {
        if let appPath = config.applicationPath {
            NSWorkspace.shared.open(
                [URL(fileURLWithPath: filePath)],
                withApplicationAt: URL(fileURLWithPath: appPath),
                configuration: NSWorkspace.OpenConfiguration()
            )
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: filePath))
        }
    }

    private func tagFile(filePath: String, config: PostDownloadAction.ActionConfig) {
        guard let tags = config.tags, !tags.isEmpty else { return }
        let url = URL(fileURLWithPath: filePath) as NSURL
        try? url.setResourceValues([.tagNamesKey: tags])
        logger.info("Tagged file with: \(tags.joined(separator: ", "))")
    }

    // MARK: - Action Management

    func addAction(_ action: PostDownloadAction) {
        var newAction = action
        newAction.order = actions.count
        actions.append(newAction)
        saveActions()
    }

    func removeAction(_ id: UUID) {
        actions.removeAll { $0.id == id }
        saveActions()
    }

    func toggleAction(_ id: UUID) {
        if let index = actions.firstIndex(where: { $0.id == id }) {
            actions[index].isEnabled.toggle()
            saveActions()
        }
    }

    // MARK: - Persistence

    private var actionsFile: URL {
        DataStore.shared.appSupportDirectory.appendingPathComponent("post_actions.json")
    }

    private func loadActions() {
        guard FileManager.default.fileExists(atPath: actionsFile.path) else {
            actions = PostDownloadAction.defaultActions
            return
        }
        do {
            let data = try Data(contentsOf: actionsFile)
            actions = try JSONDecoder().decode([PostDownloadAction].self, from: data)
        } catch {
            logger.error("Failed to load actions: \(error.localizedDescription)")
            actions = PostDownloadAction.defaultActions
        }
    }

    private func saveActions() {
        do {
            let data = try JSONEncoder().encode(actions)
            try data.write(to: actionsFile, options: .atomic)
        } catch {
            logger.error("Failed to save actions: \(error.localizedDescription)")
        }
    }
}
