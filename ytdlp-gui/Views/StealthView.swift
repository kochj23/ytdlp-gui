//
//  StealthView.swift
//  ytdlp-gui
//
//  Anti-detection configuration dashboard
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

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
                                Spacer()
                                if dataStore.stealthProfile.cookieSource != .none {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(ModernColors.accentGreen)
                                        .font(.system(size: 14))
                                }
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

                            // Cookie file picker when .file is selected
                            if dataStore.stealthProfile.cookieSource == .file {
                                HStack {
                                    TextField("Cookie file path (Netscape format)...", text: Binding(
                                        get: { dataStore.stealthProfile.cookieFilePath ?? "" },
                                        set: { dataStore.stealthProfile.cookieFilePath = $0.isEmpty ? nil : $0; dataStore.saveStealthProfile() }
                                    ))
                                    .formTextField()

                                    Button("Browse") {
                                        let panel = NSOpenPanel()
                                        panel.canChooseFiles = true
                                        panel.canChooseDirectories = false
                                        panel.allowedContentTypes = [.text, .plainText]
                                        panel.message = "Select a Netscape-format cookies.txt file"
                                        if panel.runModal() == .OK, let url = panel.url {
                                            dataStore.stealthProfile.cookieFilePath = url.path
                                            dataStore.saveStealthProfile()
                                        }
                                    }
                                    .buttonStyle(ModernButtonStyle(color: ModernColors.purple, style: .outlined))
                                }
                            }

                            Text("Importing cookies from your browser is the #1 most effective fix for YouTube 403 errors.")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(ModernColors.accentGreen)
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
                                Spacer()
                                Button("Update yt-dlp") {
                                    Task { try? await BinaryManager.shared.updateYTDLP() }
                                }
                                .buttonStyle(ModernButtonStyle(color: ModernColors.accentGreen, style: .outlined))
                            }

                            // Quick fix checklist
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Fix Checklist (in order of effectiveness):")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(ModernColors.yellow)
                                fixChecklistItem("1. Update yt-dlp to latest version", done: false)
                                fixChecklistItem("2. Import cookies from browser", done: dataStore.stealthProfile.cookieSource != .none)
                                fixChecklistItem("3. Enable TLS impersonation (Chrome)", done: dataStore.stealthProfile.impersonateTarget != nil)
                                fixChecklistItem("4. Player client rotation", done: dataStore.stealthProfile.usePlayerClientRotation)
                                fixChecklistItem("5. Set YouTube referer", done: dataStore.stealthProfile.setReferer)
                                fixChecklistItem("6. Send CONSENT cookie", done: dataStore.stealthProfile.sendConsentCookie)
                            }
                            .padding(10)
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(8)

                            Toggle("Rotate player clients (web/android/ios/mweb)", isOn: $dataStore.stealthProfile.usePlayerClientRotation)
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
                                HStack {
                                    Text("PO Token")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(ModernColors.textSecondary)
                                    Spacer()
                                    if dataStore.stealthProfile.poToken != nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(ModernColors.accentGreen)
                                            .font(.system(size: 12))
                                    }
                                }
                                TextField("Paste PO token from browser DevTools...", text: Binding(
                                    get: { dataStore.stealthProfile.poToken ?? "" },
                                    set: { dataStore.stealthProfile.poToken = $0.isEmpty ? nil : $0; dataStore.saveStealthProfile() }
                                ))
                                .formTextField()
                                Text("When set, forces web client. Get from browser Network tab → innertube request → po_token.")
                                    .font(.system(size: 10, design: .rounded))
                                    .foregroundColor(ModernColors.textTertiary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Visitor Data")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(ModernColors.textSecondary)
                                    Spacer()
                                    if dataStore.stealthProfile.visitorData != nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(ModernColors.accentGreen)
                                            .font(.system(size: 12))
                                    }
                                }
                                TextField("Paste visitor data...", text: Binding(
                                    get: { dataStore.stealthProfile.visitorData ?? "" },
                                    set: { dataStore.stealthProfile.visitorData = $0.isEmpty ? nil : $0; dataStore.saveStealthProfile() }
                                ))
                                .formTextField()
                                Text("From same innertube request. Pairs with PO token for full session auth.")
                                    .font(.system(size: 10, design: .rounded))
                                    .foregroundColor(ModernColors.textTertiary)
                            }

                            Text("403 errors auto-retry with identity rotation (up to \(dataStore.stealthProfile.maxRetries) attempts).")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(ModernColors.cyan)
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

    // MARK: - Helpers

    private func fixChecklistItem(_ text: String, done: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundColor(done ? ModernColors.accentGreen : ModernColors.textTertiary)
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(done ? ModernColors.textSecondary : ModernColors.textTertiary)
        }
    }
}
