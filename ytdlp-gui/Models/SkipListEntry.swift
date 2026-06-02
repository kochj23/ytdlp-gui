//
//  SkipListEntry.swift
//  ytdlp-gui
//
//  Persistent skip list entry — URLs that should never be re-attempted.
//  Created by Jordan Koch on 2026-06-02.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

struct SkipListEntry: Identifiable, Codable {
    let id: UUID
    var url: String
    var reason: SkipReason
    var addedAt: Date
    var source: String?

    init(url: String, reason: SkipReason, source: String? = nil) {
        self.id = UUID()
        self.url = url
        self.reason = reason
        self.addedAt = Date()
        self.source = source
    }
}

enum SkipReason: String, Codable, CaseIterable, Identifiable {
    case membersOnly = "Members Only"
    case geoRestricted = "Geo-Restricted"
    case ageRestricted = "Age-Restricted"
    case unavailable = "Unavailable"
    case filesystemError = "Filesystem Error"
    case hardBlock = "Hard Block"
    case manualSkip = "Manual Skip"

    var id: String { rawValue }

    var isSoftError: Bool {
        switch self {
        case .membersOnly, .geoRestricted, .ageRestricted, .unavailable, .filesystemError:
            return true
        case .hardBlock, .manualSkip:
            return false
        }
    }

    var icon: String {
        switch self {
        case .membersOnly: return "person.badge.key"
        case .geoRestricted: return "globe.badge.chevron.backward"
        case .ageRestricted: return "exclamationmark.shield"
        case .unavailable: return "video.slash"
        case .filesystemError: return "externaldrive.badge.xmark"
        case .hardBlock: return "hand.raised"
        case .manualSkip: return "forward.end"
        }
    }
}
