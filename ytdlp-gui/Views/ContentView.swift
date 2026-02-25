//
//  ContentView.swift
//  ytdlp-gui
//
//  Main content view with sidebar navigation (OneOnOne pattern)
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

// MARK: - Sidebar Navigation

enum SidebarSection: String, CaseIterable {
    case main = "Main"
    case downloads = "Downloads"
    case options = "Options"
    case tools = "Tools"
}

enum SidebarItem: String, CaseIterable, Identifiable {
    // Main
    case dashboard = "Dashboard"
    case newDownload = "New Download"

    // Downloads
    case queue = "Queue"
    case library = "Library"

    // Options
    case presets = "Presets"
    case formatSelector = "Format Selector"
    case outputTemplate = "Output Template"
    case allOptions = "All Options"

    // Tools
    case playlist = "Playlists"
    case stealth = "Anti-Detection"
    case binaries = "Binaries"
    case log = "Log Viewer"
    case settings = "Settings"

    var id: String { rawValue }

    var section: SidebarSection {
        switch self {
        case .dashboard, .newDownload: return .main
        case .queue, .library: return .downloads
        case .presets, .formatSelector, .outputTemplate, .allOptions: return .options
        case .playlist, .stealth, .binaries, .log, .settings: return .tools
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .newDownload: return "arrow.down.circle"
        case .queue: return "list.bullet"
        case .library: return "books.vertical"
        case .presets: return "star"
        case .formatSelector: return "film"
        case .outputTemplate: return "doc.text"
        case .allOptions: return "slider.horizontal.3"
        case .playlist: return "list.number"
        case .stealth: return "eye.slash"
        case .binaries: return "cpu"
        case .log: return "terminal"
        case .settings: return "gear"
        }
    }

    var color: Color {
        switch self {
        case .dashboard: return ModernColors.cyan
        case .newDownload: return ModernColors.accentGreen
        case .queue: return ModernColors.accentBlue
        case .library: return ModernColors.purple
        case .presets: return ModernColors.orange
        case .formatSelector: return ModernColors.pink
        case .outputTemplate: return ModernColors.yellow
        case .allOptions: return ModernColors.teal
        case .playlist: return ModernColors.blue
        case .stealth: return ModernColors.accentOrange
        case .binaries: return ModernColors.accentGreen
        case .log: return ModernColors.textSecondary
        case .settings: return ModernColors.cyan
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var downloadManager: DownloadManager
    @State private var selectedItem: SidebarItem = .dashboard

    var body: some View {
        ZStack {
            GlassmorphicBackground()

            HStack(spacing: 0) {
                // Sidebar
                sidebar
                    .frame(width: 260)

                // Divider
                Rectangle()
                    .fill(ModernColors.glassBorder)
                    .frame(width: 1)

                // Main content
                mainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App title
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(ModernColors.cyan)

                VStack(alignment: .leading, spacing: 2) {
                    Text("ytdlp-gui")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(ModernColors.textPrimary)
                    Text("Video Downloader")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)

            // Navigation items grouped by section
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(SidebarSection.allCases, id: \.self) { section in
                        let items = SidebarItem.allCases.filter { $0.section == section }

                        if !items.isEmpty {
                            Text(section.rawValue.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(ModernColors.textTertiary)
                                .padding(.horizontal, 20)
                                .padding(.top, section == .main ? 0 : 16)
                                .padding(.bottom, 4)

                            ForEach(items) { item in
                                sidebarButton(item)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
            }

            Spacer()

            // Bottom stats
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(downloadManager.activeCount > 0 ? ModernColors.accentGreen : ModernColors.textTertiary)
                        .frame(width: 8, height: 8)
                    Text(downloadManager.activeCount > 0 ? "\(downloadManager.activeCount) active" : "Idle")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)
                    Spacer()
                    if downloadManager.totalSpeed > 0 {
                        Text(ByteCountFormatter.string(fromByteCount: Int64(downloadManager.totalSpeed), countStyle: .binary) + "/s")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(ModernColors.cyan)
                    }
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.03))
        }
        .background(Color.white.opacity(0.02))
    }

    private func sidebarButton(_ item: SidebarItem) -> some View {
        Button {
            selectedItem = item
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 24)

                Text(item.rawValue)
                    .font(.system(size: 14, weight: selectedItem == item ? .semibold : .medium, design: .rounded))

                Spacer()

                // Badge counts
                if item == .queue && downloadManager.activeCount > 0 {
                    Text("\(downloadManager.queue.count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(item.color.opacity(0.8))
                        .cornerRadius(10)
                }
                if item == .library {
                    Text("\(dataStore.library.count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(item.color.opacity(0.5))
                        .cornerRadius(10)
                }
            }
            .sidebarItem(isSelected: selectedItem == item, color: item.color)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch selectedItem {
        case .dashboard:
            DashboardView()
        case .newDownload:
            NewDownloadView()
        case .queue:
            QueueView()
        case .library:
            LibraryView()
        case .presets:
            PresetsView()
        case .formatSelector:
            FormatSelectorView()
        case .outputTemplate:
            OutputTemplateBuilderView()
        case .allOptions:
            OptionsView()
        case .playlist:
            PlaylistView()
        case .stealth:
            StealthView()
        case .binaries:
            BinaryManagerView()
        case .log:
            LogView()
        case .settings:
            SettingsView()
        }
    }
}
