//
//  SpeedLimitView.swift
//  ytdlp-gui
//
//  Download speed limiting configuration
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct SpeedLimitView: View {
    @StateObject private var limiter = SpeedLimiter.shared
    @EnvironmentObject var downloadManager: DownloadManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Speed Limiter")
                            .modernHeader(size: .large)
                        Text("Control download bandwidth usage")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    Spacer()

                    Toggle("Enabled", isOn: $limiter.isEnabled)
                        .toggleStyle(.switch)
                        .onChange(of: limiter.isEnabled) { _ in limiter.save() }
                }

                // Current speed
                HStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(SpeedLimiter.formatSpeed(limiter.globalLimitKBps))
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(limiter.isEnabled ? ModernColors.cyan : ModernColors.textTertiary)
                        Text("Global Limit")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .glassCard()

                    VStack(spacing: 8) {
                        Text(SpeedLimiter.formatSpeed(limiter.perDownloadLimitKBps))
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(limiter.isEnabled ? ModernColors.orange : ModernColors.textTertiary)
                        Text("Per-Download Limit")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .glassCard()

                    VStack(spacing: 8) {
                        Text(ByteCountFormatter.string(fromByteCount: Int64(downloadManager.totalSpeed), countStyle: .binary) + "/s")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(ModernColors.accentGreen)
                        Text("Current Speed")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .glassCard()
                }

                // Global limit
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "speedometer")
                            .foregroundColor(ModernColors.cyan)
                        Text("Global Speed Limit")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)
                    }

                    Text("Shared across all active downloads")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                        ForEach(SpeedLimiter.presets, id: \.1) { preset in
                            Button(preset.0) {
                                limiter.globalLimitKBps = preset.1
                                limiter.save()
                            }
                            .font(.system(size: 12, weight: limiter.globalLimitKBps == preset.1 ? .bold : .medium, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(limiter.globalLimitKBps == preset.1 ? ModernColors.cyan.opacity(0.2) : Color.white.opacity(0.05))
                            .foregroundColor(limiter.globalLimitKBps == preset.1 ? ModernColors.cyan : ModernColors.textSecondary)
                            .cornerRadius(8)
                        }
                    }

                    HStack {
                        Text("Custom (KB/s):")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                        TextField("0", value: $limiter.globalLimitKBps, format: .number)
                            .formTextField()
                            .frame(width: 100)
                            .onChange(of: limiter.globalLimitKBps) { _ in limiter.save() }
                    }
                }
                .glassCard()

                // Per-download limit
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                            .foregroundColor(ModernColors.orange)
                        Text("Per-Download Limit")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)
                    }

                    Text("Applied individually to each download (overrides global if set)")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                        ForEach(SpeedLimiter.presets, id: \.1) { preset in
                            Button(preset.0) {
                                limiter.perDownloadLimitKBps = preset.1
                                limiter.save()
                            }
                            .font(.system(size: 12, weight: limiter.perDownloadLimitKBps == preset.1 ? .bold : .medium, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(limiter.perDownloadLimitKBps == preset.1 ? ModernColors.orange.opacity(0.2) : Color.white.opacity(0.05))
                            .foregroundColor(limiter.perDownloadLimitKBps == preset.1 ? ModernColors.orange : ModernColors.textSecondary)
                            .cornerRadius(8)
                        }
                    }
                }
                .glassCard()
            }
            .padding(32)
        }
    }
}
