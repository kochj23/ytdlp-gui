//
//  OutputTemplate.swift
//  ytdlp-gui
//
//  Output filename template builder model
//  Created by Jordan Koch on 2026-02-25.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

struct OutputTemplateVariable: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let code: String
    let description: String
    let category: TemplateCategory

    enum TemplateCategory: String, CaseIterable {
        case video = "Video"
        case upload = "Upload"
        case format = "Format"
        case playlist = "Playlist"
        case other = "Other"
    }

    static let allVariables: [OutputTemplateVariable] = [
        // Video
        OutputTemplateVariable(name: "Title", code: "%(title)s", description: "Video title", category: .video),
        OutputTemplateVariable(name: "ID", code: "%(id)s", description: "Video identifier", category: .video),
        OutputTemplateVariable(name: "Description", code: "%(description)s", description: "Video description", category: .video),
        OutputTemplateVariable(name: "Duration", code: "%(duration)s", description: "Duration in seconds", category: .video),
        OutputTemplateVariable(name: "Duration (formatted)", code: "%(duration_string)s", description: "Duration as HH:MM:SS", category: .video),
        OutputTemplateVariable(name: "View Count", code: "%(view_count)s", description: "Number of views", category: .video),
        OutputTemplateVariable(name: "Like Count", code: "%(like_count)s", description: "Number of likes", category: .video),
        OutputTemplateVariable(name: "Age Limit", code: "%(age_limit)s", description: "Age restriction", category: .video),
        OutputTemplateVariable(name: "Webpage URL", code: "%(webpage_url)s", description: "Full URL of the page", category: .video),

        // Upload
        OutputTemplateVariable(name: "Uploader", code: "%(uploader)s", description: "Channel/uploader name", category: .upload),
        OutputTemplateVariable(name: "Uploader ID", code: "%(uploader_id)s", description: "Uploader identifier", category: .upload),
        OutputTemplateVariable(name: "Channel", code: "%(channel)s", description: "Channel name", category: .upload),
        OutputTemplateVariable(name: "Channel ID", code: "%(channel_id)s", description: "Channel identifier", category: .upload),
        OutputTemplateVariable(name: "Upload Date", code: "%(upload_date)s", description: "Upload date (YYYYMMDD)", category: .upload),
        OutputTemplateVariable(name: "Release Date", code: "%(release_date)s", description: "Release date (YYYYMMDD)", category: .upload),
        OutputTemplateVariable(name: "Release Year", code: "%(release_year)s", description: "Release year", category: .upload),

        // Format
        OutputTemplateVariable(name: "Extension", code: "%(ext)s", description: "File extension", category: .format),
        OutputTemplateVariable(name: "Resolution", code: "%(resolution)s", description: "Resolution (e.g., 1920x1080)", category: .format),
        OutputTemplateVariable(name: "Height", code: "%(height)s", description: "Video height in pixels", category: .format),
        OutputTemplateVariable(name: "Width", code: "%(width)s", description: "Video width in pixels", category: .format),
        OutputTemplateVariable(name: "FPS", code: "%(fps)s", description: "Frames per second", category: .format),
        OutputTemplateVariable(name: "Video Codec", code: "%(vcodec)s", description: "Video codec", category: .format),
        OutputTemplateVariable(name: "Audio Codec", code: "%(acodec)s", description: "Audio codec", category: .format),
        OutputTemplateVariable(name: "Format ID", code: "%(format_id)s", description: "Format identifier", category: .format),
        OutputTemplateVariable(name: "File Size", code: "%(filesize)s", description: "File size in bytes", category: .format),

        // Playlist
        OutputTemplateVariable(name: "Playlist Title", code: "%(playlist_title)s", description: "Playlist title", category: .playlist),
        OutputTemplateVariable(name: "Playlist Index", code: "%(playlist_index)s", description: "Index in playlist", category: .playlist),
        OutputTemplateVariable(name: "Playlist Count", code: "%(n_entries)s", description: "Total entries in playlist", category: .playlist),
        OutputTemplateVariable(name: "Playlist ID", code: "%(playlist_id)s", description: "Playlist identifier", category: .playlist),
        OutputTemplateVariable(name: "Playlist Uploader", code: "%(playlist_uploader)s", description: "Playlist uploader name", category: .playlist),

        // Other
        OutputTemplateVariable(name: "Extractor", code: "%(extractor)s", description: "Extractor name (e.g., youtube)", category: .other),
        OutputTemplateVariable(name: "Epoch", code: "%(epoch)s", description: "Unix epoch of download", category: .other),
        OutputTemplateVariable(name: "Autonumber", code: "%(autonumber)s", description: "Auto-incrementing number", category: .other),
    ]

    static func variables(for category: TemplateCategory) -> [OutputTemplateVariable] {
        allVariables.filter { $0.category == category }
    }
}

struct OutputTemplatePreset: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let template: String
    let description: String

    init(id: UUID = UUID(), name: String, template: String, description: String) {
        self.id = id
        self.name = name
        self.template = template
        self.description = description
    }

    static let builtIn: [OutputTemplatePreset] = [
        OutputTemplatePreset(name: "Default", template: "%(title)s.%(ext)s", description: "Title with extension"),
        OutputTemplatePreset(name: "With Uploader", template: "%(uploader)s - %(title)s.%(ext)s", description: "Uploader - Title"),
        OutputTemplatePreset(name: "Organized", template: "%(uploader)s/%(title)s.%(ext)s", description: "Uploader folder / Title"),
        OutputTemplatePreset(name: "With Date", template: "%(upload_date)s - %(title)s.%(ext)s", description: "Date - Title"),
        OutputTemplatePreset(name: "Playlist", template: "%(playlist_title)s/%(playlist_index)s - %(title)s.%(ext)s", description: "Playlist folder / Index - Title"),
        OutputTemplatePreset(name: "Full Info", template: "%(uploader)s/%(upload_date)s - %(title)s [%(resolution)s].%(ext)s", description: "Uploader / Date - Title [Resolution]"),
    ]
}
