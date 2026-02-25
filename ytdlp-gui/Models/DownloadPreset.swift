//
//  DownloadPreset.swift
//  ytdlp-gui
//
//  Saved download option configurations for quick access
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

struct DownloadPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var description: String
    var options: YTDLPOptions
    var isBuiltIn: Bool

    init(id: UUID = UUID(), name: String, icon: String, colorHex: String, description: String, options: YTDLPOptions, isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.description = description
        self.options = options
        self.isBuiltIn = isBuiltIn
    }

    static var builtInPresets: [DownloadPreset] {
        [
            bestVideo,
            audioMP3,
            audioFLAC,
            quality1080p,
            quality720p,
            stealthMode,
        ]
    }

    static var bestVideo: DownloadPreset {
        var opts = YTDLPOptions()
        opts.format = "bv*+ba/b"
        return DownloadPreset(
            name: "Best Video",
            icon: "film",
            colorHex: "#4DE0F5",
            description: "Best available video + audio quality",
            options: opts,
            isBuiltIn: true
        )
    }

    static var audioMP3: DownloadPreset {
        var opts = YTDLPOptions()
        opts.extractAudio = true
        opts.audioFormat = "mp3"
        opts.audioQuality = "0"
        return DownloadPreset(
            name: "Audio MP3",
            icon: "music.note",
            colorHex: "#9966F2",
            description: "Extract audio as MP3 (best quality)",
            options: opts,
            isBuiltIn: true
        )
    }

    static var audioFLAC: DownloadPreset {
        var opts = YTDLPOptions()
        opts.extractAudio = true
        opts.audioFormat = "flac"
        return DownloadPreset(
            name: "Audio FLAC",
            icon: "waveform",
            colorHex: "#FF9933",
            description: "Extract audio as lossless FLAC",
            options: opts,
            isBuiltIn: true
        )
    }

    static var quality1080p: DownloadPreset {
        var opts = YTDLPOptions()
        opts.format = "bv*[height<=1080]+ba/b[height<=1080]"
        return DownloadPreset(
            name: "1080p Max",
            icon: "sparkles.tv",
            colorHex: "#4DE094",
            description: "Best video up to 1080p resolution",
            options: opts,
            isBuiltIn: true
        )
    }

    static var quality720p: DownloadPreset {
        var opts = YTDLPOptions()
        opts.format = "bv*[height<=720]+ba/b[height<=720]"
        return DownloadPreset(
            name: "720p Small",
            icon: "arrow.down.to.line",
            colorHex: "#FFD700",
            description: "720p for smaller file size",
            options: opts,
            isBuiltIn: true
        )
    }

    static var stealthMode: DownloadPreset {
        var opts = YTDLPOptions()
        opts.format = "bv*+ba/b"
        opts.sleepInterval = 2
        opts.maxSleepInterval = 6
        opts.sleepRequests = 1
        opts.retries = 10
        return DownloadPreset(
            name: "Stealth Mode",
            icon: "eye.slash",
            colorHex: "#FF5999",
            description: "Maximum anti-detection with delays and rotation",
            options: opts,
            isBuiltIn: true
        )
    }
}
