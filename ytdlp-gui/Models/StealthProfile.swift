//
//  StealthProfile.swift
//  ytdlp-gui
//
//  Anti-detection configuration for YouTube and other sites
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

struct StealthProfile: Codable {
    var isEnabled: Bool = true
    var rotateUserAgents: Bool = true
    var randomDelayEnabled: Bool = true
    var minDelay: Double = 1.0
    var maxDelay: Double = 5.0

    var cookieSource: CookieSource = .none
    var cookieFilePath: String?

    var impersonateTarget: String?

    var proxyEnabled: Bool = false
    var proxyList: [String] = []

    var retryOn429: Bool = true
    var maxRetries: Int = 5
    var backoffBase: Double = 2.0
    var backoffMax: Double = 300.0

    // Enhanced anti-detection (YouTube 403 evasion)
    var usePlayerClientRotation: Bool = true
    var playerClients: [String] = ["web", "android", "ios", "mweb"]
    var setReferer: Bool = true
    var sendConsentCookie: Bool = true
    var sleepBetweenRequests: Double = 1.0
    var poToken: String?
    var visitorData: String?
}

enum CookieSource: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case chrome = "Chrome"
    case firefox = "Firefox"
    case safari = "Safari"
    case edge = "Edge"
    case brave = "Brave"
    case chromium = "Chromium"
    case opera = "Opera"
    case vivaldi = "Vivaldi"
    case file = "Cookie File"

    var id: String { rawValue }

    var ytdlpValue: String? {
        switch self {
        case .none: return nil
        case .file: return nil
        case .chrome: return "chrome"
        case .firefox: return "firefox"
        case .safari: return "safari"
        case .edge: return "edge"
        case .brave: return "brave"
        case .chromium: return "chromium"
        case .opera: return "opera"
        case .vivaldi: return "vivaldi"
        }
    }
}
