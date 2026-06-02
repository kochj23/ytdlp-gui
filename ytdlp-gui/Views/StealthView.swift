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
    @ObservedObject var sessionManager = SessionManager.shared
    @ObservedObject var cookieRefresh = CookieRefreshService.shared
    @ObservedObject var skipListManager = SkipListManager.shared
    @State private var showingSkipList = false

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

                            if BinaryManager.shared.impersonateAvailable {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(ModernColors.accentGreen)
                                        .font(.system(size: 11))
                                    Text("curl_cffi available — impersonation active")
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundColor(ModernColors.accentGreen)
                                }
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(ModernColors.orange)
                                        .font(.system(size: 11))
                                    Text("Requires curl_cffi: pip install curl_cffi (skipped if missing)")
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundColor(ModernColors.orange)
                                }
                            }
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

                // ═══════════════════════════════════════════════════════════════
                // NOVA SESSION MANAGEMENT
                // ═══════════════════════════════════════════════════════════════

                Divider()
                    .padding(.vertical, 8)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nova Session Intelligence")
                            .modernHeader(size: .medium)
                        Text("Battle-tested download orchestration from 677+ channel automation")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    Spacer()
                    // Session state badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(sessionStateColor)
                            .frame(width: 8, height: 8)
                        Text(sessionManager.sessionState.rawValue)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(sessionStateColor.opacity(0.1))
                    .cornerRadius(12)
                }

                HStack(alignment: .top, spacing: 24) {
                    // Left column: Session Control + Cookie Refresh
                    VStack(spacing: 20) {
                        // Session Control
                        sessionControlCard

                        // Cookie Auto-Refresh
                        cookieRefreshCard
                    }

                    // Right column: Download Pacing + Skip List
                    VStack(spacing: 20) {
                        // Download Pacing (Realistic Delays + Batching)
                        downloadPacingCard

                        // Skip List
                        skipListCard
                    }
                }
            }
            .padding(32)
        }
        .sheet(isPresented: $showingSkipList) {
            SkipListView()
        }
    }

    // MARK: - Session State Color

    private var sessionStateColor: Color {
        switch sessionManager.sessionState {
        case .active: return ModernColors.accentGreen
        case .paused: return ModernColors.red
        case .waitingBatch: return ModernColors.orange
        case .waitingZeroBatch: return ModernColors.yellow
        }
    }

    // MARK: - Session Control Card

    private var sessionControlCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(ModernColors.purple)
                Text("Session Control")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)
                Spacer()
                Toggle("", isOn: $dataStore.sessionConfig.blockDetectionEnabled)
                    .toggleStyle(.switch)
                    .onChange(of: dataStore.sessionConfig.blockDetectionEnabled) { _ in
                        dataStore.saveSessionConfig()
                    }
            }

            // Session stats
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hard Blocks")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)
                    Text("\(sessionManager.consecutiveHardBlocks)")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(sessionManager.consecutiveHardBlocks > 0 ? ModernColors.red : ModernColors.textSecondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rate Limits")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)
                    Text("\(sessionManager.consecutiveRateLimits)")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(sessionManager.consecutiveRateLimits > 0 ? ModernColors.orange : ModernColors.textSecondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Batch")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)
                    Text("\(sessionManager.downloadsInCurrentBatch)/\(sessionManager.currentBatchSize)")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(ModernColors.textSecondary)
                }
                Spacer()
            }

            // Max consecutive before halt
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Halt after consecutive blocks:")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)
                    Stepper("\(dataStore.sessionConfig.maxConsecutiveHardBlocks)", value: $dataStore.sessionConfig.maxConsecutiveHardBlocks, in: 1...10)
                        .onChange(of: dataStore.sessionConfig.maxConsecutiveHardBlocks) { _ in
                            dataStore.saveSessionConfig()
                        }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pause duration (hours):")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)
                    Stepper("\(Int(dataStore.sessionConfig.hardBlockPauseDurationHours))h", value: $dataStore.sessionConfig.hardBlockPauseDurationHours, in: 1...48)
                        .onChange(of: dataStore.sessionConfig.hardBlockPauseDurationHours) { _ in
                            dataStore.saveSessionConfig()
                        }
                }
            }

            // Resume button when paused
            if sessionManager.sessionState == .paused {
                HStack {
                    if let until = sessionManager.sessionPausedUntil {
                        Text("Paused until \(until, style: .relative)")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(ModernColors.red)
                    }
                    Spacer()
                    Button("Resume Session") {
                        sessionManager.resumeSession()
                        DownloadManager.shared.processQueue()
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.accentGreen, style: .filled))
                }
            }
        }
        .glassCard()
    }

    // MARK: - Cookie Refresh Card

    private var cookieRefreshCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(ModernColors.teal)
                Text("Cookie Auto-Refresh")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)
                Spacer()
                Toggle("", isOn: $dataStore.sessionConfig.cookieAutoRefreshEnabled)
                    .toggleStyle(.switch)
                    .onChange(of: dataStore.sessionConfig.cookieAutoRefreshEnabled) { newValue in
                        dataStore.saveSessionConfig()
                        if newValue {
                            CookieRefreshService.shared.startPeriodicCheck()
                        } else {
                            CookieRefreshService.shared.stopPeriodicCheck()
                        }
                    }
            }

            // Cookie age display
            HStack {
                if let age = cookieRefresh.cookieAgeFormatted {
                    Text("Cookie file: \(age)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(cookieRefresh.cookiesAreStale() ? ModernColors.orange : ModernColors.accentGreen)
                } else {
                    Text("No cookie file found")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(ModernColors.textTertiary)
                }
                Spacer()
                if cookieRefresh.isRefreshing {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            // TTL picker
            HStack {
                Text("Refresh when older than:")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)
                Spacer()
                Picker("", selection: $dataStore.sessionConfig.cookieTTLSeconds) {
                    Text("1h").tag(TimeInterval(3600))
                    Text("3h").tag(TimeInterval(10800))
                    Text("6h").tag(TimeInterval(21600))
                    Text("12h").tag(TimeInterval(43200))
                    Text("24h").tag(TimeInterval(86400))
                }
                .frame(width: 180)
                .onChange(of: dataStore.sessionConfig.cookieTTLSeconds) { _ in
                    dataStore.saveSessionConfig()
                }
            }

            // Browser source for refresh
            HStack {
                Text("Refresh from:")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)
                Spacer()
                Picker("", selection: $dataStore.sessionConfig.cookieRefreshBrowser) {
                    ForEach(CookieSource.allCases.filter { $0 != .none && $0 != .file }) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .frame(width: 140)
                .onChange(of: dataStore.sessionConfig.cookieRefreshBrowser) { _ in
                    dataStore.saveSessionConfig()
                }
            }

            // Status + manual refresh
            HStack {
                if let status = cookieRefresh.lastRefreshStatus {
                    Text(status)
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)
                        .lineLimit(1)
                }
                Spacer()
                Button("Refresh Now") {
                    Task { _ = await CookieRefreshService.shared.refreshCookies() }
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(ModernColors.teal)
                .disabled(cookieRefresh.isRefreshing)
            }
        }
        .glassCard()
    }

    // MARK: - Download Pacing Card

    private var downloadPacingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "metronome")
                    .foregroundColor(ModernColors.cyan)
                Text("Download Pacing")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)
                Spacer()
                Toggle("", isOn: $dataStore.sessionConfig.realisticDelaysEnabled)
                    .toggleStyle(.switch)
                    .onChange(of: dataStore.sessionConfig.realisticDelaysEnabled) { _ in
                        dataStore.saveSessionConfig()
                    }
            }

            Text("Nova-style organic timing: longer randomized delays that mimic human browsing")
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(ModernColors.textTertiary)

            // Inter-download delay
            VStack(alignment: .leading, spacing: 4) {
                Text("Between downloads: \(Int(dataStore.sessionConfig.interDownloadMinDelay))–\(Int(dataStore.sessionConfig.interDownloadMaxDelay))s")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(ModernColors.textSecondary)
                HStack(spacing: 8) {
                    Slider(value: $dataStore.sessionConfig.interDownloadMinDelay, in: 1...30, step: 1)
                        .onChange(of: dataStore.sessionConfig.interDownloadMinDelay) { _ in dataStore.saveSessionConfig() }
                    Slider(value: $dataStore.sessionConfig.interDownloadMaxDelay, in: 10...120, step: 5)
                        .onChange(of: dataStore.sessionConfig.interDownloadMaxDelay) { _ in dataStore.saveSessionConfig() }
                }
            }

            // Inter-batch delay
            VStack(alignment: .leading, spacing: 4) {
                Text("Between batches: \(Int(dataStore.sessionConfig.interBatchMinDelay))–\(Int(dataStore.sessionConfig.interBatchMaxDelay))s")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(ModernColors.textSecondary)
                HStack(spacing: 8) {
                    Slider(value: $dataStore.sessionConfig.interBatchMinDelay, in: 10...120, step: 5)
                        .onChange(of: dataStore.sessionConfig.interBatchMinDelay) { _ in dataStore.saveSessionConfig() }
                    Slider(value: $dataStore.sessionConfig.interBatchMaxDelay, in: 30...300, step: 10)
                        .onChange(of: dataStore.sessionConfig.interBatchMaxDelay) { _ in dataStore.saveSessionConfig() }
                }
            }

            Divider()

            // Batch Sizing
            HStack {
                Image(systemName: "square.stack.3d.up")
                    .foregroundColor(ModernColors.orange)
                    .font(.system(size: 13))
                Text("Batch Sizing")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)
                Spacer()
                Toggle("", isOn: $dataStore.sessionConfig.batchingEnabled)
                    .toggleStyle(.switch)
                    .onChange(of: dataStore.sessionConfig.batchingEnabled) { _ in
                        dataStore.saveSessionConfig()
                    }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Min batch")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)
                    Stepper("\(dataStore.sessionConfig.minBatchSize)", value: $dataStore.sessionConfig.minBatchSize, in: 0...10)
                        .onChange(of: dataStore.sessionConfig.minBatchSize) { _ in dataStore.saveSessionConfig() }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Max batch")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)
                    Stepper("\(dataStore.sessionConfig.maxBatchSize)", value: $dataStore.sessionConfig.maxBatchSize, in: 1...20)
                        .onChange(of: dataStore.sessionConfig.maxBatchSize) { _ in dataStore.saveSessionConfig() }
                }
            }

            if dataStore.sessionConfig.minBatchSize == 0 {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                        .foregroundColor(ModernColors.yellow)
                    Text("Min=0 enables zero-batches: deliberate idle periods that mimic real browsing")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(ModernColors.yellow)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Skip List Card

    private var skipListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(ModernColors.pink)
                Text("Skip List")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)
                Spacer()
                Toggle("", isOn: $dataStore.sessionConfig.skipListEnabled)
                    .toggleStyle(.switch)
                    .onChange(of: dataStore.sessionConfig.skipListEnabled) { _ in
                        dataStore.saveSessionConfig()
                    }
            }

            Text("URLs permanently skipped due to members-only, geo-restriction, or repeated failures")
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(ModernColors.textTertiary)

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 12))
                        .foregroundColor(ModernColors.orange)
                    Text("\(skipListManager.count) URLs skipped")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(ModernColors.textSecondary)
                }
                Spacer()
                Button("Manage Skip List") {
                    showingSkipList = true
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(ModernColors.pink)
            }

            // Reason breakdown (compact)
            if !skipListManager.entries.isEmpty {
                let reasons = Dictionary(grouping: skipListManager.entries, by: \.reason)
                HStack(spacing: 8) {
                    ForEach(reasons.sorted(by: { $0.value.count > $1.value.count }).prefix(4), id: \.key) { reason, entries in
                        HStack(spacing: 2) {
                            Image(systemName: reason.icon)
                                .font(.system(size: 9))
                            Text("\(entries.count)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(ModernColors.textTertiary)
                    }
                    Spacer()
                }
            }
        }
        .glassCard()
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
