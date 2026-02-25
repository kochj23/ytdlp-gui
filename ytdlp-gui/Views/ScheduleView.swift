//
//  ScheduleView.swift
//  ytdlp-gui
//
//  Schedule downloads for later execution
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct ScheduleView: View {
    @StateObject private var scheduleManager = ScheduleManager.shared
    @EnvironmentObject var dataStore: DataStore
    @State private var newURL: String = ""
    @State private var scheduledDate: Date = Date().addingTimeInterval(3600)
    @State private var repeatRule: ScheduledDownload.RepeatRule = .once
    @State private var selectedPreset: DownloadPreset?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scheduled Downloads")
                            .modernHeader(size: .large)
                        Text("Schedule downloads for later or set up recurring downloads")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    Spacer()

                    if let next = scheduleManager.nextScheduledDate {
                        VStack(alignment: .trailing) {
                            Text("Next:")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(ModernColors.textTertiary)
                            Text(next, style: .relative)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(ModernColors.cyan)
                        }
                    }
                }

                // New scheduled download
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock.badge.plus")
                            .foregroundColor(ModernColors.purple)
                        Text("Schedule New Download")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)
                    }

                    TextField("Enter URL...", text: $newURL)
                        .formTextField()

                    HStack(spacing: 16) {
                        DatePicker("When:", selection: $scheduledDate, in: Date()...)
                            .labelsHidden()

                        Picker("Repeat", selection: $repeatRule) {
                            ForEach(ScheduledDownload.RepeatRule.allCases, id: \.self) { rule in
                                Text(rule.rawValue).tag(rule)
                            }
                        }
                        .frame(width: 130)

                        Spacer()

                        Button("Schedule") {
                            let options = selectedPreset?.options ?? YTDLPOptions()
                            scheduleManager.addSchedule(url: newURL, options: options, date: scheduledDate, repeatRule: repeatRule)
                            newURL = ""
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.purple, style: .filled))
                        .disabled(newURL.isEmpty)
                    }

                    // Preset selector
                    HStack(spacing: 8) {
                        Text("Preset:")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                        ForEach(dataStore.presets.prefix(4)) { preset in
                            Button(preset.name) {
                                selectedPreset = preset
                            }
                            .font(.system(size: 11, weight: selectedPreset?.id == preset.id ? .bold : .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(selectedPreset?.id == preset.id ? ModernColors.purple.opacity(0.2) : Color.white.opacity(0.05))
                            .foregroundColor(selectedPreset?.id == preset.id ? ModernColors.purple : ModernColors.textSecondary)
                            .cornerRadius(6)
                        }
                    }
                }
                .glassCard()

                // Scheduled items
                if scheduleManager.scheduledDownloads.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 40))
                            .foregroundColor(ModernColors.textTertiary)
                        Text("No scheduled downloads")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .glassCard()
                } else {
                    VStack(spacing: 0) {
                        ForEach(scheduleManager.scheduledDownloads) { schedule in
                            ScheduleRow(schedule: schedule, onToggle: {
                                scheduleManager.toggleSchedule(schedule.id)
                            }, onRemove: {
                                scheduleManager.removeSchedule(schedule.id)
                            })

                            Divider().background(Color.white.opacity(0.05))
                        }
                    }
                    .glassCard()
                }
            }
            .padding(32)
        }
    }
}

struct ScheduleRow: View {
    let schedule: ScheduledDownload
    let onToggle: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: schedule.isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(schedule.isEnabled ? ModernColors.purple : ModernColors.textTertiary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.url)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(ModernColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(schedule.scheduledDate, style: .date)
                    Text(schedule.scheduledDate, style: .time)
                    if schedule.repeatRule != .once {
                        Text("(\(schedule.repeatRule.rawValue))")
                            .foregroundColor(ModernColors.purple)
                    }
                }
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(ModernColors.textTertiary)
            }

            Spacer()

            statusBadge(schedule.status)

            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundColor(ModernColors.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func statusBadge(_ status: ScheduledDownload.ScheduleStatus) -> some View {
        Text(status.rawValue)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor(status).opacity(0.15))
            .foregroundColor(statusColor(status))
            .cornerRadius(6)
    }

    private func statusColor(_ status: ScheduledDownload.ScheduleStatus) -> Color {
        switch status {
        case .pending: return ModernColors.yellow
        case .running: return ModernColors.cyan
        case .completed: return ModernColors.accentGreen
        case .failed: return ModernColors.red
        }
    }
}
