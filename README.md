# ytdlp-gui

A modern macOS GUI for [yt-dlp](https://github.com/yt-dlp/yt-dlp) with full feature coverage, anti-detection capabilities, and a glassmorphic dark UI.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Every yt-dlp option** — All ~160 flags across 17 categories exposed through a visual editor
- **Download queue** — Configurable concurrency (1-10 simultaneous downloads) with pause/resume/cancel per item
- **Playlist detection** — Auto-detect YouTube playlists, browse entries, selectively download
- **Format selector** — Visual format picker with quality comparison and quick presets
- **Output template builder** — Build custom filename templates with variable chips
- **Anti-detection suite** — User agent rotation (50+ agents), random delays, TLS impersonation, proxy rotation, cookie import from Chrome/Firefox/Safari/Edge/Brave, auto-retry on HTTP 429 with exponential backoff
- **Download library** — Persistent history with thumbnails, search, filtering, favorites
- **Download presets** — Built-in presets (Best Video, Audio MP3, Audio FLAC, 1080p, 720p, Stealth Mode) plus custom presets
- **Binary management** — Auto-detect yt-dlp and ffmpeg, one-click updates
- **Real-time progress** — Live progress bars, speed display, ETA, circular speed gauge
- **macOS notifications** — Completion/failure notifications
- **Log viewer** — Color-coded real-time yt-dlp output

## Screenshots

The app uses a dark glassmorphic design with animated floating blobs, glass cards, and vibrant accent colors.

## Requirements

- macOS 13.0 (Ventura) or later
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) installed (via Homebrew: `brew install yt-dlp`)
- [ffmpeg](https://ffmpeg.org/) recommended for format merging (`brew install ffmpeg`)

## Installation

### DMG (Recommended)
1. Download the latest DMG from [Releases](https://github.com/kochj23/ytdlp-gui/releases)
2. Open the DMG and drag ytdlp-gui to Applications
3. Launch from Applications

### Build from Source
```bash
# Clone
git clone https://github.com/kochj23/ytdlp-gui.git
cd ytdlp-gui

# Generate Xcode project (requires xcodegen)
brew install xcodegen
xcodegen generate

# Build
xcodebuild -project ytdlp-gui.xcodeproj -scheme ytdlp-gui -configuration Release build
```

## Usage

1. **New Download** — Paste a URL, optionally fetch metadata and pick a format, click Download
2. **Queue** — Monitor active downloads, adjust concurrency, pause/resume individual items
3. **Presets** — Quick-select common configurations (Best Video, Audio MP3, etc.)
4. **All Options** — Fine-tune every yt-dlp flag across 17 categories
5. **Anti-Detection** — Enable stealth mode to rotate user agents, add random delays, and auto-retry on rate limits
6. **Library** — Browse download history with search, favorites, and one-click re-download

## Anti-Detection

The stealth system helps avoid rate limiting and detection:

- **User Agent Rotation** — 50+ real browser user agents, shuffled without repeats until pool is exhausted
- **Random Delays** — Configurable min/max delays between requests
- **Cookie Import** — Use cookies from Chrome, Firefox, Safari, Edge, Brave, Opera, Vivaldi
- **TLS Impersonation** — Impersonate browser TLS fingerprints via yt-dlp's `--impersonate`
- **Proxy Rotation** — Round-robin through a list of SOCKS5/HTTP proxies
- **Auto-Retry** — Exponential backoff with identity rotation on HTTP 429

## Architecture

- **SwiftUI** with `@MainActor` concurrency
- **Process** execution with real-time `readabilityHandler` streaming
- **JSON persistence** in `~/Library/Application Support/ytdlp-gui/`
- **XcodeGen** for project generation
- No sandbox — direct file system access for maximum functionality

## License

MIT License — see [LICENSE](LICENSE) for details.

## Author

Created by Jordan Koch ([@kochj23](https://github.com/kochj23))
