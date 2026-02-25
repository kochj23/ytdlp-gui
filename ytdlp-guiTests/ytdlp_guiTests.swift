//
//  ytdlp_guiTests.swift
//  ytdlp-guiTests
//
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import XCTest
@testable import ytdlp_gui

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
}

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
}
