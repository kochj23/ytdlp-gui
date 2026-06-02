//
//  AudioExtractionConfig.swift
//  ytdlp-gui
//
//  Smart audio extraction: detect music content and auto-extract to MP3/FLAC with ID3 tags.
//  Created by Jordan Koch on 2026-06-02.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

struct AudioExtractionConfig: Codable {
    var enabled: Bool = false
    var outputDirectory: String = NSHomeDirectory() + "/Music/ytdlp-gui"
    var format: AudioFormat = .mp3
    var quality: AudioQuality = .high
    var embedThumbnail: Bool = true
    var embedMetadata: Bool = true
    var parseArtistTitle: Bool = true

    // Detection rules
    var autoDetectMusic: Bool = true
    var musicKeywords: [String] = AudioExtractionConfig.defaultMusicKeywords
    var musicChannels: [String] = []
    var minDurationSeconds: Int = 60
    var maxDurationSeconds: Int = 7200

    enum AudioFormat: String, Codable, CaseIterable, Identifiable {
        case mp3 = "MP3"
        case flac = "FLAC"
        case opus = "Opus"
        case wav = "WAV"
        case m4a = "M4A"

        var id: String { rawValue }

        var ytdlpCodec: String {
            switch self {
            case .mp3: return "mp3"
            case .flac: return "flac"
            case .opus: return "opus"
            case .wav: return "wav"
            case .m4a: return "m4a"
            }
        }

        var fileExtension: String { ytdlpCodec }
    }

    enum AudioQuality: String, Codable, CaseIterable, Identifiable {
        case best = "Best (0)"
        case high = "High (256k)"
        case medium = "Medium (192k)"
        case low = "Low (128k)"

        var id: String { rawValue }

        var ytdlpValue: String {
            switch self {
            case .best: return "0"
            case .high: return "256K"
            case .medium: return "192K"
            case .low: return "128K"
            }
        }
    }

    static let defaultMusicKeywords: [String] = [
        "remix", "mix", "dj set", "full album", "full song", "bootleg",
        "breakcore", "dnb", "drum & bass", "drum and bass", "jungle",
        "rave", "reggae", "hip hop", "soul", "disco", "funk", "techno",
        "house", "garage", "dubstep", "trance", "ambient", "lo-fi",
        "synthwave", "phonk", "hardstyle", "hardcore", "acid",
        "official audio", "official video", "lyrics", "visualizer",
        "music video", "live performance", "boiler room", "kexp",
        "npr tiny desk", "vinyl set", "all vinyl", "feat.", "ft.", "prod.",
        "instrumental", "acoustic"
    ]

    func isMusicContent(title: String, channel: String?, duration: TimeInterval?) -> Bool {
        guard autoDetectMusic else { return false }

        // Check channel match
        if !musicChannels.isEmpty {
            if let ch = channel, musicChannels.contains(where: { ch.localizedCaseInsensitiveContains($0) }) {
                return true
            }
        }

        // Check keyword match in title
        let titleLower = title.lowercased()
        let hasKeyword = musicKeywords.contains { titleLower.contains($0.lowercased()) }

        // Check Artist - Title pattern (strong signal)
        let hasArtistTitle = title.contains(" - ") && !title.contains("Ep.") && !title.contains("Episode")

        // Duration check
        var durationOk = true
        if let dur = duration {
            durationOk = dur >= Double(minDurationSeconds) && dur <= Double(maxDurationSeconds)
        }

        return (hasKeyword || hasArtistTitle) && durationOk
    }

    func parseArtistAndTitle(from filename: String) -> (artist: String?, title: String?) {
        guard parseArtistTitle else { return (nil, filename) }

        var clean = filename
        // Remove common prefixes like [Channel], (info)
        clean = clean.replacingOccurrences(of: #"^\[.*?\]\s*"#, with: "", options: .regularExpression)
        clean = clean.replacingOccurrences(of: #"^\(.*?\)\s*"#, with: "", options: .regularExpression)

        // Try "Artist - Title" pattern
        if clean.contains(" - ") {
            let parts = clean.split(separator: " - ", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                let artist = parts[0].trimmingCharacters(in: .whitespaces)
                var title = parts[1].trimmingCharacters(in: .whitespaces)
                // Clean trailing metadata
                title = title.replacingOccurrences(of: #"\s*\(Official.*?\)\s*$"#, with: "", options: .regularExpression)
                title = title.replacingOccurrences(of: #"\s*\[.*?\]\s*$"#, with: "", options: .regularExpression)
                return (artist, title)
            }
        }

        return (nil, clean)
    }

    func ytdlpAudioArguments() -> [String] {
        var args: [String] = []
        args += ["-x", "--audio-format", format.ytdlpCodec]
        args += ["--audio-quality", quality.ytdlpValue]
        if embedThumbnail {
            args += ["--embed-thumbnail"]
        }
        if embedMetadata {
            args += ["--embed-metadata"]
        }
        return args
    }
}
