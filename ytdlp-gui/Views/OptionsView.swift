//
//  OptionsView.swift
//  ytdlp-gui
//
//  Complete yt-dlp options editor organized by category
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct OptionsView: View {
    @State private var selectedCategory: OptionCategory = .general
    @State private var options = YTDLPOptions()

    enum OptionCategory: String, CaseIterable, Identifiable {
        case general = "General"
        case network = "Network"
        case selection = "Selection"
        case download = "Download"
        case format = "Format"
        case subtitles = "Subtitles"
        case authentication = "Auth"
        case filesystem = "Filesystem"
        case thumbnails = "Thumbnails"
        case postProcessing = "Post-Processing"
        case sponsorblock = "SponsorBlock"
        case workarounds = "Workarounds"
        case extractor = "Extractor"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .network: return "network"
            case .selection: return "checklist"
            case .download: return "arrow.down"
            case .format: return "film"
            case .subtitles: return "captions.bubble"
            case .authentication: return "lock"
            case .filesystem: return "folder"
            case .thumbnails: return "photo"
            case .postProcessing: return "wand.and.stars"
            case .sponsorblock: return "scissors"
            case .workarounds: return "wrench"
            case .extractor: return "doc.text.magnifyingglass"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Category picker
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(OptionCategory.allCases) { cat in
                        Button {
                            selectedCategory = cat
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 14))
                                    .frame(width: 20)
                                Text(cat.rawValue)
                                    .font(.system(size: 13, weight: selectedCategory == cat ? .semibold : .medium, design: .rounded))
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedCategory == cat ? ModernColors.cyan.opacity(0.15) : Color.clear)
                            )
                            .foregroundColor(selectedCategory == cat ? ModernColors.cyan : ModernColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
            }
            .frame(width: 180)
            .background(Color.white.opacity(0.02))

            Rectangle()
                .fill(ModernColors.glassBorder)
                .frame(width: 1)

            // Options content
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Text(selectedCategory.rawValue)
                            .modernHeader(size: .medium)
                        Spacer()
                    }

                    optionsContent
                }
                .padding(32)
            }
        }
    }

    @ViewBuilder
    private var optionsContent: some View {
        switch selectedCategory {
        case .general:
            generalOptions
        case .network:
            networkOptions
        case .selection:
            selectionOptions
        case .download:
            downloadOptions
        case .format:
            formatOptions
        case .subtitles:
            subtitleOptions
        case .authentication:
            authOptions
        case .filesystem:
            filesystemOptions
        case .thumbnails:
            thumbnailOptions
        case .postProcessing:
            postProcessingOptions
        case .sponsorblock:
            sponsorblockOptions
        case .workarounds:
            workaroundOptions
        case .extractor:
            extractorOptions
        }
    }

    // MARK: - Option Sections

    private var generalOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            optionToggle("Ignore Errors", binding: $options.ignoreErrors, help: "Continue on download errors (-i)")
            optionToggle("Abort on Error", binding: $options.abortOnError, help: "Abort on first error")
            optionToggle("Flat Playlist", binding: $options.flatPlaylist, help: "Don't expand playlist entries")
            optionToggle("Live from Start", binding: $options.liveFromStart, help: "Download livestreams from the start")
            optionToggle("Mark Watched", binding: $options.markWatched, help: "Mark videos as watched on the platform")
            optionTextField("Use Extractors", binding: $options.useExtractors, help: "Extractor names/regex to use")
            optionTextField("Default Search", binding: $options.defaultSearch, help: "Prefix for unqualified URLs")
        }
        .glassCard()
    }

    private var networkOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            optionTextField("Proxy", binding: $options.proxy, help: "HTTP/HTTPS/SOCKS proxy URL")
            optionIntField("Socket Timeout", binding: $options.socketTimeout, help: "Connection timeout in seconds")
            optionTextField("Source Address", binding: $options.sourceAddress, help: "Client-side IP to bind to")
            optionTextField("Impersonate", binding: $options.impersonate, help: "Browser to impersonate (chrome, firefox, safari, edge)")
            optionToggle("Force IPv4", binding: $options.forceIPv4, help: "Force IPv4 connections")
            optionToggle("Force IPv6", binding: $options.forceIPv6, help: "Force IPv6 connections")
        }
        .glassCard()
    }

    private var selectionOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            optionTextField("Playlist Items", binding: $options.playlistItems, help: "Indices to download (e.g., 1:3,7,-5::2)")
            optionTextField("Min Filesize", binding: $options.minFilesize, help: "Skip files smaller than (e.g., 50k, 44.6M)")
            optionTextField("Max Filesize", binding: $options.maxFilesize, help: "Skip files larger than")
            optionTextField("Date", binding: $options.date, help: "Only videos uploaded on date (YYYYMMDD)")
            optionTextField("Date Before", binding: $options.dateBefore, help: "Only videos before date")
            optionTextField("Date After", binding: $options.dateAfter, help: "Only videos after date")
            optionIntField("Age Limit", binding: $options.ageLimit, help: "Content age restriction limit")
            optionTextField("Download Archive", binding: $options.downloadArchive, help: "Archive file to track downloaded videos")
            optionIntField("Max Downloads", binding: $options.maxDownloads, help: "Stop after N downloads")
            optionToggle("No Playlist", binding: $options.noPlaylist, help: "Download single video only")
            optionToggle("Yes Playlist", binding: $options.yesPlaylist, help: "Download the entire playlist")
            optionToggle("Break on Existing", binding: $options.breakOnExisting, help: "Stop when hitting archived video")
        }
        .glassCard()
    }

    private var downloadOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            optionIntField("Concurrent Fragments", binding: $options.concurrentFragments, help: "Concurrent fragment downloads (DASH/HLS)")
            optionTextField("Limit Rate", binding: $options.limitRate, help: "Bandwidth limit (e.g., 50K, 4.2M)")
            optionTextField("Throttled Rate", binding: $options.throttledRate, help: "Re-extract if speed drops below this")
            optionIntField("Retries", binding: $options.retries, help: "Retry count (default 10)")
            optionIntField("Fragment Retries", binding: $options.fragmentRetries, help: "Fragment retry count")
            optionTextField("Buffer Size", binding: $options.bufferSize, help: "Download buffer size")
            optionTextField("HTTP Chunk Size", binding: $options.httpChunkSize, help: "Chunk size for throttle bypass")
            optionToggle("Keep Fragments", binding: $options.keepFragments, help: "Keep fragment files after merge")
            optionToggle("Playlist Reverse", binding: $options.playlistReverse, help: "Download in reverse order")
            optionToggle("Playlist Random", binding: $options.playlistRandom, help: "Randomize playlist order")
            optionToggle("HLS Use MPEGTS", binding: $options.hlsUseMpegts, help: "Use mpegts for HLS")
        }
        .glassCard()
    }

    private var formatOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            optionTextField("Format", binding: $options.format, help: "Format selector (e.g., bv*+ba/b, best, bestaudio)")

            // Common format presets
            HStack(spacing: 8) {
                ForEach(["bv*+ba/b", "bestaudio", "best[height<=1080]", "best[height<=720]"], id: \.self) { fmt in
                    Button(fmt) {
                        options.format = fmt
                    }
                    .font(.system(size: 11, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(6)
                    .foregroundColor(ModernColors.cyan)
                }
            }

            optionTextField("Merge Output Format", binding: $options.mergeOutputFormat, help: "Container: avi, flv, mkv, mov, mp4, webm")
            optionToggle("Prefer Free Formats", binding: $options.preferFreeFormats, help: "Prefer webm/opus over mp4/m4a")
            optionToggle("Check Formats", binding: $options.checkFormats, help: "Verify formats are downloadable")
            optionToggle("Video Multistreams", binding: $options.videoMultistreams, help: "Allow multiple video streams")
            optionToggle("Audio Multistreams", binding: $options.audioMultistreams, help: "Allow multiple audio streams")
        }
        .glassCard()
    }

    private var subtitleOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            optionToggle("Write Subtitles", binding: $options.writeSubs, help: "Download subtitles")
            optionToggle("Write Auto Subtitles", binding: $options.writeAutoSubs, help: "Download auto-generated subtitles")
            optionTextField("Subtitle Format", binding: $options.subFormat, help: "srt, ass, vtt, lrc")
            optionTextField("Subtitle Languages", binding: $options.subLangs, help: "Comma-separated (e.g., en.*,ja)")
        }
        .glassCard()
    }

    private var authOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            optionTextField("Username", binding: $options.username, help: "Account username")
            optionToggle("Use .netrc", binding: $options.netrc, help: "Use .netrc file for credentials")
            optionTextField(".netrc Location", binding: $options.netrcLocation, help: "Custom .netrc path")
            optionTextField("AP MSO", binding: $options.apMso, help: "Adobe Pass TV provider")
            optionTextField("AP Username", binding: $options.apUsername, help: "TV provider login")
            optionTextField("Client Certificate", binding: $options.clientCertificate, help: "PEM certificate file")

            Text("Passwords are stored in macOS Keychain for security.")
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(ModernColors.textTertiary)
        }
        .glassCard()
    }

    private var filesystemOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            optionTextField2("Output Template", binding: $options.outputTemplate, help: "Filename template (e.g., %(title)s.%(ext)s)")
            optionTextField("Batch File", binding: $options.batchFile, help: "File with list of URLs")
            optionTextField("Cookies File", binding: $options.cookies, help: "Netscape cookie file path")
            optionTextField("Cookies from Browser", binding: $options.cookiesFromBrowser, help: "chrome, firefox, safari, edge, brave")
            optionToggle("Restrict Filenames", binding: $options.restrictFilenames, help: "ASCII-only filenames")
            optionToggle("No Overwrites", binding: $options.noOverwrites, help: "Never overwrite existing files")
            optionToggle("Force Overwrites", binding: $options.forceOverwrites, help: "Always overwrite")
            optionToggle("No Part Files", binding: $options.noPart, help: "Don't use .part files")
            optionToggle("Write Info JSON", binding: $options.writeInfoJson, help: "Save .info.json metadata")
            optionToggle("Write Description", binding: $options.writeDescription, help: "Save .description file")
            optionToggle("Write Comments", binding: $options.writeComments, help: "Fetch and save video comments")
        }
        .glassCard()
    }

    private var thumbnailOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            optionToggle("Write Thumbnail", binding: $options.writeThumbnail, help: "Save thumbnail image")
            optionToggle("Write All Thumbnails", binding: $options.writeAllThumbnails, help: "Save all thumbnail sizes")
            optionTextField("Convert Thumbnails", binding: $options.convertThumbnails, help: "jpg, png, webp")
        }
        .glassCard()
    }

    private var postProcessingOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            optionToggle("Extract Audio", binding: $options.extractAudio, help: "Convert to audio-only")
            optionTextField("Audio Format", binding: $options.audioFormat, help: "best, aac, alac, flac, m4a, mp3, opus, vorbis, wav")
            optionTextField("Audio Quality", binding: $options.audioQuality, help: "0-10 (0=best) or bitrate like 128K")
            optionTextField("Remux Video", binding: $options.remuxVideo, help: "Remux to: avi, flv, mkv, mov, mp4, webm")
            optionTextField("Recode Video", binding: $options.recodeVideo, help: "Re-encode to different format")
            optionToggle("Embed Subtitles", binding: $options.embedSubs, help: "Embed subs in video (mp4/mkv)")
            optionToggle("Embed Thumbnail", binding: $options.embedThumbnail, help: "Embed thumbnail as cover art")
            optionToggle("Embed Metadata", binding: $options.embedMetadata, help: "Embed all metadata + chapters")
            optionToggle("Embed Chapters", binding: $options.embedChapters, help: "Embed chapter markers")
            optionToggle("Keep Video", binding: $options.keepVideo, help: "Keep intermediate video")
            optionToggle("Split Chapters", binding: $options.splitChapters, help: "Split video by chapters")
            optionTextField("Convert Subtitles", binding: $options.convertSubs, help: "ass, lrc, srt, vtt")
            optionTextField("ffmpeg Location", binding: $options.ffmpegLocation, help: "Custom ffmpeg binary path")
        }
        .glassCard()
    }

    private var sponsorblockOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            optionTextField("Mark Categories", binding: $options.sponsorblockMark, help: "Mark as chapters: sponsor,intro,outro,selfpromo,all")
            optionTextField("Remove Categories", binding: $options.sponsorblockRemove, help: "Remove from video: sponsor,intro,outro,selfpromo,all")
            optionTextField("Chapter Title Template", binding: $options.sponsorblockChapterTitle, help: "Title for SponsorBlock chapters")
            optionToggle("Disable SponsorBlock", binding: $options.noSponsorblock, help: "Disable SponsorBlock entirely")
            optionTextField("API URL", binding: $options.sponsorblockApi, help: "Custom SponsorBlock API URL")
        }
        .glassCard()
    }

    private var workaroundOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            optionTextField("User Agent", binding: $options.userAgent, help: "Custom user agent string")
            optionTextField("Referer", binding: $options.referer, help: "Custom referer URL")
            optionTextField("Encoding", binding: $options.encoding, help: "Force character encoding")
            optionDoubleField("Sleep Requests", binding: $options.sleepRequests, help: "Delay between requests (seconds)")
            optionDoubleField("Sleep Interval", binding: $options.sleepInterval, help: "Delay before each download")
            optionDoubleField("Max Sleep Interval", binding: $options.maxSleepInterval, help: "Max random sleep")
            optionToggle("Legacy Server Connect", binding: $options.legacyServerConnect, help: "Allow insecure TLS renegotiation")
            optionToggle("No Check Certificates", binding: $options.noCheckCertificates, help: "Disable SSL verification")
            optionToggle("Prefer Insecure", binding: $options.preferInsecure, help: "Use HTTP instead of HTTPS")
        }
        .glassCard()
    }

    private var extractorOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            optionIntField("Extractor Retries", binding: $options.extractorRetries, help: "Retries for extractor errors")
            optionToggle("Allow Dynamic MPD", binding: $options.allowDynamicMpd, help: "Process dynamic DASH manifests")
            optionToggle("HLS Split Discontinuity", binding: $options.hlsSplitDiscontinuity, help: "Split HLS at discontinuities")
        }
        .glassCard()
    }

    // MARK: - Reusable Option Components

    private func optionToggle(_ label: String, binding: Binding<Bool>, help: String) -> some View {
        HStack {
            Toggle(isOn: binding) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(ModernColors.textPrimary)
                    Text(help)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(ModernColors.textTertiary)
                }
            }
            .toggleStyle(.switch)
        }
    }

    private func optionTextField(_ label: String, binding: Binding<String?>, help: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(ModernColors.textPrimary)
            TextField(help, text: Binding(
                get: { binding.wrappedValue ?? "" },
                set: { binding.wrappedValue = $0.isEmpty ? nil : $0 }
            ))
            .formTextField()
        }
    }

    private func optionTextField2(_ label: String, binding: Binding<String>, help: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(ModernColors.textPrimary)
            TextField(help, text: binding)
                .formTextField()
        }
    }

    private func optionIntField(_ label: String, binding: Binding<Int?>, help: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(ModernColors.textPrimary)
            TextField(help, text: Binding(
                get: { binding.wrappedValue.map(String.init) ?? "" },
                set: { binding.wrappedValue = Int($0) }
            ))
            .formTextField()
        }
    }

    private func optionDoubleField(_ label: String, binding: Binding<Double?>, help: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(ModernColors.textPrimary)
            TextField(help, text: Binding(
                get: { binding.wrappedValue.map { String(format: "%.1f", $0) } ?? "" },
                set: { binding.wrappedValue = Double($0) }
            ))
            .formTextField()
        }
    }
}
