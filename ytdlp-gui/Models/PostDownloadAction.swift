//
//  PostDownloadAction.swift
//  ytdlp-gui
//
//  Post-download action configuration
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

struct PostDownloadAction: Identifiable, Codable {
    let id: UUID
    var name: String
    var actionType: ActionType
    var isEnabled: Bool
    var order: Int
    var configuration: ActionConfig

    init(name: String, actionType: ActionType, configuration: ActionConfig = ActionConfig()) {
        self.id = UUID()
        self.name = name
        self.actionType = actionType
        self.isEnabled = true
        self.order = 0
        self.configuration = configuration
    }

    enum ActionType: String, Codable, CaseIterable, Identifiable {
        case moveToFolder = "Move to Folder"
        case runScript = "Run Shell Script"
        case convertFormat = "Convert Format"
        case addToMusic = "Add to Apple Music"
        case addToPhotos = "Add to Photos"
        case openWith = "Open with App"
        case notify = "Send Notification"
        case tagFile = "Tag File"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .moveToFolder: return "folder.badge.plus"
            case .runScript: return "terminal"
            case .convertFormat: return "arrow.triangle.2.circlepath"
            case .addToMusic: return "music.note"
            case .addToPhotos: return "photo"
            case .openWith: return "arrow.up.forward.app"
            case .notify: return "bell"
            case .tagFile: return "tag"
            }
        }
    }

    struct ActionConfig: Codable {
        var destinationFolder: String?
        var scriptPath: String?
        var scriptArguments: String?
        var targetFormat: String?
        var applicationPath: String?
        var tags: [String]?

        init() {}
    }

    static let defaultActions: [PostDownloadAction] = [
        PostDownloadAction(name: "Move videos to Movies", actionType: .moveToFolder,
                          configuration: ActionConfig().withDestination(NSHomeDirectory() + "/Movies/ytdlp-gui")),
        PostDownloadAction(name: "Notify on complete", actionType: .notify),
    ]
}

extension PostDownloadAction.ActionConfig {
    func withDestination(_ path: String) -> PostDownloadAction.ActionConfig {
        var config = self
        config.destinationFolder = path
        return config
    }

    func withScript(_ path: String, arguments: String? = nil) -> PostDownloadAction.ActionConfig {
        var config = self
        config.scriptPath = path
        config.scriptArguments = arguments
        return config
    }
}
