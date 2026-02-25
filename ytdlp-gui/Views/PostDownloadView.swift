//
//  PostDownloadView.swift
//  ytdlp-gui
//
//  Configure post-download actions (move, script, convert, etc.)
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct PostDownloadView: View {
    @StateObject private var actionManager = PostDownloadManager.shared

    @State private var showAddAction = false
    @State private var newActionType: PostDownloadAction.ActionType = .moveToFolder
    @State private var newActionName: String = ""
    @State private var newDestFolder: String = ""
    @State private var newScriptPath: String = ""
    @State private var newTargetFormat: String = "mp4"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Post-Download Actions")
                            .modernHeader(size: .large)
                        Text("Automatic actions after each download completes")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    Spacer()

                    Button("Add Action") {
                        showAddAction.toggle()
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.accentGreen, style: .filled))
                }

                // Add new action form
                if showAddAction {
                    addActionCard
                }

                // Actions list
                if actionManager.actions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bolt.circle")
                            .font(.system(size: 40))
                            .foregroundColor(ModernColors.textTertiary)
                        Text("No post-download actions")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .glassCard()
                } else {
                    VStack(spacing: 8) {
                        ForEach(actionManager.actions) { action in
                            ActionRow(action: action, onToggle: {
                                actionManager.toggleAction(action.id)
                            }, onRemove: {
                                actionManager.removeAction(action.id)
                            })
                        }
                    }
                }

                // Last result
                if let result = actionManager.lastActionResult {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(ModernColors.teal)
                        Text(result)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    .glassCard()
                }
            }
            .padding(32)
        }
    }

    private var addActionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "plus.circle")
                    .foregroundColor(ModernColors.orange)
                Text("New Action")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)
            }

            TextField("Action name", text: $newActionName)
                .formTextField()

            Picker("Type", selection: $newActionType) {
                ForEach(PostDownloadAction.ActionType.allCases) { type in
                    Label(type.rawValue, systemImage: type.icon).tag(type)
                }
            }

            // Type-specific config
            switch newActionType {
            case .moveToFolder:
                HStack {
                    TextField("Destination folder", text: $newDestFolder)
                        .formTextField()
                    Button("Browse") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        if panel.runModal() == .OK, let url = panel.url {
                            newDestFolder = url.path
                        }
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.teal, style: .outlined))
                }
            case .runScript:
                HStack {
                    TextField("Script path", text: $newScriptPath)
                        .formTextField()
                    Button("Browse") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = true
                        panel.canChooseDirectories = false
                        if panel.runModal() == .OK, let url = panel.url {
                            newScriptPath = url.path
                        }
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.teal, style: .outlined))
                }
            case .convertFormat:
                Picker("Target format", selection: $newTargetFormat) {
                    Text("MP4").tag("mp4")
                    Text("MKV").tag("mkv")
                    Text("MP3").tag("mp3")
                    Text("FLAC").tag("flac")
                    Text("WAV").tag("wav")
                    Text("M4A").tag("m4a")
                }
            default:
                EmptyView()
            }

            HStack {
                Button("Add") {
                    var config = PostDownloadAction.ActionConfig()
                    config.destinationFolder = newDestFolder.isEmpty ? nil : newDestFolder
                    config.scriptPath = newScriptPath.isEmpty ? nil : newScriptPath
                    config.targetFormat = newTargetFormat
                    let action = PostDownloadAction(name: newActionName.isEmpty ? newActionType.rawValue : newActionName, actionType: newActionType, configuration: config)
                    actionManager.addAction(action)
                    showAddAction = false
                    newActionName = ""
                    newDestFolder = ""
                    newScriptPath = ""
                }
                .buttonStyle(ModernButtonStyle(color: ModernColors.accentGreen, style: .filled))

                Button("Cancel") {
                    showAddAction = false
                }
                .buttonStyle(ModernButtonStyle(color: ModernColors.textSecondary, style: .outlined))
            }
        }
        .glassCard()
    }
}

struct ActionRow: View {
    let action: PostDownloadAction
    let onToggle: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: action.isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(action.isEnabled ? ModernColors.accentGreen : ModernColors.textTertiary)
            }
            .buttonStyle(.plain)

            Image(systemName: action.actionType.icon)
                .foregroundColor(ModernColors.orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(action.name)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)
                Text(action.actionType.rawValue)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(ModernColors.textTertiary)
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundColor(ModernColors.red)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }
}
