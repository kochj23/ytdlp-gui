//
//  SponsorBlockService.swift
//  ytdlp-gui
//
//  Fetches SponsorBlock segments for visual timeline editing
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import os

@MainActor
class SponsorBlockService: ObservableObject {
    static let shared = SponsorBlockService()

    @Published var segments: [SponsorBlockSegment] = []
    @Published var isFetching = false
    @Published var videoDuration: Double = 0

    private let logger = Logger(subsystem: "com.jordankoch.ytdlp-gui", category: "SponsorBlockService")
    private let apiBase = "https://sponsor.ajay.app/api"

    // MARK: - Fetch Segments

    func fetchSegments(videoID: String) async {
        isFetching = true
        defer { isFetching = false }

        let categories = SponsorBlockSegment.SegmentCategory.allCases.map(\.rawValue)
        let categoriesParam = "[" + categories.map { "\"\($0)\"" }.joined(separator: ",") + "]"

        guard let url = URL(string: "\(apiBase)/skipSegments?videoID=\(videoID)&categories=\(categoriesParam)") else {
            logger.error("Invalid SponsorBlock URL")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let apiSegments = try JSONDecoder().decode([SponsorBlockAPISegment].self, from: data)

            segments = apiSegments.compactMap { apiSeg -> SponsorBlockSegment? in
                guard apiSeg.segment.count >= 2,
                      let category = SponsorBlockSegment.SegmentCategory(rawValue: apiSeg.category) else { return nil }
                return SponsorBlockSegment(category: category, startTime: apiSeg.segment[0], endTime: apiSeg.segment[1])
            }

            logger.info("Fetched \(self.segments.count) SponsorBlock segments for \(videoID)")
        } catch {
            logger.debug("SponsorBlock fetch failed: \(error.localizedDescription)")
            segments = []
        }
    }

    // MARK: - Extract Video ID

    func extractYouTubeVideoID(from url: String) -> String? {
        // youtube.com/watch?v=ID
        if let range = url.range(of: "v=") {
            let start = range.upperBound
            let remaining = String(url[start...])
            return String(remaining.prefix(while: { $0 != "&" && $0 != "#" }))
        }
        // youtu.be/ID
        if url.contains("youtu.be/") {
            if let range = url.range(of: "youtu.be/") {
                let start = range.upperBound
                let remaining = String(url[start...])
                return String(remaining.prefix(while: { $0 != "?" && $0 != "#" }))
            }
        }
        // youtube.com/shorts/ID
        if url.contains("/shorts/") {
            if let range = url.range(of: "/shorts/") {
                let start = range.upperBound
                let remaining = String(url[start...])
                return String(remaining.prefix(while: { $0 != "?" && $0 != "#" }))
            }
        }
        return nil
    }

    // MARK: - Build yt-dlp Arguments

    func buildSponsorBlockArgs() -> [String] {
        let selectedCategories = segments.filter(\.isSelected).map(\.category.rawValue)
        guard !selectedCategories.isEmpty else { return [] }
        return ["--sponsorblock-remove", selectedCategories.joined(separator: ",")]
    }

    func toggleSegment(_ id: UUID) {
        if let index = segments.firstIndex(where: { $0.id == id }) {
            segments[index].isSelected.toggle()
        }
    }

    func selectAll() {
        for index in segments.indices {
            segments[index].isSelected = true
        }
    }

    func deselectAll() {
        for index in segments.indices {
            segments[index].isSelected = false
        }
    }

    func clear() {
        segments = []
        videoDuration = 0
    }

    // MARK: - Stats

    var totalSkipTime: Double {
        segments.filter(\.isSelected).reduce(0) { $0 + $1.duration }
    }
}
