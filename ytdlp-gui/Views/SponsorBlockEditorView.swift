//
//  SponsorBlockEditorView.swift
//  ytdlp-gui
//
//  Visual SponsorBlock timeline editor
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct SponsorBlockEditorView: View {
    @StateObject private var service = SponsorBlockService.shared
    @State private var url: String = ""
    @State private var videoDuration: Double = 600

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SponsorBlock Editor")
                            .modernHeader(size: .large)
                        Text("Preview and select sponsor segments to skip or remove")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    Spacer()
                }

                // URL input
                HStack(spacing: 12) {
                    TextField("YouTube URL...", text: $url)
                        .formTextField()

                    Button("Fetch Segments") {
                        fetchSegments()
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.accentGreen, style: .filled))
                    .disabled(url.isEmpty || service.isFetching)
                }
                .glassCard()

                if service.isFetching {
                    ProgressView("Fetching SponsorBlock data...")
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .glassCard()
                }

                if !service.segments.isEmpty {
                    // Timeline visualization
                    timelineView

                    // Stats
                    HStack(spacing: 24) {
                        statCard(title: "Segments", value: "\(service.segments.count)", color: ModernColors.cyan)
                        statCard(title: "Selected", value: "\(service.segments.filter(\.isSelected).count)", color: ModernColors.accentGreen)
                        statCard(title: "Skip Time", value: formatDuration(service.totalSkipTime), color: ModernColors.orange)
                    }

                    // Controls
                    HStack(spacing: 8) {
                        Button("Select All") { service.selectAll() }
                            .buttonStyle(ModernButtonStyle(color: ModernColors.cyan, style: .outlined))
                        Button("Deselect All") { service.deselectAll() }
                            .buttonStyle(ModernButtonStyle(color: ModernColors.textSecondary, style: .outlined))
                        Spacer()

                        Text("yt-dlp args: \(service.buildSponsorBlockArgs().joined(separator: " "))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(ModernColors.textTertiary)
                    }
                    .glassCard()

                    // Segment list
                    VStack(spacing: 0) {
                        ForEach(service.segments) { segment in
                            SegmentRow(segment: segment) {
                                service.toggleSegment(segment.id)
                            }

                            if segment.id != service.segments.last?.id {
                                Divider().background(Color.white.opacity(0.05))
                            }
                        }
                    }
                    .glassCard()

                    // Category legend
                    legendView
                }
            }
            .padding(32)
        }
    }

    // MARK: - Timeline

    private var timelineView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(ModernColors.purple)
                Text("Timeline")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 40)

                    // Segment bars
                    ForEach(service.segments) { segment in
                        let startFraction = segment.startTime / max(videoDuration, 1)
                        let endFraction = segment.endTime / max(videoDuration, 1)
                        let width = max((endFraction - startFraction) * geometry.size.width, 2)
                        let offset = startFraction * geometry.size.width

                        RoundedRectangle(cornerRadius: 3)
                            .fill(segment.isSelected ? segment.category.color : segment.category.color.opacity(0.3))
                            .frame(width: width, height: 40)
                            .offset(x: offset)
                    }
                }
            }
            .frame(height: 40)

            // Time labels
            HStack {
                Text("0:00")
                Spacer()
                Text(formatDuration(videoDuration))
            }
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(ModernColors.textTertiary)
        }
        .glassCard()
    }

    // MARK: - Legend

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Categories")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(ModernColors.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(SponsorBlockSegment.SegmentCategory.allCases) { category in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(category.color)
                            .frame(width: 8, height: 8)
                        Text(category.displayName)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Helpers

    private func fetchSegments() {
        guard let videoID = service.extractYouTubeVideoID(from: url) else { return }

        // Also fetch video duration via metadata
        Task {
            await service.fetchSegments(videoID: videoID)

            // Try to get duration from metadata
            if let metadata = try? await MetadataService.shared.fetchMetadata(url: url),
               let duration = metadata.duration {
                videoDuration = duration
                service.videoDuration = duration
            }
        }
    }

    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(ModernColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

struct SegmentRow: View {
    let segment: SponsorBlockSegment
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: segment.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(segment.isSelected ? segment.category.color : ModernColors.textTertiary)
            }
            .buttonStyle(.plain)

            Circle()
                .fill(segment.category.color)
                .frame(width: 10, height: 10)

            Text(segment.category.displayName)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(ModernColors.textPrimary)
                .frame(width: 120, alignment: .leading)

            Text(segment.formattedTimeRange)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(ModernColors.textSecondary)

            Spacer()

            Text(String(format: "%.1fs", segment.duration))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(ModernColors.textTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
