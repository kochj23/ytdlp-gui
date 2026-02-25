//
//  SubscriptionView.swift
//  ytdlp-gui
//
//  Channel/playlist subscription management for auto-downloads
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct SubscriptionView: View {
    @StateObject private var subManager = SubscriptionManager.shared
    @State private var newName: String = ""
    @State private var newURL: String = ""
    @State private var newInterval: ChannelSubscription.CheckInterval = .sixHours

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Subscriptions")
                            .modernHeader(size: .large)
                        Text("Auto-download new videos from channels and playlists")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    Spacer()

                    if subManager.isChecking {
                        ProgressView()
                            .scaleEffect(0.7)
                    }

                    Button("Check Now") {
                        subManager.forceCheckAll()
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.cyan, style: .outlined))
                }

                // Add subscription
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(ModernColors.accentGreen)
                        Text("Add Subscription")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)
                    }

                    HStack(spacing: 12) {
                        TextField("Name (e.g. Tech Channel)", text: $newName)
                            .formTextField()
                            .frame(maxWidth: 200)

                        TextField("Channel or Playlist URL", text: $newURL)
                            .formTextField()

                        Picker("", selection: $newInterval) {
                            ForEach(ChannelSubscription.CheckInterval.allCases) { interval in
                                Text(interval.rawValue).tag(interval)
                            }
                        }
                        .frame(width: 100)

                        Button("Subscribe") {
                            subManager.addSubscription(name: newName, url: newURL, interval: newInterval)
                            newName = ""
                            newURL = ""
                        }
                        .buttonStyle(ModernButtonStyle(color: ModernColors.accentGreen, style: .filled))
                        .disabled(newName.isEmpty || newURL.isEmpty)
                    }
                }
                .glassCard()

                // Subscriptions list
                if subManager.subscriptions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 40))
                            .foregroundColor(ModernColors.textTertiary)
                        Text("No subscriptions yet")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                        Text("Subscribe to channels to auto-download new videos")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .glassCard()
                } else {
                    VStack(spacing: 12) {
                        ForEach(subManager.subscriptions) { sub in
                            SubscriptionCard(subscription: sub, onToggle: {
                                subManager.toggleSubscription(sub.id)
                            }, onCheck: {
                                Task { await subManager.checkSubscription(sub.id) }
                            }, onRemove: {
                                subManager.removeSubscription(sub.id)
                            })
                        }
                    }
                }
            }
            .padding(32)
        }
    }
}

struct SubscriptionCard: View {
    let subscription: ChannelSubscription
    let onToggle: () -> Void
    let onCheck: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: subscription.isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(subscription.isEnabled ? ModernColors.accentGreen : ModernColors.textTertiary)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(subscription.isEnabled ? ModernColors.textPrimary : ModernColors.textTertiary)

                Text(subscription.url)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(ModernColors.textTertiary)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label("Every \(subscription.checkInterval.rawValue)", systemImage: "clock")
                    Label("\(subscription.downloadedVideoIds.count) downloaded", systemImage: "arrow.down.circle")
                    if let lastCheck = subscription.lastCheckedAt {
                        Text(lastCheck, style: .relative)
                    }
                }
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(ModernColors.textTertiary)
            }

            Spacer()

            Button(action: onCheck) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(ModernColors.cyan)
            }
            .buttonStyle(.plain)

            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundColor(ModernColors.red)
            }
            .buttonStyle(.plain)
        }
        .glassCard()
    }
}
