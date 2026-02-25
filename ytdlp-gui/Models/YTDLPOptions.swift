//
//  YTDLPOptions.swift
//  ytdlp-gui
//
//  Complete model for all yt-dlp command-line options (~160 flags)
//  Each property maps to a yt-dlp flag and is used to build the argument list.
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

struct YTDLPOptions: Codable, Equatable {

    // MARK: - General Options
    var ignoreErrors: Bool = false
    var abortOnError: Bool = false
    var useExtractors: String?
    var defaultSearch: String?
    var flatPlaylist: Bool = false
    var liveFromStart: Bool = false
    var waitForVideo: String?
    var markWatched: Bool = false
    var compatOptions: String?

    // MARK: - Network Options
    var proxy: String?
    var socketTimeout: Int?
    var sourceAddress: String?
    var impersonate: String?
    var forceIPv4: Bool = false
    var forceIPv6: Bool = false
    var enableFileUrls: Bool = false

    // MARK: - Geo-restriction
    var geoVerificationProxy: String?
    var xff: String?

    // MARK: - Video Selection
    var playlistItems: String?
    var minFilesize: String?
    var maxFilesize: String?
    var date: String?
    var dateBefore: String?
    var dateAfter: String?
    var matchFilters: [String] = []
    var breakMatchFilters: [String] = []
    var noPlaylist: Bool = false
    var yesPlaylist: Bool = false
    var ageLimit: Int?
    var downloadArchive: String?
    var maxDownloads: Int?
    var breakOnExisting: Bool = false
    var breakPerInput: Bool = false
    var skipPlaylistAfterErrors: Int?

    // MARK: - Download Options
    var concurrentFragments: Int?
    var limitRate: String?
    var throttledRate: String?
    var retries: Int?
    var fileAccessRetries: Int?
    var fragmentRetries: Int?
    var retrySleep: String?
    var skipUnavailableFragments: Bool = true
    var keepFragments: Bool = false
    var bufferSize: String?
    var noResizeBuffer: Bool = false
    var httpChunkSize: String?
    var playlistReverse: Bool = false
    var playlistRandom: Bool = false
    var lazyPlaylist: Bool = false
    var hlsUseMpegts: Bool = false
    var downloadSections: String?
    var downloader: String?
    var downloaderArgs: String?

    // MARK: - Filesystem Options
    var batchFile: String?
    var paths: String?
    var outputTemplate: String = "%(title)s.%(ext)s"
    var outputNaPlaceholder: String?
    var restrictFilenames: Bool = false
    var windowsFilenames: Bool = false
    var trimFilenames: Int?
    var noOverwrites: Bool = false
    var forceOverwrites: Bool = false
    var continueDownload: Bool = true
    var noPart: Bool = false
    var noMtime: Bool = false
    var writeDescription: Bool = false
    var writeInfoJson: Bool = false
    var writePlaylistMetafiles: Bool = false
    var cleanInfoJson: Bool = true
    var writeComments: Bool = false
    var cookies: String?
    var cookiesFromBrowser: String?
    var cacheDir: String?
    var noCacheDir: Bool = false

    // MARK: - Video Format Options
    var format: String?
    var formatSort: [String] = []
    var formatSortForce: Bool = false
    var videoMultistreams: Bool = false
    var audioMultistreams: Bool = false
    var preferFreeFormats: Bool = false
    var checkFormats: Bool = false
    var checkAllFormats: Bool = false
    var mergeOutputFormat: String?

    // MARK: - Subtitle Options
    var writeSubs: Bool = false
    var writeAutoSubs: Bool = false
    var subFormat: String?
    var subLangs: String?

    // MARK: - Authentication Options
    var username: String?
    // password stored in Keychain, not here
    var netrc: Bool = false
    var netrcLocation: String?
    var apMso: String?
    var apUsername: String?
    // ap-password stored in Keychain
    var clientCertificate: String?
    var clientCertificateKey: String?

    // MARK: - Thumbnail Options
    var writeThumbnail: Bool = false
    var writeAllThumbnails: Bool = false

    // MARK: - Internet Shortcut Options
    var writeLink: Bool = false
    var writeUrlLink: Bool = false
    var writeWeblocLink: Bool = false
    var writeDesktopLink: Bool = false

    // MARK: - Verbosity / Simulation
    var quiet: Bool = false
    var noWarnings: Bool = false
    var simulate: Bool = false
    var skipDownload: Bool = false
    var dumpJson: Bool = false
    var dumpSingleJson: Bool = false
    var forceWriteArchive: Bool = false
    var verbose: Bool = false

    // MARK: - Workarounds
    var encoding: String?
    var legacyServerConnect: Bool = false
    var noCheckCertificates: Bool = false
    var preferInsecure: Bool = false
    var userAgent: String?
    var referer: String?
    var addHeaders: [String] = []
    var sleepRequests: Double?
    var sleepInterval: Double?
    var maxSleepInterval: Double?
    var sleepSubtitles: Double?

    // MARK: - Post-Processing
    var extractAudio: Bool = false
    var audioFormat: String?
    var audioQuality: String?
    var remuxVideo: String?
    var recodeVideo: String?
    var postprocessorArgs: [String] = []
    var keepVideo: Bool = false
    var postOverwrites: Bool = false
    var embedSubs: Bool = false
    var embedThumbnail: Bool = false
    var embedMetadata: Bool = false
    var embedChapters: Bool = false
    var embedInfoJson: Bool = false
    var parseMetadata: [String] = []
    var replaceInMetadata: [String] = []
    var xattrs: Bool = false
    var concatPlaylist: String?
    var fixup: String?
    var ffmpegLocation: String?
    var execCmd: [String] = []
    var convertSubs: String?
    var convertThumbnails: String?
    var splitChapters: Bool = false
    var removeChapters: [String] = []
    var forceKeyframesAtCuts: Bool = false
    var usePostprocessor: [String] = []

    // MARK: - SponsorBlock
    var sponsorblockMark: String?
    var sponsorblockRemove: String?
    var sponsorblockChapterTitle: String?
    var noSponsorblock: Bool = false
    var sponsorblockApi: String?

    // MARK: - Extractor Options
    var extractorRetries: Int?
    var allowDynamicMpd: Bool = true
    var hlsSplitDiscontinuity: Bool = false
    var extractorArgs: [String] = []

    // MARK: - Build Command Arguments

    func toArguments() -> [String] {
        var args: [String] = []

        // General
        if ignoreErrors { args.append("--ignore-errors") }
        if abortOnError { args.append("--abort-on-error") }
        if let v = useExtractors { args += ["--use-extractors", v] }
        if let v = defaultSearch { args += ["--default-search", v] }
        if flatPlaylist { args.append("--flat-playlist") }
        if liveFromStart { args.append("--live-from-start") }
        if let v = waitForVideo { args += ["--wait-for-video", v] }
        if markWatched { args.append("--mark-watched") }
        if let v = compatOptions { args += ["--compat-options", v] }

        // Network
        if let v = proxy { args += ["--proxy", v] }
        if let v = socketTimeout { args += ["--socket-timeout", String(v)] }
        if let v = sourceAddress { args += ["--source-address", v] }
        if let v = impersonate { args += ["--impersonate", v] }
        if forceIPv4 { args.append("--force-ipv4") }
        if forceIPv6 { args.append("--force-ipv6") }
        if enableFileUrls { args.append("--enable-file-urls") }

        // Geo-restriction
        if let v = geoVerificationProxy { args += ["--geo-verification-proxy", v] }
        if let v = xff { args += ["--xff", v] }

        // Video Selection
        if let v = playlistItems { args += ["--playlist-items", v] }
        if let v = minFilesize { args += ["--min-filesize", v] }
        if let v = maxFilesize { args += ["--max-filesize", v] }
        if let v = date { args += ["--date", v] }
        if let v = dateBefore { args += ["--datebefore", v] }
        if let v = dateAfter { args += ["--dateafter", v] }
        for f in matchFilters { args += ["--match-filters", f] }
        for f in breakMatchFilters { args += ["--break-match-filters", f] }
        if noPlaylist { args.append("--no-playlist") }
        if yesPlaylist { args.append("--yes-playlist") }
        if let v = ageLimit { args += ["--age-limit", String(v)] }
        if let v = downloadArchive { args += ["--download-archive", v] }
        if let v = maxDownloads { args += ["--max-downloads", String(v)] }
        if breakOnExisting { args.append("--break-on-existing") }
        if breakPerInput { args.append("--break-per-input") }
        if let v = skipPlaylistAfterErrors { args += ["--skip-playlist-after-errors", String(v)] }

        // Download
        if let v = concurrentFragments { args += ["--concurrent-fragments", String(v)] }
        if let v = limitRate { args += ["--limit-rate", v] }
        if let v = throttledRate { args += ["--throttled-rate", v] }
        if let v = retries { args += ["--retries", String(v)] }
        if let v = fileAccessRetries { args += ["--file-access-retries", String(v)] }
        if let v = fragmentRetries { args += ["--fragment-retries", String(v)] }
        if let v = retrySleep { args += ["--retry-sleep", v] }
        if !skipUnavailableFragments { args.append("--no-skip-unavailable-fragments") }
        if keepFragments { args.append("--keep-fragments") }
        if let v = bufferSize { args += ["--buffer-size", v] }
        if noResizeBuffer { args.append("--no-resize-buffer") }
        if let v = httpChunkSize { args += ["--http-chunk-size", v] }
        if playlistReverse { args.append("--playlist-reverse") }
        if playlistRandom { args.append("--playlist-random") }
        if lazyPlaylist { args.append("--lazy-playlist") }
        if hlsUseMpegts { args.append("--hls-use-mpegts") }
        if let v = downloadSections { args += ["--download-sections", v] }
        if let v = downloader { args += ["--downloader", v] }
        if let v = downloaderArgs { args += ["--downloader-args", v] }

        // Filesystem
        if let v = batchFile { args += ["--batch-file", v] }
        if let v = paths { args += ["--paths", v] }
        if outputTemplate != "%(title)s.%(ext)s" { args += ["--output", outputTemplate] }
        if let v = outputNaPlaceholder { args += ["--output-na-placeholder", v] }
        if restrictFilenames { args.append("--restrict-filenames") }
        if windowsFilenames { args.append("--windows-filenames") }
        if let v = trimFilenames { args += ["--trim-filenames", String(v)] }
        if noOverwrites { args.append("--no-overwrites") }
        if forceOverwrites { args.append("--force-overwrites") }
        if !continueDownload { args.append("--no-continue") }
        if noPart { args.append("--no-part") }
        if noMtime { args.append("--no-mtime") }
        if writeDescription { args.append("--write-description") }
        if writeInfoJson { args.append("--write-info-json") }
        if writePlaylistMetafiles { args.append("--write-playlist-metafiles") }
        if !cleanInfoJson { args.append("--no-clean-info-json") }
        if writeComments { args.append("--write-comments") }
        if let v = cookies { args += ["--cookies", v] }
        if let v = cookiesFromBrowser { args += ["--cookies-from-browser", v] }
        if let v = cacheDir { args += ["--cache-dir", v] }
        if noCacheDir { args.append("--no-cache-dir") }

        // Format
        if let v = format { args += ["--format", v] }
        if !formatSort.isEmpty { args += ["--format-sort", formatSort.joined(separator: ",")] }
        if formatSortForce { args.append("--format-sort-force") }
        if videoMultistreams { args.append("--video-multistreams") }
        if audioMultistreams { args.append("--audio-multistreams") }
        if preferFreeFormats { args.append("--prefer-free-formats") }
        if checkFormats { args.append("--check-formats") }
        if checkAllFormats { args.append("--check-all-formats") }
        if let v = mergeOutputFormat { args += ["--merge-output-format", v] }

        // Subtitles
        if writeSubs { args.append("--write-subs") }
        if writeAutoSubs { args.append("--write-auto-subs") }
        if let v = subFormat { args += ["--sub-format", v] }
        if let v = subLangs { args += ["--sub-langs", v] }

        // Authentication
        if let v = username { args += ["--username", v] }
        if netrc { args.append("--netrc") }
        if let v = netrcLocation { args += ["--netrc-location", v] }
        if let v = apMso { args += ["--ap-mso", v] }
        if let v = apUsername { args += ["--ap-username", v] }
        if let v = clientCertificate { args += ["--client-certificate", v] }
        if let v = clientCertificateKey { args += ["--client-certificate-key", v] }

        // Thumbnails
        if writeThumbnail { args.append("--write-thumbnail") }
        if writeAllThumbnails { args.append("--write-all-thumbnails") }

        // Internet Shortcuts
        if writeLink { args.append("--write-link") }
        if writeUrlLink { args.append("--write-url-link") }
        if writeWeblocLink { args.append("--write-webloc-link") }
        if writeDesktopLink { args.append("--write-desktop-link") }

        // Verbosity
        if quiet { args.append("--quiet") }
        if noWarnings { args.append("--no-warnings") }
        if simulate { args.append("--simulate") }
        if skipDownload { args.append("--skip-download") }
        if dumpJson { args.append("--dump-json") }
        if dumpSingleJson { args.append("--dump-single-json") }
        if forceWriteArchive { args.append("--force-write-archive") }
        if verbose { args.append("--verbose") }

        // Workarounds
        if let v = encoding { args += ["--encoding", v] }
        if legacyServerConnect { args.append("--legacy-server-connect") }
        if noCheckCertificates { args.append("--no-check-certificates") }
        if preferInsecure { args.append("--prefer-insecure") }
        if let v = userAgent { args += ["--user-agent", v] }
        if let v = referer { args += ["--referer", v] }
        for h in addHeaders { args += ["--add-headers", h] }
        if let v = sleepRequests { args += ["--sleep-requests", String(v)] }
        if let v = sleepInterval { args += ["--sleep-interval", String(v)] }
        if let v = maxSleepInterval { args += ["--max-sleep-interval", String(v)] }
        if let v = sleepSubtitles { args += ["--sleep-subtitles", String(v)] }

        // Post-processing
        if extractAudio { args.append("--extract-audio") }
        if let v = audioFormat { args += ["--audio-format", v] }
        if let v = audioQuality { args += ["--audio-quality", v] }
        if let v = remuxVideo { args += ["--remux-video", v] }
        if let v = recodeVideo { args += ["--recode-video", v] }
        for a in postprocessorArgs { args += ["--postprocessor-args", a] }
        if keepVideo { args.append("--keep-video") }
        if postOverwrites { args.append("--post-overwrites") }
        if embedSubs { args.append("--embed-subs") }
        if embedThumbnail { args.append("--embed-thumbnail") }
        if embedMetadata { args.append("--embed-metadata") }
        if embedChapters { args.append("--embed-chapters") }
        if embedInfoJson { args.append("--embed-info-json") }
        for m in parseMetadata { args += ["--parse-metadata", m] }
        for r in replaceInMetadata { args += ["--replace-in-metadata", r] }
        if xattrs { args.append("--xattrs") }
        if let v = concatPlaylist { args += ["--concat-playlist", v] }
        if let v = fixup { args += ["--fixup", v] }
        if let v = ffmpegLocation { args += ["--ffmpeg-location", v] }
        for c in execCmd { args += ["--exec", c] }
        if let v = convertSubs { args += ["--convert-subs", v] }
        if let v = convertThumbnails { args += ["--convert-thumbnails", v] }
        if splitChapters { args.append("--split-chapters") }
        for r in removeChapters { args += ["--remove-chapters", r] }
        if forceKeyframesAtCuts { args.append("--force-keyframes-at-cuts") }
        for p in usePostprocessor { args += ["--use-postprocessor", p] }

        // SponsorBlock
        if let v = sponsorblockMark { args += ["--sponsorblock-mark", v] }
        if let v = sponsorblockRemove { args += ["--sponsorblock-remove", v] }
        if let v = sponsorblockChapterTitle { args += ["--sponsorblock-chapter-title", v] }
        if noSponsorblock { args.append("--no-sponsorblock") }
        if let v = sponsorblockApi { args += ["--sponsorblock-api", v] }

        // Extractor
        if let v = extractorRetries { args += ["--extractor-retries", String(v)] }
        if !allowDynamicMpd { args.append("--no-allow-dynamic-mpd") }
        if hlsSplitDiscontinuity { args.append("--hls-split-discontinuity") }
        for a in extractorArgs { args += ["--extractor-args", a] }

        return args
    }
}

// MARK: - Audio Format Options

enum AudioFormatOption: String, CaseIterable, Identifiable {
    case best, aac, alac, flac, m4a, mp3, opus, vorbis, wav
    var id: String { rawValue }
}

// MARK: - Merge Output Format Options

enum MergeOutputFormatOption: String, CaseIterable, Identifiable {
    case avi, flv, mkv, mov, mp4, webm
    var id: String { rawValue }
}

// MARK: - Subtitle Format Options

enum SubtitleFormatOption: String, CaseIterable, Identifiable {
    case srt, ass, vtt, lrc
    var id: String { rawValue }
}

// MARK: - Fixup Policy Options

enum FixupPolicyOption: String, CaseIterable, Identifiable {
    case never, warn, detect_or_warn, force
    var id: String { rawValue }
}

// MARK: - Impersonate Options

enum ImpersonateOption: String, CaseIterable, Identifiable {
    case chrome, edge, firefox, safari
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chrome: return "Chrome"
        case .edge: return "Edge"
        case .firefox: return "Firefox"
        case .safari: return "Safari"
        }
    }
}

// MARK: - SponsorBlock Categories

enum SponsorBlockCategory: String, CaseIterable, Identifiable {
    case sponsor, intro, outro, selfpromo, preview, filler, interaction, music_offtopic, all
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sponsor: return "Sponsor"
        case .intro: return "Intro"
        case .outro: return "Outro"
        case .selfpromo: return "Self Promotion"
        case .preview: return "Preview"
        case .filler: return "Filler"
        case .interaction: return "Interaction"
        case .music_offtopic: return "Off-topic Music"
        case .all: return "All Categories"
        }
    }
}
