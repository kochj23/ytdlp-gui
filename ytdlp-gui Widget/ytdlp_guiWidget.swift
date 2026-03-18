//
//  ytdlp_guiWidget.swift
//  ytdlp-gui Widget
//
//  macOS WidgetKit widget for ytdlp-gui.
//  Shows live download queue, active progress, speed, stealth mode, and daily stats.
//  Sizes: Small (queue pulse), Medium (active download + stats), Large (full dashboard)
//
//  Created by Jordan Koch on 2026-03-18.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct YTDLPWidgetEntry: TimelineEntry {
    let date: Date
    let data: YTDLPWidgetData
}

// MARK: - Timeline Provider

struct YTDLPWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> YTDLPWidgetEntry {
        YTDLPWidgetEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (YTDLPWidgetEntry) -> Void) {
        let data = context.isPreview ? .placeholder : SharedDataManager.shared.loadWidgetData()
        completion(YTDLPWidgetEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<YTDLPWidgetEntry>) -> Void) {
        let data = SharedDataManager.shared.loadWidgetData()
        let entry = YTDLPWidgetEntry(date: Date(), data: data)
        // Refresh every 30s when active, every 5m when idle
        let interval: TimeInterval = data.activeDownloads.isEmpty ? 300 : 30
        let nextRefresh = Date().addingTimeInterval(interval)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

// MARK: - Color Helpers

private func statusColor(_ status: String) -> Color {
    switch status.lowercased() {
    case "downloading": return Color(hex: "00D4FF")
    case "completed":   return Color(hex: "22C55E")
    case "failed":      return Color(hex: "EF4444")
    case "queued":      return Color(hex: "94A3B8")
    case "processing":  return Color(hex: "F59E0B")
    case "paused":      return Color(hex: "6366F1")
    case "retrying":    return Color(hex: "F97316")
    default:            return Color(hex: "94A3B8")
    }
}

// MARK: - Small Widget: Download Pulse

struct SmallWidgetView: View {
    let entry: YTDLPWidgetEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0A0F1E"), Color(hex: "111827")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                // Header
                HStack(spacing: 5) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "00D4FF"))
                    Text("ytdlp-gui")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    if entry.data.stealthModeActive {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "6366F1"))
                    }
                }

                if let active = entry.data.activeDownloads.first {
                    // Active download ring
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 5)
                            .frame(width: 50, height: 50)
                        Circle()
                            .trim(from: 0, to: active.progress)
                            .stroke(
                                AngularGradient(
                                    colors: [Color(hex: "00D4FF"), Color(hex: "0088FF")],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 5, lineCap: .round)
                            )
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(active.progress * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Text(active.title)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "94A3B8"))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                } else {
                    // Idle state
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "22C55E"))
                    Text("Queue Empty")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "94A3B8"))
                }

                // Stats row
                HStack(spacing: 10) {
                    statPill(icon: "clock.fill", value: "\(entry.data.completedToday)", color: Color(hex: "22C55E"))
                    if entry.data.queuedCount > 0 {
                        statPill(icon: "list.bullet", value: "\(entry.data.queuedCount)", color: Color(hex: "F59E0B"))
                    }
                    if entry.data.failedCount > 0 {
                        statPill(icon: "xmark.circle.fill", value: "\(entry.data.failedCount)", color: Color(hex: "EF4444"))
                    }
                }
            }
            .padding(12)
        }
        .containerBackground(for: .widget) { Color(hex: "0A0F1E") }
        .widgetURL(SharedDataManager.openAppURL)
    }

    @ViewBuilder
    func statPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Medium Widget: Active Download + Stats

struct MediumWidgetView: View {
    let entry: YTDLPWidgetEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0A0F1E"), Color(hex: "111827")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 10) {
                // Header
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "00D4FF"))
                    Text("ytdlp-gui")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    if entry.data.stealthModeActive {
                        HStack(spacing: 3) {
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: 9))
                            Text("Stealth")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "6366F1"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "6366F1").opacity(0.15))
                        .cornerRadius(6)
                    }
                    Text(SharedDataManager.shared.dataAgeString(for: entry.data.lastUpdated))
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "475569"))
                }

                if let active = entry.data.activeDownloads.first {
                    // Active download card
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(active.title)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Spacer()
                            Text(statusColor(active.status) == Color(hex: "00D4FF") ?
                                 "\(Int(active.progress * 100))%" : active.status)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(statusColor(active.status))
                        }

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 5)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "00D4FF"), Color(hex: "0088FF")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * active.progress, height: 5)
                            }
                        }
                        .frame(height: 5)

                        HStack {
                            if let uploader = active.uploader {
                                Text(uploader)
                                    .font(.system(size: 9))
                                    .foregroundColor(Color(hex: "64748B"))
                            }
                            Spacer()
                            if active.speedBytesPerSecond > 0 {
                                Text(formatSpeed(active.speedBytesPerSecond))
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color(hex: "00D4FF"))
                            }
                            if let eta = active.formattedETA {
                                Text("ETA \(eta)")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(Color(hex: "94A3B8"))
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "22C55E"))
                        Text("No active downloads")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(Color(hex: "64748B"))
                        Spacer()
                        Link(destination: SharedDataManager.addDownloadURL) {
                            Label("Add", systemImage: "plus.circle.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(hex: "00D4FF"))
                        }
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                }

                // Stats row
                HStack(spacing: 0) {
                    statCard(label: "Done Today", value: "\(entry.data.completedToday)", icon: "checkmark.circle.fill", color: Color(hex: "22C55E"))
                    Divider().background(Color.white.opacity(0.1)).frame(height: 28)
                    statCard(label: "Queued", value: "\(entry.data.queuedCount)", icon: "list.bullet.rectangle", color: Color(hex: "F59E0B"))
                    Divider().background(Color.white.opacity(0.1)).frame(height: 28)
                    statCard(label: "Downloaded", value: entry.data.formattedTotalToday, icon: "internaldrive.fill", color: Color(hex: "818CF8"))
                    if entry.data.failedCount > 0 {
                        Divider().background(Color.white.opacity(0.1)).frame(height: 28)
                        statCard(label: "Failed", value: "\(entry.data.failedCount)", icon: "xmark.circle.fill", color: Color(hex: "EF4444"))
                    }
                }
            }
            .padding(14)
        }
        .containerBackground(for: .widget) { Color(hex: "0A0F1E") }
        .widgetURL(SharedDataManager.openAppURL)
    }

    @ViewBuilder
    func statCard(label: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 8))
                    .foregroundColor(Color(hex: "64748B"))
            }
        }
        .frame(maxWidth: .infinity)
    }

    func formatSpeed(_ bps: Double) -> String {
        if bps >= 1_048_576 { return String(format: "%.1f MB/s", bps / 1_048_576) }
        if bps >= 1024 { return String(format: "%.0f KB/s", bps / 1024) }
        return String(format: "%.0f B/s", bps)
    }
}

// MARK: - Large Widget: Full Download Dashboard

struct LargeWidgetView: View {
    let entry: YTDLPWidgetEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0A0F1E"), Color(hex: "111827")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 10) {
                // Header
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "00D4FF"))
                    Text("ytdlp-gui")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Download Manager")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "64748B"))
                    Spacer()
                    if entry.data.stealthModeActive {
                        HStack(spacing: 3) {
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: 9))
                            Text("Stealth")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "6366F1"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "6366F1").opacity(0.15))
                        .cornerRadius(6)
                    }
                }

                Divider().background(Color.white.opacity(0.08))

                // Stats overview
                HStack(spacing: 0) {
                    bigStat(icon: "checkmark.circle.fill", value: "\(entry.data.completedToday)", label: "Done Today", color: Color(hex: "22C55E"))
                    bigStat(icon: "list.bullet.rectangle", value: "\(entry.data.queuedCount)", label: "Queued", color: Color(hex: "F59E0B"))
                    bigStat(icon: "internaldrive.fill", value: entry.data.formattedTotalToday, label: "Downloaded", color: Color(hex: "818CF8"))
                    bigStat(icon: "bolt.fill", value: entry.data.formattedSpeed, label: "Speed", color: Color(hex: "00D4FF"))
                }

                Divider().background(Color.white.opacity(0.08))

                // Active downloads list
                if entry.data.activeDownloads.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "tray.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "334155"))
                        Text("Queue is empty")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(Color(hex: "475569"))
                        Link(destination: SharedDataManager.addDownloadURL) {
                            Label("Add Download", systemImage: "plus.circle.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "00D4FF"))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 5) {
                        ForEach(entry.data.activeDownloads.prefix(4)) { item in
                            downloadRow(item: item)
                        }
                        if entry.data.activeDownloads.count > 4 {
                            Text("+ \(entry.data.activeDownloads.count - 4) more")
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: "475569"))
                        }
                    }
                }

                Spacer(minLength: 0)

                // Footer
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 8))
                        .foregroundColor(Color(hex: "334155"))
                    Text("Updated \(SharedDataManager.shared.dataAgeString(for: entry.data.lastUpdated))")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "334155"))
                    Spacer()
                    if entry.data.failedCount > 0 {
                        Label("\(entry.data.failedCount) failed", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color(hex: "EF4444"))
                    }
                }
            }
            .padding(14)
        }
        .containerBackground(for: .widget) { Color(hex: "0A0F1E") }
        .widgetURL(SharedDataManager.openAppURL)
    }

    @ViewBuilder
    func bigStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(Color(hex: "64748B"))
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    func downloadRow(item: WidgetDownloadItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(statusColor(item.status))
                    .frame(width: 6, height: 6)
                Text(item.title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
                Text("\(Int(item.progress * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(statusColor(item.status))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.07)).frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(statusColor(item.status).opacity(0.85))
                        .frame(width: geo.size.width * item.progress, height: 3)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int & 0xFF0000) >> 16) / 255
        let g = Double((int & 0x00FF00) >> 8)  / 255
        let b = Double(int & 0x0000FF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Widget Configuration

struct YTDLPWidget: Widget {
    let kind = "YTDLPWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: YTDLPWidgetProvider()) { entry in
            YTDLPWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ytdlp-gui")
        .description("Monitor your download queue — progress, speed, and daily stats.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct YTDLPWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: YTDLPWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        case .systemLarge:  LargeWidgetView(entry: entry)
        default:            MediumWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct YTDLPWidgetBundle: WidgetBundle {
    var body: some Widget {
        YTDLPWidget()
    }
}
