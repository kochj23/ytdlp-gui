//
//  StealthView.swift
//  ytdlp-gui
//
//  Anti-detection configuration dashboard
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct StealthView: View {
    @EnvironmentObject var dataStore: DataStore
    @ObservedObject var stealthManager = StealthManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Anti-Detection")
                            .modernHeader(size: .large)
                        Text("Configure stealth settings to avoid rate limiting")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    Spacer()

                    // Master toggle
                    Toggle("Enabled", isOn: $dataStore.stealthProfile.isEnabled)
                        .toggleStyle(.switch)
                        .onChange(of: dataStore.stealthProfile.isEnabled) { _ in
                            dataStore.saveStealthProfile()
                        }
                }

                HStack(alignment: .top, spacing: 24) {
                    // Left column
                    VStack(spacing: 20) {
                        // User Agent Rotation
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "person.crop.rectangle")
                                    .foregroundColor(ModernColors.cyan)
                                Text("User Agent Rotation")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(ModernColors.textPrimary)
                                Spacer()
                                Toggle("", isOn: $dataStore.stealthProfile.rotateUserAgents)
                                    .toggleStyle(.switch)
                                    .onChange(of: dataStore.stealthProfile.rotateUserAgents) { _ in
                                        dataStore.saveStealthProfile()
                                    }
                            }

                            HStack {
                                Text("Pool: \(stealthManager.currentPoolSize) agents")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(ModernColors.textSecondary)
                                Text("Used: \(stealthManager.usedCount)")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(ModernColors.textTertiary)
                                Spacer()
                                Button("Reset Pool") {
                                    stealthManager.resetPool()
                                }
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(ModernColors.cyan)
                            }
                        }
                        .glassCard()

                        // Random Delays
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "clock.badge.questionmark")
                                    .foregroundColor(ModernColors.orange)
                                Text("Random Delays")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(ModernColors.textPrimary)
                                Spacer()
                                Toggle("", isOn: $dataStore.stealthProfile.randomDelayEnabled)
                                    .toggleStyle(.switch)
                                    .onChange(of: dataStore.stealthProfile.randomDelayEnabled) { _ in
                                        dataStore.saveStealthProfile()
                                    }
                            }

                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Min: \(String(format: "%.1f", dataStore.stealthProfile.minDelay))s")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(ModernColors.textSecondary)
                                    Slider(value: $dataStore.stealthProfile.minDelay, in: 0...10, step: 0.5)
                                        .onChange(of: dataStore.stealthProfile.minDelay) { _ in
                                            dataStore.saveStealthProfile()
                                        }
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Max: \(String(format: "%.1f", dataStore.stealthProfile.maxDelay))s")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(ModernColors.textSecondary)
                                    Slider(value: $dataStore.stealthProfile.maxDelay, in: 1...30, step: 0.5)
                                        .onChange(of: dataStore.stealthProfile.maxDelay) { _ in
                                            dataStore.saveStealthProfile()
                                        }
                                }
                            }
                        }
                        .glassCard()

                        // Cookie Import
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(ModernColors.purple)
                                Text("Cookie Source")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(ModernColors.textPrimary)
                            }

                            Picker("Browser", selection: $dataStore.stealthProfile.cookieSource) {
                                ForEach(CookieSource.allCases) { source in
                                    Text(source.rawValue).tag(source)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: dataStore.stealthProfile.cookieSource) { _ in
                                dataStore.saveStealthProfile()
                            }
                        }
                        .glassCard()
                    }

                    // Right column
                    VStack(spacing: 20) {
                        // YouTube 403 Evasion
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.shield")
                                    .foregroundColor(ModernColors.red)
                                Text("YouTube Anti-403")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(ModernColors.textPrimary)
                            }

                            Toggle("Rotate player clients (web/android/ios)", isOn: $dataStore.stealthProfile.usePlayerClientRotation)
                                .onChange(of: dataStore.stealthProfile.usePlayerClientRotation) { _ in
                                    dataStore.saveStealthProfile()
                                }

                            Toggle("Set YouTube referer header", isOn: $dataStore.stealthProfile.setReferer)
                                .onChange(of: dataStore.stealthProfile.setReferer) { _ in
                                    dataStore.saveStealthProfile()
                                }

                            Toggle("Send CONSENT cookie", isOn: $dataStore.stealthProfile.sendConsentCookie)
                                .onChange(of: dataStore.stealthProfile.sendConsentCookie) { _ in
                                    dataStore.saveStealthProfile()
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sleep between requests: \(String(format: "%.1f", dataStore.stealthProfile.sleepBetweenRequests))s")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(ModernColors.textSecondary)
                                Slider(value: $dataStore.stealthProfile.sleepBetweenRequests, in: 0...5, step: 0.5)
                                    .onChange(of: dataStore.stealthProfile.sleepBetweenRequests) { _ in
                                        dataStore.saveStealthProfile()
                                    }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("PO Token (optional)")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(ModernColors.textSecondary)
                                TextField("Paste PO token...", text: Binding(
                                    get: { dataStore.stealthProfile.poToken ?? "" },
                                    set: { dataStore.stealthProfile.poToken = $0.isEmpty ? nil : $0; dataStore.saveStealthProfile() }
                                ))
                                .formTextField()
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Visitor Data (optional)")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(ModernColors.textSecondary)
                                TextField("Paste visitor data...", text: Binding(
                                    get: { dataStore.stealthProfile.visitorData ?? "" },
                                    set: { dataStore.stealthProfile.visitorData = $0.isEmpty ? nil : $0; dataStore.saveStealthProfile() }
                                ))
                                .formTextField()
                            }

                            Text("Tip: Cookie import from your browser is the most effective 403 fix. Also keep yt-dlp updated.")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(ModernColors.yellow)
                        }
                        .glassCard()

                        // TLS Impersonation
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "shield.checkered")
                                    .foregroundColor(ModernColors.accentGreen)
                                Text("TLS Impersonation")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(ModernColors.textPrimary)
                            }

                            Picker("Target", selection: Binding(
                                get: { dataStore.stealthProfile.impersonateTarget ?? "" },
                                set: { dataStore.stealthProfile.impersonateTarget = $0.isEmpty ? nil : $0; dataStore.saveStealthProfile() }
                            )) {
                                Text("None").tag("")
                                ForEach(ImpersonateOption.allCases) { opt in
                                    Text(opt.displayName).tag(opt.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)

                            Text("Requires curl_cffi Python package")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(ModernColors.textTertiary)
                        }
                        .glassCard()

                        // Auto-Retry on 429
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "arrow.clockwise.circle")
                                    .foregroundColor(ModernColors.yellow)
                                Text("Auto-Retry on Rate Limit")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(ModernColors.textPrimary)
                                Spacer()
                                Toggle("", isOn: $dataStore.stealthProfile.retryOn429)
                                    .toggleStyle(.switch)
                                    .onChange(of: dataStore.stealthProfile.retryOn429) { _ in
                                        dataStore.saveStealthProfile()
                                    }
                            }

                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Max Retries")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundColor(ModernColors.textSecondary)
                                    Stepper("\(dataStore.stealthProfile.maxRetries)", value: $dataStore.stealthProfile.maxRetries, in: 1...20)
                                        .onChange(of: dataStore.stealthProfile.maxRetries) { _ in
                                            dataStore.saveStealthProfile()
                                        }
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Backoff Max: \(Int(dataStore.stealthProfile.backoffMax))s")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundColor(ModernColors.textSecondary)
                                    Slider(value: $dataStore.stealthProfile.backoffMax, in: 30...600, step: 30)
                                        .onChange(of: dataStore.stealthProfile.backoffMax) { _ in
                                            dataStore.saveStealthProfile()
                                        }
                                }
                            }
                        }
                        .glassCard()

                        // Proxy Rotation
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "network.badge.shield.half.filled")
                                    .foregroundColor(ModernColors.pink)
                                Text("Proxy Rotation")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(ModernColors.textPrimary)
                                Spacer()
                                Toggle("", isOn: $dataStore.stealthProfile.proxyEnabled)
                                    .toggleStyle(.switch)
                                    .onChange(of: dataStore.stealthProfile.proxyEnabled) { _ in
                                        dataStore.saveStealthProfile()
                                    }
                            }

                            Text("Add proxy URLs (one per line, format: socks5://host:port)")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(ModernColors.textTertiary)

                            TextEditor(text: Binding(
                                get: { dataStore.stealthProfile.proxyList.joined(separator: "\n") },
                                set: { dataStore.stealthProfile.proxyList = $0.split(separator: "\n").map(String.init); dataStore.saveStealthProfile() }
                            ))
                            .font(.system(size: 12, design: .monospaced))
                            .frame(height: 80)
                            .padding(8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        }
                        .glassCard()
                    }
                }
            }
            .padding(32)
        }
    }
}
