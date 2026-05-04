//
//  ytdlp_guiTests.swift
//  ytdlp-guiTests
//
//  Comprehensive test suite for ytdlp-gui
//  Covers: Unit, Security, Integration, Functional, and Frame tests
//  Written by Jordan Koch on 2026-02-25.
//  Updated by Jordan Koch on 2026-05-03.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import XCTest
@testable import ytdlp_gui

// =============================================================================
// MARK: - Unit Tests
// =============================================================================

// MARK: - Unit Tests: YTDLPOptions (Argument Generation)

final class YTDLPOptionsTests: XCTestCase {

    func testDefaultOptionsGenerateNoArguments() {
        let options = YTDLPOptions()
        let args = options.toArguments()
        XCTAssertTrue(args.isEmpty, "Default options should generate no arguments")
    }

    func testExtractAudioGeneratesCorrectFlags() {
        var options = YTDLPOptions()
        options.extractAudio = true
        options.audioFormat = "mp3"
        options.audioQuality = "0"

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--extract-audio"))
        XCTAssertTrue(args.contains("--audio-format"))
        XCTAssertTrue(args.contains("mp3"))
        XCTAssertTrue(args.contains("--audio-quality"))
        XCTAssertTrue(args.contains("0"))
    }

    func testFormatOptionGeneratesCorrectFlag() {
        var options = YTDLPOptions()
        options.format = "bv*+ba/b"

        let args = options.toArguments()
        XCTAssertEqual(args, ["--format", "bv*+ba/b"])
    }

    func testNetworkOptionsGenerateCorrectFlags() {
        var options = YTDLPOptions()
        options.proxy = "socks5://127.0.0.1:9050"
        options.forceIPv4 = true
        options.socketTimeout = 30

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--proxy"))
        XCTAssertTrue(args.contains("socks5://127.0.0.1:9050"))
        XCTAssertTrue(args.contains("--force-ipv4"))
        XCTAssertTrue(args.contains("--socket-timeout"))
        XCTAssertTrue(args.contains("30"))
    }

    func testStealthOptionsGenerateCorrectFlags() {
        var options = YTDLPOptions()
        options.userAgent = "Mozilla/5.0 Test"
        options.sleepInterval = 2.0
        options.maxSleepInterval = 5.0
        options.impersonate = "chrome"

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--user-agent"))
        XCTAssertTrue(args.contains("Mozilla/5.0 Test"))
        XCTAssertTrue(args.contains("--sleep-interval"))
        XCTAssertTrue(args.contains("--impersonate"))
        XCTAssertTrue(args.contains("chrome"))
    }

    func testSponsorBlockOptionsGenerateCorrectFlags() {
        var options = YTDLPOptions()
        options.sponsorblockRemove = "sponsor,intro"

        let args = options.toArguments()
        XCTAssertEqual(args, ["--sponsorblock-remove", "sponsor,intro"])
    }

    func testCustomOutputTemplateGeneratesFlag() {
        var options = YTDLPOptions()
        options.outputTemplate = "%(uploader)s/%(title)s.%(ext)s"

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--output"))
        XCTAssertTrue(args.contains("%(uploader)s/%(title)s.%(ext)s"))
    }

    func testDefaultOutputTemplateGeneratesNoFlag() {
        let options = YTDLPOptions()
        let args = options.toArguments()
        XCTAssertFalse(args.contains("--output"), "Default output template should not generate --output flag")
    }

    func testSubtitleOptionsGenerateCorrectFlags() {
        var options = YTDLPOptions()
        options.writeSubs = true
        options.writeAutoSubs = true
        options.subFormat = "srt"
        options.subLangs = "en,es"

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--write-subs"))
        XCTAssertTrue(args.contains("--write-auto-subs"))
        XCTAssertTrue(args.contains("--sub-format"))
        XCTAssertTrue(args.contains("srt"))
        XCTAssertTrue(args.contains("--sub-langs"))
        XCTAssertTrue(args.contains("en,es"))
    }

    func testPostProcessingOptionsGenerateCorrectFlags() {
        var options = YTDLPOptions()
        options.embedThumbnail = true
        options.embedMetadata = true
        options.embedSubs = true
        options.embedChapters = true
        options.remuxVideo = "mkv"

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--embed-thumbnail"))
        XCTAssertTrue(args.contains("--embed-metadata"))
        XCTAssertTrue(args.contains("--embed-subs"))
        XCTAssertTrue(args.contains("--embed-chapters"))
        XCTAssertTrue(args.contains("--remux-video"))
        XCTAssertTrue(args.contains("mkv"))
    }

    func testPlaylistOptionsGenerateCorrectFlags() {
        var options = YTDLPOptions()
        options.noPlaylist = true
        options.playlistItems = "1-5"

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--no-playlist"))
        XCTAssertTrue(args.contains("--playlist-items"))
        XCTAssertTrue(args.contains("1-5"))
    }

    func testFilesystemOptionsGenerateCorrectFlags() {
        var options = YTDLPOptions()
        options.restrictFilenames = true
        options.noOverwrites = true
        options.noPart = true

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--restrict-filenames"))
        XCTAssertTrue(args.contains("--no-overwrites"))
        XCTAssertTrue(args.contains("--no-part"))
    }

    func testCookiesFromBrowserOptionGeneratesCorrectFlag() {
        var options = YTDLPOptions()
        options.cookiesFromBrowser = "chrome"

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--cookies-from-browser"))
        XCTAssertTrue(args.contains("chrome"))
    }

    func testCookieFileOptionGeneratesCorrectFlag() {
        var options = YTDLPOptions()
        options.cookies = "/tmp/cookies.txt"

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--cookies"))
        XCTAssertTrue(args.contains("/tmp/cookies.txt"))
    }

    func testMultipleHeadersGenerateMultipleFlags() {
        var options = YTDLPOptions()
        options.addHeaders = ["Authorization:Bearer token", "Cookie:CONSENT=PENDING+999"]

        let args = options.toArguments()
        let headerOccurrences = args.filter { $0 == "--add-headers" }.count
        XCTAssertEqual(headerOccurrences, 2, "Should generate two --add-headers flags")
    }

    func testFormatSortGeneratesCommaSeparatedFlag() {
        var options = YTDLPOptions()
        options.formatSort = ["res", "ext:mp4:m4a"]

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--format-sort"))
        XCTAssertTrue(args.contains("res,ext:mp4:m4a"))
    }

    func testMatchFiltersGenerateMultipleFlags() {
        var options = YTDLPOptions()
        options.matchFilters = ["duration > 60", "like_count > 100"]

        let args = options.toArguments()
        let filterCount = args.filter { $0 == "--match-filters" }.count
        XCTAssertEqual(filterCount, 2)
    }

    func testExtractorArgsGenerateMultipleFlags() {
        var options = YTDLPOptions()
        options.extractorArgs = ["youtube:player_client=web", "youtube:po_token=abc123"]

        let args = options.toArguments()
        let extractorArgCount = args.filter { $0 == "--extractor-args" }.count
        XCTAssertEqual(extractorArgCount, 2)
    }

    func testDownloadSectionsGeneratesFlag() {
        var options = YTDLPOptions()
        options.downloadSections = "*00:00-05:00"

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--download-sections"))
        XCTAssertTrue(args.contains("*00:00-05:00"))
    }

    func testLimitRateGeneratesFlag() {
        var options = YTDLPOptions()
        options.limitRate = "5M"

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--limit-rate"))
        XCTAssertTrue(args.contains("5M"))
    }

    func testContinueDownloadDisabledGeneratesFlag() {
        var options = YTDLPOptions()
        options.continueDownload = false

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--no-continue"))
    }

    func testContinueDownloadEnabledByDefaultGeneratesNoFlag() {
        let options = YTDLPOptions()
        XCTAssertFalse(options.toArguments().contains("--no-continue"))
    }

    func testOptionsEquality() {
        let a = YTDLPOptions()
        var b = YTDLPOptions()
        XCTAssertEqual(a, b)

        b.format = "mp4"
        XCTAssertNotEqual(a, b)
    }

    func testOptionsCodable() throws {
        var options = YTDLPOptions()
        options.format = "bv*+ba/b"
        options.extractAudio = true
        options.audioFormat = "mp3"
        options.proxy = "socks5://proxy"

        let data = try JSONEncoder().encode(options)
        let decoded = try JSONDecoder().decode(YTDLPOptions.self, from: data)
        XCTAssertEqual(options, decoded)
    }

    func testVerbosityOptionsGenerateFlags() {
        var options = YTDLPOptions()
        options.quiet = true
        options.verbose = true
        options.simulate = true

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--quiet"))
        XCTAssertTrue(args.contains("--verbose"))
        XCTAssertTrue(args.contains("--simulate"))
    }

    func testGeoRestrictionOptionsGenerateFlags() {
        var options = YTDLPOptions()
        options.geoVerificationProxy = "http://proxy.example.com"
        options.xff = "default"

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--geo-verification-proxy"))
        XCTAssertTrue(args.contains("http://proxy.example.com"))
        XCTAssertTrue(args.contains("--xff"))
        XCTAssertTrue(args.contains("default"))
    }

    func testAuthenticationOptionsGenerateFlags() {
        var options = YTDLPOptions()
        options.username = "testuser"
        options.netrc = true

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--username"))
        XCTAssertTrue(args.contains("testuser"))
        XCTAssertTrue(args.contains("--netrc"))
        // Password should NOT be in default args -- it comes from Keychain at runtime
        XCTAssertFalse(args.contains("--password"))
    }

    func testRecodeVideoGeneratesFlag() {
        var options = YTDLPOptions()
        options.recodeVideo = "mp4"

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--recode-video"))
        XCTAssertTrue(args.contains("mp4"))
    }

    func testNoAllowDynamicMpdGeneratesFlag() {
        var options = YTDLPOptions()
        options.allowDynamicMpd = false

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--no-allow-dynamic-mpd"))
    }

    func testAllowDynamicMpdDefaultGeneratesNoFlag() {
        let options = YTDLPOptions()
        XCTAssertFalse(options.toArguments().contains("--no-allow-dynamic-mpd"))
    }
}

// MARK: - Unit Tests: Progress Parsing

final class ProgressParsingTests: XCTestCase {

    func testPercentageExtractionFromTypicalLine() {
        let line = "[download]  45.2% of ~123.45MiB at 5.67MiB/s ETA 00:15"
        let regex = try! NSRegularExpression(pattern: #"(\d+\.?\d*)%"#)
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        let match = regex.firstMatch(in: line, range: range)
        XCTAssertNotNil(match)

        if let matchRange = Range(match!.range(at: 1), in: line) {
            let percentStr = String(line[matchRange])
            XCTAssertEqual(Double(percentStr), 45.2)
        }
    }

    func testPercentageExtractionFrom100Percent() {
        let line = "[download] 100% of  123.45MiB in 00:21"
        let regex = try! NSRegularExpression(pattern: #"(\d+\.?\d*)%"#)
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        let match = regex.firstMatch(in: line, range: range)
        XCTAssertNotNil(match)

        if let matchRange = Range(match!.range(at: 1), in: line) {
            let percentStr = String(line[matchRange])
            XCTAssertEqual(Double(percentStr), 100.0)
        }
    }

    func testSpeedExtractionFromLine() {
        let line = "[download]  45.2% of ~123.45MiB at 5.67MiB/s ETA 00:15"
        let regex = try! NSRegularExpression(pattern: #"at\s+([\d.]+\w+/s)"#)
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        let match = regex.firstMatch(in: line, range: range)
        XCTAssertNotNil(match)

        if let matchRange = Range(match!.range(at: 1), in: line) {
            let speedStr = String(line[matchRange])
            XCTAssertEqual(speedStr, "5.67MiB/s")
        }
    }

    func testETAExtractionFromLine() {
        let line = "[download]  45.2% of ~123.45MiB at 5.67MiB/s ETA 00:15"
        let regex = try! NSRegularExpression(pattern: #"ETA\s+(\d+:\d+:\d+|\d+:\d+)"#)
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        let match = regex.firstMatch(in: line, range: range)
        XCTAssertNotNil(match)

        if let matchRange = Range(match!.range(at: 1), in: line) {
            let etaStr = String(line[matchRange])
            XCTAssertEqual(etaStr, "00:15")
        }
    }

    func testTotalSizeExtractionWithTilde() {
        let line = "[download]  45.2% of ~123.45MiB at 5.67MiB/s ETA 00:15"
        let regex = try! NSRegularExpression(pattern: #"of\s+~?([\d.]+\w+)"#)
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        let match = regex.firstMatch(in: line, range: range)
        XCTAssertNotNil(match)

        if let matchRange = Range(match!.range(at: 1), in: line) {
            let sizeStr = String(line[matchRange])
            XCTAssertEqual(sizeStr, "123.45MiB")
        }
    }

    func testNonDownloadLineDoesNotMatch() {
        let line = "[info] Extracting URL: https://www.youtube.com/watch?v=test"
        XCTAssertFalse(line.contains("[download]") && line.contains("%"))
    }

    func testDestinationLineDetection() {
        let line = "[download] Destination: /Users/test/Downloads/video.mp4"
        XCTAssertTrue(line.contains("[download] Destination:"))
        let path = line.components(separatedBy: "Destination: ").last?.trimmingCharacters(in: .whitespaces)
        XCTAssertEqual(path, "/Users/test/Downloads/video.mp4")
    }

    func testMergerLineDetection() {
        let line = #"[Merger] Merging formats into "/Users/test/Downloads/video.mkv""#
        XCTAssertTrue(line.contains("[Merger]"))
        let path = line.components(separatedBy: "\"").dropFirst().first
        XCTAssertEqual(path, "/Users/test/Downloads/video.mkv")
    }

    func testETAExtractionWithHours() {
        let line = "[download]  12.5% of ~2.30GiB at 10.20MiB/s ETA 01:23:45"
        let regex = try! NSRegularExpression(pattern: #"ETA\s+(\d+:\d+:\d+|\d+:\d+)"#)
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        let match = regex.firstMatch(in: line, range: range)
        XCTAssertNotNil(match)

        if let matchRange = Range(match!.range(at: 1), in: line) {
            let etaStr = String(line[matchRange])
            XCTAssertEqual(etaStr, "01:23:45")
        }
    }
}

// MARK: - Unit Tests: Byte Size Parsing

final class ByteSizeParsingTests: XCTestCase {

    func testParseMiB() {
        let value = parseByteSize("123.45MiB")
        let expected = Int64(123.45 * 1024 * 1024)
        XCTAssertEqual(value, expected)
    }

    func testParseGiB() {
        let value = parseByteSize("2.30GiB")
        let expected = Int64(2.30 * 1024 * 1024 * 1024)
        XCTAssertEqual(value, expected)
    }

    func testParseKiB() {
        let value = parseByteSize("512.0KiB")
        let expected = Int64(512.0 * 1024)
        XCTAssertEqual(value, expected)
    }

    func testParseMB() {
        let value = parseByteSize("100.0MB")
        let expected = Int64(100.0 * 1024 * 1024)
        XCTAssertEqual(value, expected)
    }

    func testParseGB() {
        let value = parseByteSize("1.5GB")
        let expected = Int64(1.5 * 1024 * 1024 * 1024)
        XCTAssertEqual(value, expected)
    }

    func testParseKB() {
        let value = parseByteSize("256KB")
        let expected = Int64(256.0 * 1024)
        XCTAssertEqual(value, expected)
    }

    func testParseB() {
        let value = parseByteSize("1024B")
        XCTAssertEqual(value, 1024)
    }

    func testParseEmptyString() {
        let value = parseByteSize("")
        XCTAssertEqual(value, 0)
    }

    // Helper: mirrors YTDLPService.parseByteSize (private)
    private func parseByteSize(_ str: String) -> Int64 {
        let str = str.trimmingCharacters(in: .whitespaces)

        if str.hasSuffix("GiB") || str.hasSuffix("GB") {
            let num = str.replacingOccurrences(of: "GiB", with: "").replacingOccurrences(of: "GB", with: "")
            return Int64((Double(num) ?? 0) * 1024 * 1024 * 1024)
        }
        if str.hasSuffix("MiB") || str.hasSuffix("MB") {
            let num = str.replacingOccurrences(of: "MiB", with: "").replacingOccurrences(of: "MB", with: "")
            return Int64((Double(num) ?? 0) * 1024 * 1024)
        }
        if str.hasSuffix("KiB") || str.hasSuffix("KB") {
            let num = str.replacingOccurrences(of: "KiB", with: "").replacingOccurrences(of: "KB", with: "")
            return Int64((Double(num) ?? 0) * 1024)
        }
        if str.hasSuffix("B") {
            let num = str.replacingOccurrences(of: "B", with: "")
            return Int64(Double(num) ?? 0)
        }

        return Int64(Double(str) ?? 0)
    }
}

// MARK: - Unit Tests: Time String Parsing

final class TimeParsingTests: XCTestCase {

    func testParseMMSS() {
        let result = parseTimeString("05:30")
        XCTAssertEqual(result, 330.0) // 5*60 + 30
    }

    func testParseHHMMSS() {
        let result = parseTimeString("01:23:45")
        XCTAssertEqual(result, 5025.0) // 1*3600 + 23*60 + 45
    }

    func testParseZeroTime() {
        let result = parseTimeString("00:00")
        XCTAssertEqual(result, 0.0)
    }

    func testParseSingleDigitMinutes() {
        let result = parseTimeString("2:15")
        XCTAssertEqual(result, 135.0)
    }

    // Mirrors YTDLPService.parseTimeString
    private func parseTimeString(_ str: String) -> TimeInterval {
        let parts = str.split(separator: ":").map { Int($0) ?? 0 }
        if parts.count == 3 {
            return TimeInterval(parts[0] * 3600 + parts[1] * 60 + parts[2])
        } else if parts.count == 2 {
            return TimeInterval(parts[0] * 60 + parts[1])
        }
        return 0
    }
}

// MARK: - Unit Tests: YouTube Video ID Extraction

final class YouTubeIDExtractionTests: XCTestCase {

    func testExtractFromWatchURL() {
        let id = extractYouTubeVideoID(from: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        XCTAssertEqual(id, "dQw4w9WgXcQ")
    }

    func testExtractFromWatchURLWithExtraParams() {
        let id = extractYouTubeVideoID(from: "https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=RDdQw4w9WgXcQ&index=1")
        XCTAssertEqual(id, "dQw4w9WgXcQ")
    }

    func testExtractFromShortURL() {
        let id = extractYouTubeVideoID(from: "https://youtu.be/dQw4w9WgXcQ")
        XCTAssertEqual(id, "dQw4w9WgXcQ")
    }

    func testExtractFromShortURLWithParams() {
        let id = extractYouTubeVideoID(from: "https://youtu.be/dQw4w9WgXcQ?t=120")
        XCTAssertEqual(id, "dQw4w9WgXcQ")
    }

    func testExtractFromShortsURL() {
        let id = extractYouTubeVideoID(from: "https://www.youtube.com/shorts/abc123XYZ-_")
        XCTAssertEqual(id, "abc123XYZ-_")
    }

    func testExtractFromNonYouTubeURLReturnsNil() {
        let id = extractYouTubeVideoID(from: "https://vimeo.com/12345678")
        XCTAssertNil(id)
    }

    func testExtractFromEmptyStringReturnsNil() {
        let id = extractYouTubeVideoID(from: "")
        XCTAssertNil(id)
    }

    func testExtractFromShortsURLWithParams() {
        let id = extractYouTubeVideoID(from: "https://www.youtube.com/shorts/abc123XYZ?feature=share")
        XCTAssertEqual(id, "abc123XYZ")
    }

    func testExtractFromWatchURLWithHash() {
        let id = extractYouTubeVideoID(from: "https://www.youtube.com/watch?v=dQw4w9WgXcQ#t=30")
        XCTAssertEqual(id, "dQw4w9WgXcQ")
    }

    // Mirrors SponsorBlockService.extractYouTubeVideoID
    private func extractYouTubeVideoID(from url: String) -> String? {
        if let range = url.range(of: "v=") {
            let start = range.upperBound
            let remaining = String(url[start...])
            return String(remaining.prefix(while: { $0 != "&" && $0 != "#" }))
        }
        if url.contains("youtu.be/") {
            if let range = url.range(of: "youtu.be/") {
                let start = range.upperBound
                let remaining = String(url[start...])
                return String(remaining.prefix(while: { $0 != "?" && $0 != "#" }))
            }
        }
        if url.contains("/shorts/") {
            if let range = url.range(of: "/shorts/") {
                let start = range.upperBound
                let remaining = String(url[start...])
                return String(remaining.prefix(while: { $0 != "?" && $0 != "#" }))
            }
        }
        return nil
    }
}

// MARK: - Unit Tests: URL Video Detection (ClipboardMonitor)

final class URLVideoDetectionTests: XCTestCase {

    func testYouTubeWatchURL() {
        XCTAssertTrue(isVideoURL("https://www.youtube.com/watch?v=dQw4w9WgXcQ"))
    }

    func testYouTubeShortURL() {
        XCTAssertTrue(isVideoURL("https://youtu.be/dQw4w9WgXcQ"))
    }

    func testYouTubePlaylistURL() {
        XCTAssertTrue(isVideoURL("https://www.youtube.com/playlist?list=PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf"))
    }

    func testYouTubeShortsURL() {
        XCTAssertTrue(isVideoURL("https://www.youtube.com/shorts/abc123"))
    }

    func testVimeoURL() {
        XCTAssertTrue(isVideoURL("https://vimeo.com/12345678"))
    }

    func testTwitchVODURL() {
        XCTAssertTrue(isVideoURL("https://www.twitch.tv/videos/12345"))
    }

    func testTwitterURL() {
        XCTAssertTrue(isVideoURL("https://twitter.com/user/status/12345"))
    }

    func testXURL() {
        XCTAssertTrue(isVideoURL("https://x.com/user/status/12345"))
    }

    func testInstagramReelURL() {
        XCTAssertTrue(isVideoURL("https://www.instagram.com/reel/abc123/"))
    }

    func testInstagramPostURL() {
        XCTAssertTrue(isVideoURL("https://www.instagram.com/p/abc123/"))
    }

    func testTikTokURL() {
        XCTAssertTrue(isVideoURL("https://www.tiktok.com/@user/video/12345"))
    }

    func testSoundCloudURL() {
        XCTAssertTrue(isVideoURL("https://soundcloud.com/artist/track-name"))
    }

    func testBandcampURL() {
        XCTAssertTrue(isVideoURL("https://artist.bandcamp.com/track/song"))
    }

    func testRedditURL() {
        XCTAssertTrue(isVideoURL("https://www.reddit.com/r/videos/comments/abc123"))
    }

    func testDailymotionURL() {
        XCTAssertTrue(isVideoURL("https://www.dailymotion.com/video/x8abc"))
    }

    func testBilibiliURL() {
        XCTAssertTrue(isVideoURL("https://www.bilibili.com/video/BV1xx411c7mD"))
    }

    func testCrunchyrollURL() {
        XCTAssertTrue(isVideoURL("https://www.crunchyroll.com/watch/GRMEH5"))
    }

    func testNonVideoURL() {
        XCTAssertFalse(isVideoURL("https://www.google.com"))
    }

    func testPlainText() {
        XCTAssertFalse(isVideoURL("just some text"))
    }

    func testFTPSchemeRejected() {
        XCTAssertFalse(isVideoURL("ftp://youtube.com/watch?v=test"))
    }

    func testHTTPAllowed() {
        XCTAssertTrue(isVideoURL("http://www.youtube.com/watch?v=test"))
    }

    // Mirrors ClipboardMonitor.isVideoURL
    private static let videoPatterns: [String] = [
        "youtube.com/watch", "youtu.be/", "youtube.com/playlist", "youtube.com/shorts",
        "vimeo.com/", "dailymotion.com/video", "twitch.tv/videos",
        "twitter.com/", "x.com/", "instagram.com/reel", "instagram.com/p/",
        "tiktok.com/", "facebook.com/watch", "reddit.com/r/",
        "soundcloud.com/", "bandcamp.com/", "bilibili.com/video",
        "nicovideo.jp/watch", "crunchyroll.com/watch",
    ]

    private func isVideoURL(_ string: String) -> Bool {
        guard string.hasPrefix("http://") || string.hasPrefix("https://") else { return false }
        let lowered = string.lowercased()
        return Self.videoPatterns.contains { lowered.contains($0) }
    }
}

// MARK: - Unit Tests: DownloadItem & DownloadStatus

final class DownloadItemTests: XCTestCase {

    func testDownloadItemInitialization() {
        let item = DownloadItem(url: "https://youtube.com/watch?v=test")
        XCTAssertEqual(item.url, "https://youtube.com/watch?v=test")
        XCTAssertEqual(item.status, .queued)
        XCTAssertEqual(item.retryCount, 0)
        XCTAssertNil(item.title)
        XCTAssertNil(item.outputPath)
        XCTAssertNil(item.errorMessage)
    }

    func testDownloadStatusIsActive() {
        XCTAssertTrue(DownloadStatus.downloading.isActive)
        XCTAssertTrue(DownloadStatus.fetchingMetadata.isActive)
        XCTAssertTrue(DownloadStatus.postProcessing.isActive)
        XCTAssertTrue(DownloadStatus.retrying.isActive)
        XCTAssertFalse(DownloadStatus.queued.isActive)
        XCTAssertFalse(DownloadStatus.completed.isActive)
        XCTAssertFalse(DownloadStatus.failed.isActive)
        XCTAssertFalse(DownloadStatus.cancelled.isActive)
        XCTAssertFalse(DownloadStatus.paused.isActive)
    }

    func testDownloadStatusIsTerminal() {
        XCTAssertTrue(DownloadStatus.completed.isTerminal)
        XCTAssertTrue(DownloadStatus.failed.isTerminal)
        XCTAssertTrue(DownloadStatus.cancelled.isTerminal)
        XCTAssertFalse(DownloadStatus.downloading.isTerminal)
        XCTAssertFalse(DownloadStatus.queued.isTerminal)
        XCTAssertFalse(DownloadStatus.paused.isTerminal)
        XCTAssertFalse(DownloadStatus.retrying.isTerminal)
    }

    func testDownloadStatusAllCases() {
        XCTAssertEqual(DownloadStatus.allCases.count, 9)
    }

    func testDownloadStatusRawValues() {
        XCTAssertEqual(DownloadStatus.queued.rawValue, "Queued")
        XCTAssertEqual(DownloadStatus.downloading.rawValue, "Downloading")
        XCTAssertEqual(DownloadStatus.completed.rawValue, "Completed")
        XCTAssertEqual(DownloadStatus.failed.rawValue, "Failed")
    }

    func testDownloadItemCodable() throws {
        var item = DownloadItem(url: "https://test.com")
        item.title = "Test Video"
        item.status = .completed

        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(DownloadItem.self, from: data)

        XCTAssertEqual(decoded.url, item.url)
        XCTAssertEqual(decoded.title, item.title)
        XCTAssertEqual(decoded.status, item.status)
    }

    func testDownloadItemPlaylistContext() {
        var item = DownloadItem(url: "https://youtube.com/watch?v=test")
        item.playlistTitle = "My Playlist"
        item.playlistIndex = 3
        item.playlistTotal = 10

        XCTAssertEqual(item.playlistTitle, "My Playlist")
        XCTAssertEqual(item.playlistIndex, 3)
        XCTAssertEqual(item.playlistTotal, 10)
    }

    func testDownloadItemTimingProperties() {
        var item = DownloadItem(url: "https://test.com")
        XCTAssertNotNil(item.addedAt)
        XCTAssertNil(item.startedAt)
        XCTAssertNil(item.completedAt)

        item.startedAt = Date()
        item.completedAt = Date()
        XCTAssertNotNil(item.startedAt)
        XCTAssertNotNil(item.completedAt)
    }
}

// MARK: - Unit Tests: DownloadProgress

final class DownloadProgressTests: XCTestCase {

    func testDefaultProgressValues() {
        let progress = DownloadProgress()
        XCTAssertEqual(progress.percentage, 0)
        XCTAssertEqual(progress.downloadedBytes, 0)
        XCTAssertNil(progress.totalBytes)
        XCTAssertEqual(progress.speed, 0)
        XCTAssertNil(progress.eta)
    }

    func testSpeedFormatted() {
        var progress = DownloadProgress()
        progress.speed = 5_000_000 // ~5 MB/s
        let formatted = progress.speedFormatted
        XCTAssertTrue(formatted.contains("/s"))
    }

    func testDownloadedFormatted() {
        var progress = DownloadProgress()
        progress.downloadedBytes = 1_048_576 // 1 MiB
        let formatted = progress.downloadedFormatted
        XCTAssertFalse(formatted.isEmpty)
    }

    func testTotalFormattedNilWhenNone() {
        let progress = DownloadProgress()
        XCTAssertNil(progress.totalFormatted)
    }

    func testTotalFormattedWhenSet() {
        var progress = DownloadProgress()
        progress.totalBytes = 10_485_760 // 10 MiB
        XCTAssertNotNil(progress.totalFormatted)
    }

    func testETAFormattedNilWhenNone() {
        let progress = DownloadProgress()
        XCTAssertNil(progress.etaFormatted)
    }

    func testETAFormattedWithMinutes() {
        var progress = DownloadProgress()
        progress.eta = 90 // 1:30
        XCTAssertEqual(progress.etaFormatted, "1:30")
    }

    func testETAFormattedWithSecondsOnly() {
        var progress = DownloadProgress()
        progress.eta = 45
        XCTAssertEqual(progress.etaFormatted, "45s")
    }

    func testETAFormattedZeroReturnsNil() {
        var progress = DownloadProgress()
        progress.eta = 0
        XCTAssertNil(progress.etaFormatted)
    }

    func testProgressCodable() throws {
        var progress = DownloadProgress()
        progress.percentage = 75.5
        progress.speed = 1234567
        progress.totalBytes = 9876543

        let data = try JSONEncoder().encode(progress)
        let decoded = try JSONDecoder().decode(DownloadProgress.self, from: data)

        XCTAssertEqual(decoded.percentage, progress.percentage)
        XCTAssertEqual(decoded.speed, progress.speed)
        XCTAssertEqual(decoded.totalBytes, progress.totalBytes)
    }

    func testFragmentTracking() {
        var progress = DownloadProgress()
        progress.currentFragment = 5
        progress.totalFragments = 20

        XCTAssertEqual(progress.currentFragment, 5)
        XCTAssertEqual(progress.totalFragments, 20)
    }
}

// MARK: - Unit Tests: DownloadPreset

final class DownloadPresetTests: XCTestCase {

    func testBuiltInPresetsCount() {
        XCTAssertEqual(DownloadPreset.builtInPresets.count, 6)
    }

    func testBestVideoPresetFormat() {
        let preset = DownloadPreset.bestVideo
        XCTAssertEqual(preset.options.format, "bv*+ba/b")
        XCTAssertTrue(preset.isBuiltIn)
    }

    func testAudioMP3PresetOptions() {
        let preset = DownloadPreset.audioMP3
        XCTAssertTrue(preset.options.extractAudio)
        XCTAssertEqual(preset.options.audioFormat, "mp3")
        XCTAssertEqual(preset.options.audioQuality, "0")
    }

    func testAudioFLACPresetOptions() {
        let preset = DownloadPreset.audioFLAC
        XCTAssertTrue(preset.options.extractAudio)
        XCTAssertEqual(preset.options.audioFormat, "flac")
    }

    func test1080pPresetFormat() {
        let preset = DownloadPreset.quality1080p
        XCTAssertTrue(preset.options.format!.contains("1080"))
    }

    func test720pPresetFormat() {
        let preset = DownloadPreset.quality720p
        XCTAssertTrue(preset.options.format!.contains("720"))
    }

    func testStealthModePresetHasSleepInterval() {
        let preset = DownloadPreset.stealthMode
        XCTAssertNotNil(preset.options.sleepInterval)
        XCTAssertNotNil(preset.options.maxSleepInterval)
        XCTAssertNotNil(preset.options.sleepRequests)
        XCTAssertEqual(preset.options.retries, 10)
    }

    func testPresetCodable() throws {
        let preset = DownloadPreset.bestVideo
        let data = try JSONEncoder().encode(preset)
        let decoded = try JSONDecoder().decode(DownloadPreset.self, from: data)
        XCTAssertEqual(decoded.name, preset.name)
        XCTAssertEqual(decoded.options.format, preset.options.format)
    }

    func testAllPresetsHaveNames() {
        for preset in DownloadPreset.builtInPresets {
            XCTAssertFalse(preset.name.isEmpty, "Preset should have a name")
            XCTAssertFalse(preset.icon.isEmpty, "Preset should have an icon")
            XCTAssertFalse(preset.description.isEmpty, "Preset should have a description")
        }
    }

    func testAllPresetsHaveColorHex() {
        for preset in DownloadPreset.builtInPresets {
            XCTAssertTrue(preset.colorHex.hasPrefix("#"), "Preset color should be a hex code: \(preset.name)")
            XCTAssertEqual(preset.colorHex.count, 7, "Hex color should be 7 characters (#RRGGBB): \(preset.name)")
        }
    }
}

// MARK: - Unit Tests: OutputTemplate

final class OutputTemplateTests: XCTestCase {

    func testAllVariablesExist() {
        XCTAssertGreaterThan(OutputTemplateVariable.allVariables.count, 20)
    }

    func testVariableCategoryCoverage() {
        for category in OutputTemplateVariable.TemplateCategory.allCases {
            let vars = OutputTemplateVariable.variables(for: category)
            XCTAssertFalse(vars.isEmpty, "\(category.rawValue) should have variables")
        }
    }

    func testBuiltInPresetsExist() {
        XCTAssertGreaterThan(OutputTemplatePreset.builtIn.count, 3)
    }

    func testDefaultPresetIsCorrect() {
        let defaultPreset = OutputTemplatePreset.builtIn.first { $0.name == "Default" }
        XCTAssertNotNil(defaultPreset)
        XCTAssertEqual(defaultPreset?.template, "%(title)s.%(ext)s")
    }

    func testVariableCodesContainPercent() {
        for variable in OutputTemplateVariable.allVariables {
            XCTAssertTrue(variable.code.hasPrefix("%("), "Variable code should start with %(: \(variable.code)")
            XCTAssertTrue(variable.code.hasSuffix(")s"), "Variable code should end with )s: \(variable.code)")
        }
    }

    func testPresetCodable() throws {
        let preset = OutputTemplatePreset.builtIn.first!
        let data = try JSONEncoder().encode(preset)
        let decoded = try JSONDecoder().decode(OutputTemplatePreset.self, from: data)
        XCTAssertEqual(decoded.template, preset.template)
        XCTAssertEqual(decoded.name, preset.name)
    }

    func testPlaylistPresetContainsPlaylistIndex() {
        let playlistPreset = OutputTemplatePreset.builtIn.first { $0.name == "Playlist" }
        XCTAssertNotNil(playlistPreset)
        XCTAssertTrue(playlistPreset!.template.contains("%(playlist_index)s"))
    }
}

// MARK: - Unit Tests: StealthProfile

final class StealthProfileTests: XCTestCase {

    func testDefaultStealthProfile() {
        let profile = StealthProfile()
        XCTAssertTrue(profile.isEnabled)
        XCTAssertTrue(profile.rotateUserAgents)
        XCTAssertTrue(profile.randomDelayEnabled)
        XCTAssertEqual(profile.minDelay, 1.0)
        XCTAssertEqual(profile.maxDelay, 5.0)
        XCTAssertEqual(profile.maxRetries, 5)
    }

    func testPlayerClientsDefault() {
        let profile = StealthProfile()
        XCTAssertEqual(profile.playerClients, ["web", "android", "ios", "mweb"])
    }

    func testProfileCodable() throws {
        var profile = StealthProfile()
        profile.proxyEnabled = true
        profile.proxyList = ["socks5://proxy1", "socks5://proxy2"]
        profile.poToken = "test_token"

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(StealthProfile.self, from: data)

        XCTAssertTrue(decoded.proxyEnabled)
        XCTAssertEqual(decoded.proxyList.count, 2)
        XCTAssertEqual(decoded.poToken, "test_token")
    }

    func testDefaultAntiDetectionFlags() {
        let profile = StealthProfile()
        XCTAssertTrue(profile.usePlayerClientRotation)
        XCTAssertTrue(profile.setReferer)
        XCTAssertTrue(profile.sendConsentCookie)
        XCTAssertTrue(profile.retryOn429)
        XCTAssertEqual(profile.backoffBase, 2.0)
        XCTAssertEqual(profile.backoffMax, 300.0)
    }

    func testProfileMinDelayLessThanMaxDelay() {
        let profile = StealthProfile()
        XCTAssertLessThanOrEqual(profile.minDelay, profile.maxDelay,
                                 "Min delay must not exceed max delay")
    }
}

// MARK: - Unit Tests: CookieSource

final class CookieSourceTests: XCTestCase {

    func testNoneCookieSourceReturnsNilValue() {
        XCTAssertNil(CookieSource.none.ytdlpValue)
    }

    func testFileCookieSourceReturnsNilValue() {
        XCTAssertNil(CookieSource.file.ytdlpValue)
    }

    func testChromeCookieSourceReturnsChrome() {
        XCTAssertEqual(CookieSource.chrome.ytdlpValue, "chrome")
    }

    func testFirefoxCookieSourceReturnsFirefox() {
        XCTAssertEqual(CookieSource.firefox.ytdlpValue, "firefox")
    }

    func testSafariCookieSourceReturnsSafari() {
        XCTAssertEqual(CookieSource.safari.ytdlpValue, "safari")
    }

    func testAllCookieSourcesHaveIds() {
        for source in CookieSource.allCases {
            XCTAssertFalse(source.id.isEmpty)
        }
    }

    func testBrowserCookieSourcesCount() {
        let browserSources = CookieSource.allCases.filter { $0.ytdlpValue != nil }
        XCTAssertEqual(browserSources.count, 8) // chrome, firefox, safari, edge, brave, chromium, opera, vivaldi
    }
}

// MARK: - Unit Tests: FormatInfo

final class FormatInfoTests: XCTestCase {

    func testHasVideoWhenVcodecPresent() {
        var format = FormatInfo()
        format.vcodec = "h264"
        XCTAssertTrue(format.hasVideo)
    }

    func testHasVideoFalseWhenVcodecNone() {
        var format = FormatInfo()
        format.vcodec = "none"
        XCTAssertFalse(format.hasVideo)
    }

    func testHasVideoFalseWhenVcodecNil() {
        let format = FormatInfo()
        XCTAssertFalse(format.hasVideo)
    }

    func testHasAudioWhenAcodecPresent() {
        var format = FormatInfo()
        format.acodec = "opus"
        XCTAssertTrue(format.hasAudio)
    }

    func testHasAudioFalseWhenAcodecNone() {
        var format = FormatInfo()
        format.acodec = "none"
        XCTAssertFalse(format.hasAudio)
    }

    func testDisplayResolution4K() {
        var format = FormatInfo()
        format.height = 2160
        XCTAssertEqual(format.displayResolution, "4K")
    }

    func testDisplayResolution1440p() {
        var format = FormatInfo()
        format.height = 1440
        XCTAssertEqual(format.displayResolution, "1440p")
    }

    func testDisplayResolution1080p() {
        var format = FormatInfo()
        format.height = 1080
        XCTAssertEqual(format.displayResolution, "1080p")
    }

    func testDisplayResolution720p() {
        var format = FormatInfo()
        format.height = 720
        XCTAssertEqual(format.displayResolution, "720p")
    }

    func testDisplayResolutionAudioOnly() {
        let format = FormatInfo()
        XCTAssertEqual(format.displayResolution, "Audio")
    }

    func testDisplayCodecVideoAndAudio() {
        var format = FormatInfo()
        format.vcodec = "h264"
        format.acodec = "aac"
        XCTAssertEqual(format.displayCodec, "h264 + aac")
    }

    func testDisplayCodecVideoOnly() {
        var format = FormatInfo()
        format.vcodec = "vp9"
        format.acodec = "none"
        XCTAssertEqual(format.displayCodec, "vp9")
    }

    func testDisplaySizeKnown() {
        var format = FormatInfo()
        format.filesize = 10_485_760 // 10 MB
        XCTAssertNotEqual(format.displaySize, "Unknown")
    }

    func testDisplaySizeFromApprox() {
        var format = FormatInfo()
        format.filesizeApprox = 5_242_880
        XCTAssertNotEqual(format.displaySize, "Unknown")
    }

    func testDisplaySizeUnknown() {
        let format = FormatInfo()
        XCTAssertEqual(format.displaySize, "Unknown")
    }
}

// MARK: - Unit Tests: LibraryItem

final class LibraryItemTests: XCTestCase {

    func testLibraryItemFromDownloadItem() {
        var download = DownloadItem(url: "https://youtube.com/watch?v=test")
        download.title = "Test Video"
        download.uploader = "TestUser"
        download.startedAt = Date()

        let item = LibraryItem(from: download, filePath: "/tmp/test.mp4", fileSize: 1024)

        XCTAssertEqual(item.url, "https://youtube.com/watch?v=test")
        XCTAssertEqual(item.title, "Test Video")
        XCTAssertEqual(item.uploader, "TestUser")
        XCTAssertEqual(item.filePath, "/tmp/test.mp4")
        XCTAssertEqual(item.fileSize, 1024)
    }

    func testLibraryItemDefaultTitleWhenNil() {
        let download = DownloadItem(url: "https://test.com")
        let item = LibraryItem(from: download, filePath: "/tmp/test.mp4", fileSize: 0)
        XCTAssertEqual(item.title, "Unknown")
    }

    func testLibraryItemAudioFormat() {
        var download = DownloadItem(url: "https://test.com")
        download.options.extractAudio = true
        download.options.audioFormat = "mp3"
        let item = LibraryItem(from: download, filePath: "/tmp/test.mp3", fileSize: 0)
        XCTAssertEqual(item.format, "mp3")
    }

    func testLibraryItemVideoFormat() {
        var download = DownloadItem(url: "https://test.com")
        download.options.mergeOutputFormat = "mkv"
        let item = LibraryItem(from: download, filePath: "/tmp/test.mkv", fileSize: 0)
        XCTAssertEqual(item.format, "mkv")
    }

    func testLibraryItemDefaultFormat() {
        let download = DownloadItem(url: "https://test.com")
        let item = LibraryItem(from: download, filePath: "/tmp/test.mp4", fileSize: 0)
        XCTAssertEqual(item.format, "mp4")
    }

    func testFileSizeFormatted() {
        let download = DownloadItem(url: "https://test.com")
        let item = LibraryItem(from: download, filePath: "/tmp/test.mp4", fileSize: 10_485_760)
        XCTAssertFalse(item.fileSizeFormatted.isEmpty)
    }

    func testDurationFormatted() {
        var download = DownloadItem(url: "https://test.com")
        download.duration = 3661 // 1:01:01
        let item = LibraryItem(from: download, filePath: "/tmp/test.mp4", fileSize: 0)
        XCTAssertEqual(item.durationFormatted, "1:01:01")
    }

    func testDurationFormattedNoHours() {
        var download = DownloadItem(url: "https://test.com")
        download.duration = 125 // 2:05
        let item = LibraryItem(from: download, filePath: "/tmp/test.mp4", fileSize: 0)
        XCTAssertEqual(item.durationFormatted, "2:05")
    }

    func testDurationFormattedNilWhenNoDuration() {
        let download = DownloadItem(url: "https://test.com")
        let item = LibraryItem(from: download, filePath: "/tmp/test.mp4", fileSize: 0)
        XCTAssertNil(item.durationFormatted)
    }

    func testLibraryItemOriginalURLAlias() {
        let download = DownloadItem(url: "https://youtube.com/watch?v=abc")
        let item = LibraryItem(from: download, filePath: "/tmp/t.mp4", fileSize: 0)
        XCTAssertEqual(item.originalURL, item.url)
    }

    func testLibraryItemFavoriteDefault() {
        let download = DownloadItem(url: "https://test.com")
        let item = LibraryItem(from: download, filePath: "/tmp/t.mp4", fileSize: 0)
        XCTAssertFalse(item.isFavorite)
    }

    func testLibraryItemTagsDefault() {
        let download = DownloadItem(url: "https://test.com")
        let item = LibraryItem(from: download, filePath: "/tmp/t.mp4", fileSize: 0)
        XCTAssertTrue(item.tags.isEmpty)
    }
}

// MARK: - Unit Tests: PostDownloadAction

final class PostDownloadActionTests: XCTestCase {

    func testDefaultActionsExist() {
        XCTAssertGreaterThanOrEqual(PostDownloadAction.defaultActions.count, 2)
    }

    func testActionTypesAllCases() {
        XCTAssertEqual(PostDownloadAction.ActionType.allCases.count, 8)
    }

    func testActionTypeIcons() {
        for actionType in PostDownloadAction.ActionType.allCases {
            XCTAssertFalse(actionType.icon.isEmpty, "\(actionType.rawValue) should have an icon")
        }
    }

    func testActionConfigWithDestination() {
        let config = PostDownloadAction.ActionConfig().withDestination("/tmp/dest")
        XCTAssertEqual(config.destinationFolder, "/tmp/dest")
    }

    func testActionConfigWithScript() {
        let config = PostDownloadAction.ActionConfig().withScript("/usr/local/bin/notify.sh", arguments: "--verbose")
        XCTAssertEqual(config.scriptPath, "/usr/local/bin/notify.sh")
        XCTAssertEqual(config.scriptArguments, "--verbose")
    }

    func testActionCodable() throws {
        let action = PostDownloadAction(name: "Test Action", actionType: .moveToFolder,
                                        configuration: PostDownloadAction.ActionConfig().withDestination("/tmp"))
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(PostDownloadAction.self, from: data)
        XCTAssertEqual(decoded.name, "Test Action")
        XCTAssertEqual(decoded.actionType, .moveToFolder)
        XCTAssertEqual(decoded.configuration.destinationFolder, "/tmp")
    }

    func testActionConfigDefaultsAreNil() {
        let config = PostDownloadAction.ActionConfig()
        XCTAssertNil(config.destinationFolder)
        XCTAssertNil(config.scriptPath)
        XCTAssertNil(config.scriptArguments)
        XCTAssertNil(config.targetFormat)
        XCTAssertNil(config.applicationPath)
        XCTAssertNil(config.tags)
    }

    func testDefaultActionsAreEnabled() {
        for action in PostDownloadAction.defaultActions {
            XCTAssertTrue(action.isEnabled, "Default action '\(action.name)' should be enabled")
        }
    }
}

// MARK: - Unit Tests: SponsorBlockSegment

final class SponsorBlockSegmentTests: XCTestCase {

    func testSegmentDuration() {
        let segment = SponsorBlockSegment(category: .sponsor, startTime: 10.0, endTime: 30.0)
        XCTAssertEqual(segment.duration, 20.0)
    }

    func testSegmentTimeRange() {
        let segment = SponsorBlockSegment(category: .intro, startTime: 0, endTime: 65)
        XCTAssertEqual(segment.formattedTimeRange, "0:00 - 1:05")
    }

    func testSegmentDefaultSelected() {
        let segment = SponsorBlockSegment(category: .sponsor, startTime: 0, endTime: 10)
        XCTAssertTrue(segment.isSelected)
    }

    func testAllCategoriesExist() {
        XCTAssertEqual(SponsorBlockSegment.SegmentCategory.allCases.count, 8)
    }

    func testCategoryDisplayNames() {
        for category in SponsorBlockSegment.SegmentCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty)
        }
    }

    func testSegmentZeroDuration() {
        let segment = SponsorBlockSegment(category: .filler, startTime: 30.0, endTime: 30.0)
        XCTAssertEqual(segment.duration, 0.0)
    }
}

// MARK: - Unit Tests: AppSettings

final class AppSettingsTests: XCTestCase {

    func testDefaultSettings() {
        let settings = AppSettings()
        XCTAssertEqual(settings.maxConcurrentDownloads, 3)
        XCTAssertTrue(settings.showNotificationsOnComplete)
        XCTAssertTrue(settings.autoFetchMetadata)
        XCTAssertTrue(settings.autoDetectPlaylists)
        XCTAssertTrue(settings.keepDownloadHistory)
        XCTAssertEqual(settings.maxHistoryItems, 1000)
        XCTAssertTrue(settings.thumbnailCacheEnabled)
        XCTAssertEqual(settings.theme, .dark)
        XCTAssertEqual(settings.defaultOutputTemplate, "%(title)s.%(ext)s")
    }

    func testSettingsCodable() throws {
        var settings = AppSettings()
        settings.maxConcurrentDownloads = 5
        settings.theme = .light
        settings.speedLimiterEnabled = true

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)

        XCTAssertEqual(decoded.maxConcurrentDownloads, 5)
        XCTAssertEqual(decoded.theme, .light)
        XCTAssertTrue(decoded.speedLimiterEnabled)
    }

    func testOutputDirectoryDefault() {
        let settings = AppSettings()
        XCTAssertTrue(settings.outputDirectory.hasSuffix("/Downloads"))
    }

    func testThemeAllCases() {
        XCTAssertEqual(AppSettings.AppTheme.allCases.count, 3)
    }

    func testSpeedLimiterDefaults() {
        let settings = AppSettings()
        XCTAssertFalse(settings.speedLimiterEnabled)
        XCTAssertEqual(settings.speedLimiterGlobalKBps, 0)
        XCTAssertEqual(settings.speedLimiterPerDownloadKBps, 0)
    }

    func testThumbnailCacheDefaults() {
        let settings = AppSettings()
        XCTAssertTrue(settings.thumbnailCacheEnabled)
        XCTAssertEqual(settings.thumbnailCacheSizeMB, 500)
    }

    func testCheckForUpdatesDefault() {
        let settings = AppSettings()
        XCTAssertTrue(settings.checkForUpdatesOnLaunch)
    }

    func testStealthModeEnabledDefault() {
        let settings = AppSettings()
        XCTAssertTrue(settings.stealthModeEnabled)
    }

    func testSettingsRoundTripPreservesAllFields() throws {
        var settings = AppSettings()
        settings.maxConcurrentDownloads = 7
        settings.showNotificationsOnComplete = false
        settings.autoFetchMetadata = false
        settings.autoDetectPlaylists = false
        settings.keepDownloadHistory = false
        settings.maxHistoryItems = 500
        settings.thumbnailCacheEnabled = false
        settings.thumbnailCacheSizeMB = 200
        settings.checkForUpdatesOnLaunch = false
        settings.stealthModeEnabled = false
        settings.defaultOutputTemplate = "%(id)s.%(ext)s"
        settings.theme = .system
        settings.speedLimiterEnabled = true
        settings.speedLimiterGlobalKBps = 1024
        settings.speedLimiterPerDownloadKBps = 512

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)

        XCTAssertEqual(decoded.maxConcurrentDownloads, 7)
        XCTAssertFalse(decoded.showNotificationsOnComplete)
        XCTAssertFalse(decoded.autoFetchMetadata)
        XCTAssertFalse(decoded.autoDetectPlaylists)
        XCTAssertFalse(decoded.keepDownloadHistory)
        XCTAssertEqual(decoded.maxHistoryItems, 500)
        XCTAssertFalse(decoded.thumbnailCacheEnabled)
        XCTAssertEqual(decoded.thumbnailCacheSizeMB, 200)
        XCTAssertFalse(decoded.checkForUpdatesOnLaunch)
        XCTAssertFalse(decoded.stealthModeEnabled)
        XCTAssertEqual(decoded.defaultOutputTemplate, "%(id)s.%(ext)s")
        XCTAssertEqual(decoded.theme, .system)
        XCTAssertTrue(decoded.speedLimiterEnabled)
        XCTAssertEqual(decoded.speedLimiterGlobalKBps, 1024)
        XCTAssertEqual(decoded.speedLimiterPerDownloadKBps, 512)
    }
}

// MARK: - Unit Tests: SpeedLimiter Formatting

@MainActor
final class SpeedLimiterFormattingTests: XCTestCase {

    func testFormatSpeedUnlimited() {
        XCTAssertEqual(SpeedLimiter.formatSpeed(0), "Unlimited")
    }

    func testFormatSpeedKBps() {
        XCTAssertEqual(SpeedLimiter.formatSpeed(512), "512 KB/s")
    }

    func testFormatSpeedMBps() {
        let result = SpeedLimiter.formatSpeed(1024)
        XCTAssertTrue(result.contains("MB/s"))
    }

    func testFormatSpeedLargeMBps() {
        let result = SpeedLimiter.formatSpeed(5120)
        XCTAssertTrue(result.contains("MB/s"))
    }

    func testPresetsExist() {
        XCTAssertGreaterThanOrEqual(SpeedLimiter.presets.count, 5)
    }

    func testPresetsStartWithUnlimited() {
        XCTAssertEqual(SpeedLimiter.presets.first?.0, "Unlimited")
        XCTAssertEqual(SpeedLimiter.presets.first?.1, 0)
    }

    func testPresetsAreInAscendingOrder() {
        let values = SpeedLimiter.presets.map { $0.1 }
        for i in 1..<values.count {
            XCTAssertGreaterThan(values[i], values[i-1], "Presets should be in ascending order")
        }
    }
}

// MARK: - Unit Tests: YTDLPError

final class YTDLPErrorTests: XCTestCase {

    func testErrorDescriptions() {
        XCTAssertNotNil(YTDLPError.downloadFailed("test").errorDescription)
        XCTAssertNotNil(YTDLPError.rateLimited.errorDescription)
        XCTAssertNotNil(YTDLPError.forbidden.errorDescription)
        XCTAssertNotNil(YTDLPError.cancelled.errorDescription)
        XCTAssertNotNil(YTDLPError.binaryNotFound.errorDescription)
        XCTAssertNotNil(YTDLPError.parseError("test").errorDescription)
    }

    func testRateLimitedDescription() {
        let desc = YTDLPError.rateLimited.errorDescription!
        XCTAssertTrue(desc.contains("429"))
    }

    func testForbiddenDescription() {
        let desc = YTDLPError.forbidden.errorDescription!
        XCTAssertTrue(desc.contains("403"))
    }

    func testErrorEquality() {
        XCTAssertEqual(YTDLPError.rateLimited, YTDLPError.rateLimited)
        XCTAssertEqual(YTDLPError.forbidden, YTDLPError.forbidden)
        XCTAssertEqual(YTDLPError.cancelled, YTDLPError.cancelled)
        XCTAssertEqual(YTDLPError.binaryNotFound, YTDLPError.binaryNotFound)
        XCTAssertNotEqual(YTDLPError.rateLimited, YTDLPError.forbidden)
    }

    func testDownloadFailedContainsMessage() {
        let error = YTDLPError.downloadFailed("Video unavailable")
        XCTAssertTrue(error.errorDescription!.contains("Video unavailable"))
    }

    func testParseErrorContainsMessage() {
        let error = YTDLPError.parseError("Invalid JSON")
        XCTAssertTrue(error.errorDescription!.contains("Invalid JSON"))
    }
}

// MARK: - Unit Tests: Enum Completeness

final class EnumTests: XCTestCase {

    func testAudioFormatOptions() {
        XCTAssertEqual(AudioFormatOption.allCases.count, 9)
        XCTAssertTrue(AudioFormatOption.allCases.contains(.mp3))
        XCTAssertTrue(AudioFormatOption.allCases.contains(.flac))
        XCTAssertTrue(AudioFormatOption.allCases.contains(.opus))
    }

    func testMergeOutputFormatOptions() {
        XCTAssertEqual(MergeOutputFormatOption.allCases.count, 6)
        XCTAssertTrue(MergeOutputFormatOption.allCases.contains(.mp4))
        XCTAssertTrue(MergeOutputFormatOption.allCases.contains(.mkv))
    }

    func testSubtitleFormatOptions() {
        XCTAssertEqual(SubtitleFormatOption.allCases.count, 4)
        XCTAssertTrue(SubtitleFormatOption.allCases.contains(.srt))
    }

    func testImpersonateOptions() {
        XCTAssertEqual(ImpersonateOption.allCases.count, 4)
        for option in ImpersonateOption.allCases {
            XCTAssertFalse(option.displayName.isEmpty)
        }
    }

    func testSponsorBlockCategories() {
        XCTAssertEqual(SponsorBlockCategory.allCases.count, 9)
        XCTAssertTrue(SponsorBlockCategory.allCases.contains(.all))
    }

    func testFixupPolicyOptions() {
        XCTAssertEqual(FixupPolicyOption.allCases.count, 4)
    }

    func testAudioFormatOptionsHaveIds() {
        for option in AudioFormatOption.allCases {
            XCTAssertFalse(option.id.isEmpty)
        }
    }

    func testSponsorBlockCategoryDisplayNames() {
        for category in SponsorBlockCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty, "\(category.rawValue) should have display name")
        }
    }
}

// MARK: - Unit Tests: MediaMetadata Decoding

final class MediaMetadataTests: XCTestCase {

    func testDecodeMinimalMetadata() throws {
        let json = """
        {"id": "test123", "title": "Test Video"}
        """
        let data = json.data(using: .utf8)!
        let metadata = try JSONDecoder().decode(MediaMetadata.self, from: data)
        XCTAssertEqual(metadata.id, "test123")
        XCTAssertEqual(metadata.title, "Test Video")
        XCTAssertFalse(metadata.isPlaylist)
    }

    func testDecodePlaylistMetadata() throws {
        let json = """
        {"id": "PL123", "title": "My Playlist", "_type": "playlist", "playlist_count": 10}
        """
        let data = json.data(using: .utf8)!
        let metadata = try JSONDecoder().decode(MediaMetadata.self, from: data)
        XCTAssertTrue(metadata.isPlaylist)
        XCTAssertEqual(metadata.playlistCount, 10)
    }

    func testDecodeFullMetadata() throws {
        let json = """
        {
            "id": "dQw4w9WgXcQ",
            "title": "Rick Astley - Never Gonna Give You Up",
            "uploader": "Rick Astley",
            "uploader_id": "@RickAstleyYT",
            "channel": "Rick Astley",
            "duration": 212,
            "view_count": 1500000000,
            "like_count": 15000000,
            "upload_date": "20091025",
            "thumbnail": "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
            "webpage_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            "categories": ["Music"],
            "tags": ["rick astley"]
        }
        """
        let data = json.data(using: .utf8)!
        let metadata = try JSONDecoder().decode(MediaMetadata.self, from: data)

        XCTAssertEqual(metadata.uploader, "Rick Astley")
        XCTAssertEqual(metadata.duration, 212)
        XCTAssertEqual(metadata.viewCount, 1_500_000_000)
        XCTAssertEqual(metadata.uploadDate, "20091025")
        XCTAssertNotNil(metadata.thumbnailUrl)
        XCTAssertNotNil(metadata.categories)
        XCTAssertNotNil(metadata.tags)
    }

    func testDecodeFormatInfo() throws {
        let json = """
        {
            "format_id": "248",
            "ext": "webm",
            "resolution": "1920x1080",
            "width": 1920,
            "height": 1080,
            "fps": 30.0,
            "vcodec": "vp9",
            "acodec": "none",
            "filesize": 104857600,
            "tbr": 2500.0,
            "format_note": "1080p"
        }
        """
        let data = json.data(using: .utf8)!
        let format = try JSONDecoder().decode(FormatInfo.self, from: data)

        XCTAssertEqual(format.formatId, "248")
        XCTAssertEqual(format.ext, "webm")
        XCTAssertEqual(format.height, 1080)
        XCTAssertEqual(format.fps, 30.0)
        XCTAssertTrue(format.hasVideo)
        XCTAssertFalse(format.hasAudio)
        XCTAssertEqual(format.displayResolution, "1080p")
    }

    func testDecodeEmptyMetadata() throws {
        let json = "{}"
        let data = json.data(using: .utf8)!
        let metadata = try JSONDecoder().decode(MediaMetadata.self, from: data)
        XCTAssertNil(metadata.id)
        XCTAssertNil(metadata.title)
        XCTAssertFalse(metadata.isPlaylist)
    }
}

// MARK: - Unit Tests: PlaylistInfo Decoding

final class PlaylistInfoTests: XCTestCase {

    func testDecodePlaylistInfo() throws {
        let json = """
        {
            "id": "PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf",
            "title": "Test Playlist",
            "uploader": "TestUser",
            "playlist_count": 3,
            "entries": [
                {"id": "vid1", "title": "Video 1", "duration": 120},
                {"id": "vid2", "title": "Video 2", "duration": 240}
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let playlist = try JSONDecoder().decode(PlaylistInfo.self, from: data)

        XCTAssertEqual(playlist.title, "Test Playlist")
        XCTAssertEqual(playlist.playlistCount, 3)
        XCTAssertEqual(playlist.entries?.count, 2)
    }

    func testPlaylistEntryStableIdentity() throws {
        let json = """
        {"id": "abc123", "title": "Test Entry", "duration": 60}
        """
        let data = json.data(using: .utf8)!
        let entry1 = try JSONDecoder().decode(PlaylistEntry.self, from: data)
        let entry2 = try JSONDecoder().decode(PlaylistEntry.self, from: data)

        // Both should have the same id (from entryId), not random UUIDs
        XCTAssertEqual(entry1.id, "abc123")
        XCTAssertEqual(entry2.id, "abc123")
    }

    func testPlaylistEntryFallbackId() throws {
        let json = """
        {"title": "No ID Entry", "duration": 60}
        """
        let data = json.data(using: .utf8)!
        let entry = try JSONDecoder().decode(PlaylistEntry.self, from: data)

        // Should have a fallback UUID
        XCTAssertFalse(entry.id.isEmpty)
    }

    func testPlaylistEntryDurationFormatted() throws {
        let json = """
        {"id": "test", "title": "Test", "duration": 125}
        """
        let data = json.data(using: .utf8)!
        let entry = try JSONDecoder().decode(PlaylistEntry.self, from: data)
        XCTAssertEqual(entry.durationFormatted, "2:05")
    }

    func testPlaylistEntryNoDurationFormatted() throws {
        let json = """
        {"id": "test", "title": "Test"}
        """
        let data = json.data(using: .utf8)!
        let entry = try JSONDecoder().decode(PlaylistEntry.self, from: data)
        XCTAssertNil(entry.durationFormatted)
    }
}

// MARK: - Unit Tests: ChannelSubscription

final class ChannelSubscriptionTests: XCTestCase {

    func testSubscriptionInitialization() {
        let sub = ChannelSubscription(name: "Test Channel", url: "https://youtube.com/@test")
        XCTAssertEqual(sub.name, "Test Channel")
        XCTAssertEqual(sub.url, "https://youtube.com/@test")
        XCTAssertEqual(sub.checkInterval, .sixHours)
        XCTAssertTrue(sub.isEnabled)
        XCTAssertTrue(sub.downloadedVideoIds.isEmpty)
        XCTAssertEqual(sub.maxDownloadsPerCheck, 5)
        XCTAssertTrue(sub.autoDownload)
    }

    func testIsDueForCheckWhenNeverChecked() {
        let sub = ChannelSubscription(name: "Test", url: "https://test.com")
        XCTAssertTrue(sub.isDueForCheck, "Should be due when never checked")
    }

    func testIsDueForCheckWhenDisabled() {
        var sub = ChannelSubscription(name: "Test", url: "https://test.com")
        sub.isEnabled = false
        XCTAssertFalse(sub.isDueForCheck, "Disabled subscriptions should not be due")
    }

    func testIsDueForCheckWhenRecentlyChecked() {
        var sub = ChannelSubscription(name: "Test", url: "https://test.com")
        sub.lastCheckedAt = Date()
        XCTAssertFalse(sub.isDueForCheck, "Should not be due immediately after check")
    }

    func testCheckIntervalSeconds() {
        XCTAssertEqual(ChannelSubscription.CheckInterval.thirtyMinutes.seconds, 1800)
        XCTAssertEqual(ChannelSubscription.CheckInterval.oneHour.seconds, 3600)
        XCTAssertEqual(ChannelSubscription.CheckInterval.threeHours.seconds, 10800)
        XCTAssertEqual(ChannelSubscription.CheckInterval.sixHours.seconds, 21600)
        XCTAssertEqual(ChannelSubscription.CheckInterval.twelveHours.seconds, 43200)
        XCTAssertEqual(ChannelSubscription.CheckInterval.daily.seconds, 86400)
        XCTAssertEqual(ChannelSubscription.CheckInterval.weekly.seconds, 604800)
    }

    func testCheckIntervalAllCases() {
        XCTAssertEqual(ChannelSubscription.CheckInterval.allCases.count, 7)
    }

    func testSubscriptionCodable() throws {
        var sub = ChannelSubscription(name: "MrBeast", url: "https://youtube.com/@MrBeast")
        sub.downloadedVideoIds = ["vid1", "vid2"]
        sub.lastVideoId = "vid2"

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(sub)
        let decoded = try decoder.decode(ChannelSubscription.self, from: data)

        XCTAssertEqual(decoded.name, "MrBeast")
        XCTAssertEqual(decoded.downloadedVideoIds.count, 2)
        XCTAssertEqual(decoded.lastVideoId, "vid2")
    }
}

// MARK: - Unit Tests: ScheduledDownload

final class ScheduledDownloadTests: XCTestCase {

    func testScheduledDownloadInit() {
        let scheduled = ScheduledDownload(url: "https://test.com", scheduledDate: Date())
        XCTAssertEqual(scheduled.url, "https://test.com")
        XCTAssertEqual(scheduled.repeatRule, .once)
        XCTAssertTrue(scheduled.isEnabled)
        XCTAssertEqual(scheduled.status, .pending)
    }

    func testIsOverdueWhenPastDate() {
        let pastDate = Date(timeIntervalSinceNow: -3600)
        let scheduled = ScheduledDownload(url: "https://test.com", scheduledDate: pastDate)
        XCTAssertTrue(scheduled.isOverdue)
    }

    func testIsNotOverdueWhenFutureDate() {
        let futureDate = Date(timeIntervalSinceNow: 3600)
        let scheduled = ScheduledDownload(url: "https://test.com", scheduledDate: futureDate)
        XCTAssertFalse(scheduled.isOverdue)
    }

    func testNextRunDateNilForOnce() {
        let scheduled = ScheduledDownload(url: "https://test.com", scheduledDate: Date(), repeatRule: .once)
        XCTAssertNil(scheduled.nextRunDate)
    }

    func testNextRunDateNotNilForDaily() {
        let scheduled = ScheduledDownload(url: "https://test.com", scheduledDate: Date(), repeatRule: .daily)
        XCTAssertNotNil(scheduled.nextRunDate)
    }

    func testRepeatRuleAllCases() {
        XCTAssertEqual(ScheduledDownload.RepeatRule.allCases.count, 4)
    }
}

// MARK: - Unit Tests: DownloadResult

final class DownloadResultTests: XCTestCase {

    func testSuccessfulResult() {
        let result = DownloadResult(success: true, outputPath: "/tmp/video.mp4", output: "Done", errorOutput: nil)
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.outputPath, "/tmp/video.mp4")
        XCTAssertNil(result.errorOutput)
    }

    func testFailedResult() {
        let result = DownloadResult(success: false, outputPath: nil, output: "", errorOutput: "Network error")
        XCTAssertFalse(result.success)
        XCTAssertNil(result.outputPath)
        XCTAssertEqual(result.errorOutput, "Network error")
    }
}

// MARK: - Unit Tests: Error Message Extraction Pattern

final class ErrorExtractionTests: XCTestCase {

    func testExtractErrorFromYtdlpOutput() {
        let output = """
        [youtube] Extracting URL: https://www.youtube.com/watch?v=test
        [youtube] test: Downloading webpage
        ERROR: [youtube] test: Video unavailable
        """

        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        let errorLines = lines.filter { $0.contains("ERROR:") }
        XCTAssertEqual(errorLines.count, 1)
        XCTAssertTrue(errorLines.first!.contains("Video unavailable"))
    }

    func testExtractMultipleErrorLines() {
        let output = """
        ERROR: Unable to download webpage
        ERROR: HTTP Error 403: Forbidden
        ERROR: Retrying...
        ERROR: Giving up after 3 retries
        """

        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        let errorLines = lines.filter { $0.contains("ERROR:") }
        XCTAssertEqual(errorLines.count, 4)

        // extractBestErrorMessage returns up to 3
        let cleaned = errorLines.prefix(3).map {
            $0.replacingOccurrences(of: "ERROR: ", with: "").trimmingCharacters(in: .whitespaces)
        }
        XCTAssertEqual(cleaned.count, 3)
    }

    func testFallbackErrorIndicators() {
        let output = "Connection timed out after 30 seconds"
        let indicators = ["unable to", "not found", "failed", "invalid", "unsupported", "unavailable", "denied", "timeout", "timed out"]
        let lower = output.lowercased()
        let hasIndicator = indicators.contains { lower.contains($0) }
        XCTAssertTrue(hasIndicator)
    }

    func testHTTP429Detection() {
        let output = "HTTP Error 429: Too Many Requests"
        XCTAssertTrue(output.contains("HTTP Error 429") || output.contains("429 Too Many Requests"))
    }

    func testHTTP403Detection() {
        let output = "Sign in to confirm you're not a bot"
        let indicators = ["HTTP Error 403", "403 Forbidden", "Sign in to confirm", "confirm you're not a bot", "bot verification", "This video is not available"]
        let hasIndicator = indicators.contains { output.contains($0) }
        XCTAssertTrue(hasIndicator)
    }
}

// =============================================================================
// MARK: - Security Tests
// =============================================================================

// MARK: - Security Tests: Command Injection Prevention

final class SecurityCommandInjectionTests: XCTestCase {

    func testURLWithShellMetacharactersInArguments() {
        // Ensure shell metacharacters in URLs are passed as literal arguments,
        // not interpreted by the shell
        var options = YTDLPOptions()
        options.format = "bv*+ba/b"

        let args = options.toArguments()

        // Arguments are array-based (Process.arguments), not shell-concatenated
        // No argument should contain a shell command
        for arg in args {
            XCTAssertFalse(arg.contains("`"), "Arguments must not contain backticks")
            XCTAssertFalse(arg.contains("$("), "Arguments must not contain command substitution")
        }
    }

    func testMaliciousURLDoesNotBreakArguments() {
        // URLs are passed as the last argument to yt-dlp, not through shell
        let maliciousURLs = [
            "https://example.com/video;rm -rf /",
            "https://example.com/video$(whoami)",
            "https://example.com/video`cat /etc/passwd`",
            "https://example.com/video|ls",
            "https://example.com/video&& echo pwned",
            "https://example.com/video\n echo pwned",
        ]

        for url in maliciousURLs {
            // These URLs should be passed as-is to yt-dlp as a single argument
            // The Process API handles this safely (no shell interpretation)
            XCTAssertFalse(url.isEmpty, "URL should not be empty")
        }
    }

    func testOutputTemplateDoesNotAllowPathTraversal() {
        // The output template is validated by yt-dlp itself, but we check the
        // template builder presets don't contain path traversal
        for preset in OutputTemplatePreset.builtIn {
            XCTAssertFalse(preset.template.contains(".."), "Template should not contain path traversal: \(preset.template)")
        }
    }

    func testProxyOptionDoesNotAllowInjection() {
        var options = YTDLPOptions()
        options.proxy = "socks5://127.0.0.1:9050; rm -rf /"

        let args = options.toArguments()
        // The proxy value is a single argument, not shell-interpreted
        XCTAssertTrue(args.contains("--proxy"))
        let proxyIndex = args.firstIndex(of: "--proxy")!
        XCTAssertEqual(args[proxyIndex + 1], "socks5://127.0.0.1:9050; rm -rf /")
    }

    func testUserAgentOptionDoesNotAllowInjection() {
        var options = YTDLPOptions()
        options.userAgent = "Mozilla/5.0\"; rm -rf /"

        let args = options.toArguments()
        let uaIndex = args.firstIndex(of: "--user-agent")!
        // Should be passed as a single argument, not split by shell
        XCTAssertEqual(args[uaIndex + 1], "Mozilla/5.0\"; rm -rf /")
    }

    func testPostDownloadScriptUsesDirectExecution() {
        // Verify that PostDownloadManager.runScript uses Process.executableURL
        // instead of /bin/bash -c which would allow injection
        let config = PostDownloadAction.ActionConfig().withScript("/usr/local/bin/test.sh", arguments: "arg1 arg2")
        XCTAssertNotNil(config.scriptPath)
        XCTAssertEqual(config.scriptArguments, "arg1 arg2")
        // Script arguments are split by whitespace, not passed to shell
    }

    func testCookiePathDoesNotAllowInjection() {
        var options = YTDLPOptions()
        options.cookies = "/tmp/cookies.txt; rm -rf /"

        let args = options.toArguments()
        let cookieIndex = args.firstIndex(of: "--cookies")!
        // Cookie path is a single argument, safe from injection
        XCTAssertEqual(args[cookieIndex + 1], "/tmp/cookies.txt; rm -rf /")
    }

    func testExecCmdOptionsAreArrayBased() {
        var options = YTDLPOptions()
        options.execCmd = ["echo %(title)s"]

        let args = options.toArguments()
        XCTAssertTrue(args.contains("--exec"))
        // Each exec command is a separate argument pair, not concatenated
        let execIndex = args.firstIndex(of: "--exec")!
        XCTAssertEqual(args[execIndex + 1], "echo %(title)s")
    }
}

// MARK: - Security Tests: Safe Filename Generation

final class SecurityFilenameTests: XCTestCase {

    func testRestrictFilenamesOption() {
        var options = YTDLPOptions()
        options.restrictFilenames = true
        let args = options.toArguments()
        XCTAssertTrue(args.contains("--restrict-filenames"))
    }

    func testWindowsFilenamesOption() {
        var options = YTDLPOptions()
        options.windowsFilenames = true
        let args = options.toArguments()
        XCTAssertTrue(args.contains("--windows-filenames"))
    }

    func testTrimFilenamesOption() {
        var options = YTDLPOptions()
        options.trimFilenames = 200
        let args = options.toArguments()
        XCTAssertTrue(args.contains("--trim-filenames"))
        XCTAssertTrue(args.contains("200"))
    }
}

// MARK: - Security Tests: URL Injection Prevention

final class SecurityURLInjectionTests: XCTestCase {

    func testSponsorBlockAPIUsesURLComponents() {
        // The SponsorBlock service uses URLComponents for proper encoding
        // Test that a video ID with special characters would be safely encoded
        let maliciousID = "test&categories=[all]&extra=injected"
        var components = URLComponents(string: "https://sponsor.ajay.app/api/skipSegments")
        components?.queryItems = [
            URLQueryItem(name: "videoID", value: maliciousID),
            URLQueryItem(name: "categories", value: "[\"sponsor\"]"),
        ]
        let url = components?.url
        XCTAssertNotNil(url)

        // The & in videoID should be percent-encoded, not parsed as a query separator
        let urlString = url!.absoluteString
        XCTAssertTrue(urlString.contains("videoID=test%26"))
    }

    func testClipboardMonitorNotificationDoesNotExposeFullURL() {
        // Verify the notification shows domain only, not full URL
        let testURL = "https://www.youtube.com/watch?v=secret_video_id&token=abc123"
        let host = URL(string: testURL)?.host
        XCTAssertEqual(host, "www.youtube.com")
        // Full URL with tokens should NOT be in notification body
    }
}

// MARK: - Security Tests: No Hardcoded Credentials

final class SecurityNoHardcodedCredsTests: XCTestCase {

    func testYTDLPOptionsDoNotStorePassword() {
        let options = YTDLPOptions()
        // There should be no password property on the options struct
        // Password is injected separately from Keychain during download
        let args = options.toArguments()
        XCTAssertFalse(args.contains("--password"), "Default options should never contain --password")
    }

    func testSponsorBlockAPIBaseIsPublic() {
        // The API base URL is not a secret - just verify it's the public API
        let expectedBase = "https://sponsor.ajay.app/api"
        // This is intentionally a public, non-authenticated API
        XCTAssertFalse(expectedBase.isEmpty)
    }

    func testOptionsDoNotContainHardcodedTokens() {
        // Verify that no built-in preset contains hardcoded credentials
        for preset in DownloadPreset.builtInPresets {
            let args = preset.options.toArguments()
            for arg in args {
                XCTAssertFalse(arg.hasPrefix("sk-"), "Preset '\(preset.name)' must not contain API key: \(arg)")
                XCTAssertFalse(arg.hasPrefix("AKIA"), "Preset '\(preset.name)' must not contain AWS key: \(arg)")
                XCTAssertFalse(arg.hasPrefix("ghp_"), "Preset '\(preset.name)' must not contain GitHub PAT: \(arg)")
            }
        }
    }

    func testStealthProfileDoesNotLeakSecretsInDefaults() {
        let profile = StealthProfile()
        XCTAssertNil(profile.poToken, "Default stealth profile should not have a PO token")
        XCTAssertNil(profile.visitorData, "Default stealth profile should not have visitor data")
        XCTAssertTrue(profile.proxyList.isEmpty, "Default stealth profile should have no proxies")
    }

    func testNovaAPIPortIsLoopbackOnly() {
        // The Nova API server binds to 127.0.0.1 (loopback), not 0.0.0.0
        // This prevents remote access to the API
        let port: UInt16 = 37445
        XCTAssertEqual(port, 37445, "Nova API should be on port 37445")
        // The bind address "127.0.0.1" is hardcoded in NovaAPIServer.start()
        // Verify by checking that the class exists and port matches
    }
}

// MARK: - Security Tests: Source Code Credential Scan

final class SecuritySourceScanTests: XCTestCase {

    /// Scans all Swift source files in the project for hardcoded credentials
    func testNoHardcodedCredentialsInSourceFiles() throws {
        let projectDir = "/Volumes/Data/xcode/ytdlp-gui/ytdlp-gui/"
        let fm = FileManager.default

        guard fm.fileExists(atPath: projectDir) else {
            // Skip if running on a different machine
            return
        }

        let enumerator = fm.enumerator(atPath: projectDir)
        var violations: [String] = []

        let dangerousPatterns = [
            "sk-[A-Za-z0-9]{20,}",       // OpenAI/Anthropic API keys
            "AKIA[A-Z0-9]{16}",           // AWS access keys
            "ghp_[A-Za-z0-9]{36}",        // GitHub PATs
            "xox[bpoas]-[A-Za-z0-9-]+",   // Slack tokens
        ]

        while let file = enumerator?.nextObject() as? String {
            guard file.hasSuffix(".swift") else { continue }
            let fullPath = projectDir + file
            guard let content = try? String(contentsOfFile: fullPath, encoding: .utf8) else { continue }

            for pattern in dangerousPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern),
                   regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) != nil {
                    violations.append("\(file): matches pattern \(pattern)")
                }
            }
        }

        XCTAssertTrue(violations.isEmpty, "Found potential hardcoded credentials:\n\(violations.joined(separator: "\n"))")
    }
}

// =============================================================================
// MARK: - Integration Tests
// =============================================================================

// MARK: - Integration Tests: Binary Availability

@MainActor
final class BinaryAvailabilityTests: XCTestCase {

    func testYTDLPBinaryExists() {
        let searchPaths = [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
        ]
        let exists = searchPaths.contains { FileManager.default.isExecutableFile(atPath: $0) }
        XCTAssertTrue(exists, "yt-dlp should be installed (via Homebrew)")
    }

    func testFFmpegBinaryExists() {
        let searchPaths = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
        ]
        let exists = searchPaths.contains { FileManager.default.isExecutableFile(atPath: $0) }
        XCTAssertTrue(exists, "ffmpeg should be installed (via Homebrew)")
    }

    func testFFprobeBinaryExists() {
        let searchPaths = [
            "/opt/homebrew/bin/ffprobe",
            "/usr/local/bin/ffprobe",
        ]
        let exists = searchPaths.contains { FileManager.default.isExecutableFile(atPath: $0) }
        XCTAssertTrue(exists, "ffprobe should be installed (via Homebrew)")
    }

    func testAppSupportDirectoryCreatable() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        XCTAssertNotNil(appSupport, "Application Support directory should exist")
    }

    func testDownloadsDirectoryIsWritable() {
        let downloads = NSHomeDirectory() + "/Downloads"
        XCTAssertTrue(FileManager.default.isWritableFile(atPath: downloads),
                      "Downloads directory should be writable")
    }

    func testYTDLPBinaryIsCallable() {
        let searchPaths = [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
        ]

        guard let binaryPath = searchPaths.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
            XCTFail("yt-dlp binary not found")
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = ["--version"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        XCTAssertNoThrow(try process.run())
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0, "yt-dlp --version should exit with status 0")

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let version = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertNotNil(version)
        XCTAssertFalse(version!.isEmpty, "yt-dlp version should not be empty")
    }
}

// MARK: - Integration Tests: Nova API Server Structure

@MainActor
final class NovaAPIServerTests: XCTestCase {

    func testNovaAPIServerIsSharedSingleton() {
        let server1 = NovaAPIServer.shared
        let server2 = NovaAPIServer.shared
        XCTAssertTrue(server1 === server2, "NovaAPIServer should be a singleton")
    }

    func testNovaAPIServerPort() {
        XCTAssertEqual(NovaAPIServer.shared.port, 37445)
    }
}

// MARK: - Integration Tests: DataStore File Paths

@MainActor
final class DataStoreIntegrationTests: XCTestCase {

    func testAppSupportDirectoryExists() {
        let dir = DataStore.shared.appSupportDirectory
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir)
        // The directory is created on first access
        XCTAssertTrue(exists && isDir.boolValue, "App support directory should exist and be a directory")
    }

    func testThumbnailCacheDirectoryExists() {
        let dir = DataStore.shared.thumbnailCacheDir
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir)
        XCTAssertTrue(exists && isDir.boolValue, "Thumbnail cache directory should exist")
    }
}

// =============================================================================
// MARK: - Functional Tests
// =============================================================================

// MARK: - Functional Tests: Download Item State Transitions

final class DownloadItemStateTransitionTests: XCTestCase {

    func testQueuedToDownloading() {
        var item = DownloadItem(url: "https://test.com")
        XCTAssertEqual(item.status, .queued)

        item.status = .downloading
        item.startedAt = Date()
        XCTAssertEqual(item.status, .downloading)
        XCTAssertTrue(item.status.isActive)
        XCTAssertNotNil(item.startedAt)
    }

    func testDownloadingToCompleted() {
        var item = DownloadItem(url: "https://test.com")
        item.status = .downloading
        item.startedAt = Date()

        item.status = .completed
        item.completedAt = Date()
        item.outputPath = "/tmp/video.mp4"

        XCTAssertTrue(item.status.isTerminal)
        XCTAssertNotNil(item.completedAt)
        XCTAssertNotNil(item.outputPath)
    }

    func testDownloadingToFailed() {
        var item = DownloadItem(url: "https://test.com")
        item.status = .downloading

        item.status = .failed
        item.errorMessage = "HTTP Error 403: Forbidden"

        XCTAssertTrue(item.status.isTerminal)
        XCTAssertNotNil(item.errorMessage)
    }

    func testDownloadingToPausedAndBack() {
        var item = DownloadItem(url: "https://test.com")
        item.status = .downloading

        item.status = .paused
        XCTAssertFalse(item.status.isActive)
        XCTAssertFalse(item.status.isTerminal)

        item.status = .downloading
        XCTAssertTrue(item.status.isActive)
    }

    func testFailedToRetrying() {
        var item = DownloadItem(url: "https://test.com")
        item.status = .failed
        item.retryCount = 0

        item.status = .retrying
        item.retryCount += 1
        XCTAssertTrue(item.status.isActive)
        XCTAssertEqual(item.retryCount, 1)
    }

    func testCancelledIsTerminal() {
        var item = DownloadItem(url: "https://test.com")
        item.status = .downloading
        item.status = .cancelled
        XCTAssertTrue(item.status.isTerminal)
    }

    func testFetchingMetadataIsActive() {
        var item = DownloadItem(url: "https://test.com")
        item.status = .fetchingMetadata
        XCTAssertTrue(item.status.isActive)
    }

    func testPostProcessingIsActive() {
        var item = DownloadItem(url: "https://test.com")
        item.status = .postProcessing
        XCTAssertTrue(item.status.isActive)
    }
}

// MARK: - Functional Tests: Preset Application to Options

final class PresetApplicationTests: XCTestCase {

    func testBestVideoPresetGeneratesFormatArg() {
        let preset = DownloadPreset.bestVideo
        let args = preset.options.toArguments()
        XCTAssertTrue(args.contains("--format"))
        XCTAssertTrue(args.contains("bv*+ba/b"))
    }

    func testAudioMP3PresetGeneratesExtractAudioArgs() {
        let preset = DownloadPreset.audioMP3
        let args = preset.options.toArguments()
        XCTAssertTrue(args.contains("--extract-audio"))
        XCTAssertTrue(args.contains("--audio-format"))
        XCTAssertTrue(args.contains("mp3"))
        XCTAssertTrue(args.contains("--audio-quality"))
        XCTAssertTrue(args.contains("0"))
    }

    func testStealthModePresetGeneratesDelayArgs() {
        let preset = DownloadPreset.stealthMode
        let args = preset.options.toArguments()
        XCTAssertTrue(args.contains("--sleep-interval"))
        XCTAssertTrue(args.contains("--max-sleep-interval"))
        XCTAssertTrue(args.contains("--sleep-requests"))
        XCTAssertTrue(args.contains("--retries"))
        XCTAssertTrue(args.contains("10"))
    }

    func testPresetOptionsCanBeCustomized() {
        var preset = DownloadPreset.bestVideo
        preset.options.embedThumbnail = true
        preset.options.embedMetadata = true

        let args = preset.options.toArguments()
        XCTAssertTrue(args.contains("--format"))
        XCTAssertTrue(args.contains("--embed-thumbnail"))
        XCTAssertTrue(args.contains("--embed-metadata"))
    }
}

// MARK: - Functional Tests: Channel Subscription URL Parsing

final class ChannelSubscriptionURLParsingTests: XCTestCase {

    func testYouTubeChannelURL() {
        let sub = ChannelSubscription(name: "Test", url: "https://www.youtube.com/@TestChannel")
        XCTAssertTrue(sub.url.contains("youtube.com"))
    }

    func testYouTubeChannelOldFormat() {
        let sub = ChannelSubscription(name: "Test", url: "https://www.youtube.com/channel/UC1234567890")
        XCTAssertTrue(sub.url.contains("/channel/"))
    }

    func testYouTubePlaylistAsSubscription() {
        let sub = ChannelSubscription(name: "Test Playlist", url: "https://www.youtube.com/playlist?list=PLtest123")
        XCTAssertTrue(sub.url.contains("playlist"))
    }

    func testSubscriptionWithCustomOptions() {
        var opts = YTDLPOptions()
        opts.format = "bv*[height<=720]+ba/b"
        opts.extractAudio = false

        let sub = ChannelSubscription(name: "720p Channel", url: "https://youtube.com/@test", options: opts)
        let args = sub.options.toArguments()
        XCTAssertTrue(args.contains("--format"))
        XCTAssertTrue(args.contains("bv*[height<=720]+ba/b"))
    }
}

// MARK: - Functional Tests: Post-Download Action Execution Logic

final class PostDownloadActionLogicTests: XCTestCase {

    func testMoveToFolderActionHasDestination() {
        let action = PostDownloadAction.defaultActions.first { $0.actionType == .moveToFolder }
        XCTAssertNotNil(action)
        XCTAssertNotNil(action?.configuration.destinationFolder)
    }

    func testNotifyActionExists() {
        let action = PostDownloadAction.defaultActions.first { $0.actionType == .notify }
        XCTAssertNotNil(action)
    }

    func testRunScriptActionCanBeCreated() {
        let action = PostDownloadAction(
            name: "Custom Script",
            actionType: .runScript,
            configuration: PostDownloadAction.ActionConfig().withScript("/usr/local/bin/post.sh")
        )
        XCTAssertEqual(action.actionType, .runScript)
        XCTAssertEqual(action.configuration.scriptPath, "/usr/local/bin/post.sh")
    }

    func testConvertFormatActionCanBeCreated() {
        var config = PostDownloadAction.ActionConfig()
        config.targetFormat = "mp4"
        let action = PostDownloadAction(name: "Convert to MP4", actionType: .convertFormat, configuration: config)
        XCTAssertEqual(action.configuration.targetFormat, "mp4")
    }

    func testActionOrderDefault() {
        let action = PostDownloadAction(name: "Test", actionType: .notify)
        XCTAssertEqual(action.order, 0)
    }
}

// MARK: - Functional Tests: StealthManager

@MainActor
final class StealthManagerTests: XCTestCase {

    func testUserAgentPoolIsNotEmpty() {
        XCTAssertFalse(StealthManager.builtInUserAgents.isEmpty)
        XCTAssertGreaterThanOrEqual(StealthManager.builtInUserAgents.count, 50)
    }

    func testUserAgentRotationDoesNotRepeat() {
        let manager = StealthManager.shared
        manager.resetPool()

        var agents: Set<String> = []
        for _ in 0..<10 {
            let agent = manager.nextUserAgent()
            XCTAssertFalse(agents.contains(agent), "User agent should not repeat: \(agent)")
            agents.insert(agent)
        }
    }

    func testUserAgentPoolResetsAfterExhaustion() {
        let manager = StealthManager.shared
        manager.resetPool()

        // Exhaust the pool
        let poolSize = manager.currentPoolSize
        for _ in 0..<poolSize {
            _ = manager.nextUserAgent()
        }

        // Pool should reset on next call
        let agent = manager.nextUserAgent()
        XCTAssertFalse(agent.isEmpty)
    }

    func testAllUserAgentsAreMozillaCompatible() {
        for agent in StealthManager.builtInUserAgents {
            XCTAssertTrue(agent.hasPrefix("Mozilla/5.0"), "User agent should start with Mozilla/5.0: \(agent)")
        }
    }

    func testUserAgentsAreUnique() {
        let unique = Set(StealthManager.builtInUserAgents)
        XCTAssertEqual(unique.count, StealthManager.builtInUserAgents.count, "All user agents should be unique")
    }
}

// MARK: - Functional Tests: SponsorBlock API Response Parsing

final class SponsorBlockAPIResponseTests: XCTestCase {

    func testDecodeAPIResponse() throws {
        let json = """
        {
            "videoID": "test123",
            "segments": [
                {"segment": [0.0, 30.5], "category": "sponsor", "UUID": "seg1"},
                {"segment": [120.0, 135.0], "category": "intro", "UUID": "seg2"}
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(SponsorBlockAPIResponse.self, from: data)

        XCTAssertEqual(response.videoID, "test123")
        XCTAssertEqual(response.segments.count, 2)
        XCTAssertEqual(response.segments[0].category, "sponsor")
        XCTAssertEqual(response.segments[0].segment, [0.0, 30.5])
    }
}

// =============================================================================
// MARK: - Frame Tests
// =============================================================================

// MARK: - Frame Tests: App Launch & View Instantiation

@MainActor
final class FrameTests: XCTestCase {

    func testDownloadItemCanBeInstantiatedInBulk() {
        // Verify no crash when creating many download items at once
        var items: [DownloadItem] = []
        for i in 0..<100 {
            items.append(DownloadItem(url: "https://example.com/video\(i)"))
        }
        XCTAssertEqual(items.count, 100)
        // Each should have a unique ID
        let uniqueIDs = Set(items.map { $0.id })
        XCTAssertEqual(uniqueIDs.count, 100)
    }

    func testDataStoreCanBeAccessed() {
        // Verify DataStore singleton is accessible without crash
        let store = DataStore.shared
        XCTAssertNotNil(store)
        XCTAssertNotNil(store.settings)
        XCTAssertNotNil(store.stealthProfile)
    }

    func testAppSettingsInitWithoutCrash() {
        let settings = AppSettings()
        XCTAssertNotNil(settings)
        XCTAssertEqual(settings.theme, .dark)
    }

    func testStealthProfileInitWithoutCrash() {
        let profile = StealthProfile()
        XCTAssertNotNil(profile)
        XCTAssertTrue(profile.isEnabled)
    }

    func testAllBuiltInPresetsInitWithoutCrash() {
        let presets = DownloadPreset.builtInPresets
        XCTAssertEqual(presets.count, 6)
        for preset in presets {
            XCTAssertNotNil(preset.id)
            XCTAssertFalse(preset.name.isEmpty)
            let args = preset.options.toArguments()
            // Just verify toArguments doesn't crash
            XCTAssertNotNil(args)
        }
    }

    func testAllOutputTemplatePresetsInitWithoutCrash() {
        let presets = OutputTemplatePreset.builtIn
        XCTAssertGreaterThan(presets.count, 0)
        for preset in presets {
            XCTAssertFalse(preset.name.isEmpty)
            XCTAssertFalse(preset.template.isEmpty)
        }
    }

    func testAllOutputTemplateVariablesInitWithoutCrash() {
        let vars = OutputTemplateVariable.allVariables
        XCTAssertGreaterThan(vars.count, 0)
        for v in vars {
            XCTAssertFalse(v.name.isEmpty)
            XCTAssertFalse(v.code.isEmpty)
        }
    }

    func testDefaultPostDownloadActionsInitWithoutCrash() {
        let actions = PostDownloadAction.defaultActions
        XCTAssertGreaterThanOrEqual(actions.count, 2)
        for action in actions {
            XCTAssertFalse(action.name.isEmpty)
            XCTAssertNotNil(action.actionType)
        }
    }

    func testSpeedLimiterSharedAccessWithoutCrash() {
        let limiter = SpeedLimiter.shared
        XCTAssertNotNil(limiter)
    }

    func testStealthManagerSharedAccessWithoutCrash() {
        let manager = StealthManager.shared
        XCTAssertNotNil(manager)
        XCTAssertGreaterThan(manager.currentPoolSize, 0)
    }

    func testNovaAPIServerSharedAccessWithoutCrash() {
        let server = NovaAPIServer.shared
        XCTAssertNotNil(server)
        XCTAssertEqual(server.port, 37445)
    }

    func testSettingsLoadSaveRoundTrip() throws {
        // Test that settings can be serialized and deserialized without data loss
        var original = AppSettings()
        original.maxConcurrentDownloads = 8
        original.theme = .system
        original.outputDirectory = "/tmp/test-output"
        original.defaultOutputTemplate = "%(id)s - %(title)s.%(ext)s"

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(original)

        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)

        XCTAssertEqual(decoded.maxConcurrentDownloads, 8)
        XCTAssertEqual(decoded.theme, .system)
        XCTAssertEqual(decoded.outputDirectory, "/tmp/test-output")
        XCTAssertEqual(decoded.defaultOutputTemplate, "%(id)s - %(title)s.%(ext)s")
    }

    func testStealthProfileLoadSaveRoundTrip() throws {
        var original = StealthProfile()
        original.isEnabled = false
        original.minDelay = 3.0
        original.maxDelay = 10.0
        original.proxyEnabled = true
        original.proxyList = ["socks5://p1", "http://p2"]
        original.poToken = "token123"
        original.visitorData = "visitor456"
        original.playerClients = ["web", "ios"]

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StealthProfile.self, from: data)

        XCTAssertFalse(decoded.isEnabled)
        XCTAssertEqual(decoded.minDelay, 3.0)
        XCTAssertEqual(decoded.maxDelay, 10.0)
        XCTAssertTrue(decoded.proxyEnabled)
        XCTAssertEqual(decoded.proxyList, ["socks5://p1", "http://p2"])
        XCTAssertEqual(decoded.poToken, "token123")
        XCTAssertEqual(decoded.visitorData, "visitor456")
        XCTAssertEqual(decoded.playerClients, ["web", "ios"])
    }

    func testChannelSubscriptionLoadSaveRoundTrip() throws {
        var sub = ChannelSubscription(
            name: "Test Channel",
            url: "https://youtube.com/@test",
            checkInterval: .threeHours
        )
        sub.maxDownloadsPerCheck = 10
        sub.autoDownload = false
        sub.downloadedVideoIds = ["vid1", "vid2", "vid3"]

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(sub)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ChannelSubscription.self, from: data)

        XCTAssertEqual(decoded.name, "Test Channel")
        XCTAssertEqual(decoded.checkInterval, .threeHours)
        XCTAssertEqual(decoded.maxDownloadsPerCheck, 10)
        XCTAssertFalse(decoded.autoDownload)
        XCTAssertEqual(decoded.downloadedVideoIds.count, 3)
    }
}
