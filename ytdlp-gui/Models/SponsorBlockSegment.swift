//
//  SponsorBlockSegment.swift
//  ytdlp-gui
//
//  SponsorBlock segment data for visual timeline editor
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import SwiftUI

struct SponsorBlockSegment: Identifiable, Codable {
    let id: UUID
    var category: SegmentCategory
    var startTime: Double
    var endTime: Double
    var isSelected: Bool

    init(category: SegmentCategory, startTime: Double, endTime: Double) {
        self.id = UUID()
        self.category = category
        self.startTime = startTime
        self.endTime = endTime
        self.isSelected = true
    }

    var duration: Double { endTime - startTime }

    var formattedTimeRange: String {
        "\(formatTime(startTime)) - \(formatTime(endTime))"
    }

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    enum SegmentCategory: String, Codable, CaseIterable, Identifiable {
        case sponsor = "sponsor"
        case selfpromo = "selfpromo"
        case interaction = "interaction"
        case intro = "intro"
        case outro = "outro"
        case preview = "preview"
        case musicOfftopic = "music_offtopic"
        case filler = "filler"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .sponsor: return "Sponsor"
            case .selfpromo: return "Self-Promotion"
            case .interaction: return "Interaction Reminder"
            case .intro: return "Intro"
            case .outro: return "Outro"
            case .preview: return "Preview"
            case .musicOfftopic: return "Non-Music"
            case .filler: return "Filler"
            }
        }

        var color: Color {
            switch self {
            case .sponsor: return Color(red: 0.0, green: 0.85, blue: 0.0)
            case .selfpromo: return Color(red: 1.0, green: 1.0, blue: 0.0)
            case .interaction: return Color(red: 0.8, green: 0.2, blue: 0.8)
            case .intro: return Color(red: 0.0, green: 1.0, blue: 1.0)
            case .outro: return Color(red: 0.0, green: 0.6, blue: 1.0)
            case .preview: return Color(red: 0.5, green: 0.3, blue: 0.0)
            case .musicOfftopic: return Color(red: 1.0, green: 0.6, blue: 0.0)
            case .filler: return Color(red: 0.6, green: 0.2, blue: 0.2)
            }
        }
    }
}

// API response model for SponsorBlock
struct SponsorBlockAPIResponse: Codable {
    let videoID: String
    let segments: [SponsorBlockAPISegment]
}

struct SponsorBlockAPISegment: Codable {
    let segment: [Double]
    let category: String
    let UUID: String
}
