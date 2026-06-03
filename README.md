# ytdlp-gui

A modern macOS GUI for yt-dlp with full option coverage, battle-tested anti-detection, download scheduling, channel subscriptions, smart audio extraction, and a glassmorphic SwiftUI interface.

![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)
![Version](https://img.shields.io/badge/version-1.2.0-brightgreen)
![Tests](https://img.shields.io/badge/tests-300%20passing-brightgreen)

---

## Features

| Feature | Description |
|---------|-------------|
| 160+ yt-dlp flags | Visual editor across 17 categories -- every option accessible without a terminal |
| Download queue | Configurable concurrency (1-10 simultaneous), pause/resume/cancel per item, **persistent across restarts** |
| Playlist detection | Auto-detect YouTube playlists, browse entries, selective download |
| Format selector | Visual picker with quality comparison and quick presets (Best Video, Audio MP3/FLAC, 1080p, 720p) |
| **Nova Session Intelligence** | Battle-tested anti-detection from 677-channel production automation (see below) |
| **Smart audio extraction** | Auto-detect music content, extract to MP3/FLAC with ID3 tags, route to music library |
| **Per-channel output routing** | Custom output directories per subscription with Plex-friendly naming templates |
| Download library | Persistent history with thumbnails, search, filtering, favorites, one-click re-download |
| Presets | Built-in and custom download presets including Stealth Mode |
| Clipboard monitor | Watches clipboard for video URLs, offers instant download |
| Scheduled downloads | Time-based downloads with repeating rules (daily, weekly) |
| Channel subscriptions | Subscribe to channels/playlists for automatic new-content downloads |
| SponsorBlock editor | Visual timeline editor to remove sponsor segments before download |
| Post-download actions | Move, convert, tag, run scripts, or open in app after download |
| Speed limiter | Global or per-download speed caps with presets |
| Binary management | Auto-detect yt-dlp and ffmpeg, one-click updates |
| Desktop widget | WidgetKit extension (Small / Medium / Large) with live download queue and daily stats |
| Log viewer | Color-coded real-time yt-dlp output |
| Nova API server | HTTP API on port 37445 (loopback only) |
| Skip list | Persistent list of URLs to never re-attempt (members-only, geo-blocked, etc.) |

---

## Nova Session Intelligence

Six anti-detection strategies ported from production automation that downloads from 677+ YouTube channels daily without triggering rate limits:

| Strategy | What It Does |
|----------|-------------|
| Cookie TTL & auto-refresh | Monitors cookie file age, auto-refreshes from browser when stale (6h default) |
| Hard/soft block detection | Classifies errors: hard blocks (429/403) pause the session; soft errors (members-only, age-restricted) skip and continue |
| Realistic inter-download delays | 5-75 seconds between downloads (not 1-5s like typical tools), 60-188s between batches |
| Batch sizing with zero-batches | Random 0-4 downloads per batch; zero-batches create deliberate idle periods that mimic browsing |
| Session-level rate limit halt | After N consecutive hard blocks, halts the entire session instead of continuing to poke the bear |
| Persistent skip list | URLs that fail for structural reasons (members-only, geo-restricted) are permanently skipped |

All features are opt-in with safe defaults. Enable in **Anti-Detection > Nova Session Intelligence**.

---

## Smart Audio Extraction

Automatically detects music content and extracts audio with proper metadata:

- **Detection engine**: Matches by 80+ keywords (remix, DJ set, boiler room, etc.), `Artist - Title` filename patterns, channel whitelist, and duration range
- **Format options**: MP3, FLAC, Opus, WAV, M4A with configurable quality (Best/256k/192k/128k)
- **ID3 tagging**: Parses artist and title from filename, embeds thumbnail as cover art
- **Separate output**: Routes music to a dedicated directory (default `~/Music/ytdlp-gui`)
- **Fully configurable**: Custom keyword lists, channel whitelists, duration bounds

---

## Per-Channel Output Routing

Each subscription can have its own output directory and naming template:

| Template | Pattern | Example |
|----------|---------|---------|
| Default | `%(title)s.%(ext)s` | `Video Title.mp4` |
| Channel Folder | `ChannelName/%(title)s.%(ext)s` | `MKBHD/Video Title.mp4` |
| Plex (Show) | `Show/Season 01/Show - S01Exx - Title.%(ext)s` | `LTT/Season 01/LTT - S01E05 - Title.mp4` |
| Plex (Movie) | `Title (Year)/Title.%(ext)s` | `Channel (2024)/Video Title.mp4` |
| Date Folder | `%(upload_date)s/%(title)s.%(ext)s` | `2024-03-15/Video Title.mp4` |
| Custom | Any yt-dlp template | User-defined |

---

## Persistent Download Queue

The download queue survives app restarts. Active downloads are automatically resumed on next launch -- you'll never lose a batch if the app crashes, gets killed, or macOS restarts.

---

## Architecture

```mermaid
graph TD
    subgraph UI["SwiftUI Views"]
        CV[ContentView]
        DASH[DashboardView]
        ND[NewDownloadView]
        QV[QueueView]
        LV[LibraryView]
        PV[PresetsView]
        STV[StealthView]
        SBV[SponsorBlockEditorView]
        SCHV[ScheduleView]
        SUBV[SubscriptionView]
        CMV[ClipboardMonitorView]
        BV[BinaryManagerView]
        SV[SettingsView]
    end

    subgraph Services["Service Layer"]
        DM[DownloadManager<br/>Queue + Concurrency]
        YS[YTDLPService<br/>Process Execution]
        SM[StealthManager<br/>Anti-Detection]
        SESS[SessionManager<br/>Nova Intelligence]
        CRS[CookieRefreshService<br/>Auto-Refresh]
        SLM[SkipListManager<br/>Permanent Skips]
        BM[BinaryManager<br/>yt-dlp + ffmpeg]
        CM[ClipboardMonitor<br/>URL Detection]
        SBS[SponsorBlockService<br/>Segment API]
        PDM[PostDownloadManager<br/>Action Pipeline]
        SCH[ScheduleManager<br/>Timed Downloads]
        SUB[SubscriptionManager<br/>Channel Feeds]
        SL[SpeedLimiter<br/>Rate Control]
        DS[DataStore<br/>JSON Persistence]
        MS[MetadataService<br/>Video Info]
        WDS[WidgetDataSync<br/>App Group]
    end

    subgraph External["External Dependencies"]
        YTDLP["yt-dlp CLI"]
        FFMPEG["ffmpeg"]
        SBAPI["SponsorBlock API"]
    end

    subgraph API["Nova API :37445"]
        STATUS["GET /api/status"]
        PING["GET /api/ping"]
        DOWNLOADS["GET /api/downloads"]
        DL_POST["POST /api/download"]
    end

    CV --> ND & QV & LV & PV & STV & SCHV & SUBV
    ND --> DM
    QV --> DM
    DM --> YS
    DM --> SM
    DM --> SESS
    DM --> SLM
    DM --> CRS
    DM --> SL
    DM --> PDM
    SESS --> SLM
    YS -->|Process.arguments| YTDLP
    YS --> BM
    BM --> YTDLP & FFMPEG
    SBS --> SBAPI
    CM --> DM
    SCH --> DM
    SUB --> DM
    SUB --> SLM
    DM --> DS
    DM --> WDS
    WDS --> WIDGET[WidgetKit Extension]
    API --> DM
```

---

## Installation

1. Install yt-dlp: `brew install yt-dlp`
2. Install ffmpeg (recommended): `brew install ffmpeg`
3. Download the latest DMG from [Releases](https://github.com/kochj23/ytdlp-gui/releases)
4. Open the DMG and drag ytdlp-gui.app to `/Applications`
5. No sandbox -- direct file system access

## Requirements

| Requirement | Minimum |
|-------------|---------|
| macOS | 14.0 (Sonoma) |
| Architecture | Universal (Apple Silicon + Intel) |
| yt-dlp | Required -- `brew install yt-dlp` |
| ffmpeg | Recommended for format merging -- `brew install ffmpeg` |

---

## Building

```bash
git clone https://github.com/kochj23/ytdlp-gui.git
cd ytdlp-gui
brew install xcodegen  # if not installed
xcodegen generate
xcodebuild -scheme ytdlp-gui -configuration Release build CODE_SIGNING_ALLOWED=NO
```

## Testing

```bash
xcodebuild test -project ytdlp-gui.xcodeproj -scheme ytdlp-gui \
  -destination 'platform=macOS' -only-testing:ytdlp-guiTests \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

300 tests across 41 test classes covering unit, functional, security, and integration layers:

| Category | Tests | What's Covered |
|----------|------:|----------------|
| Unit: Options | 24 | `YTDLPOptions.toArguments()` for all 17 flag categories, Codable round-trip |
| Unit: Models | 56 | DownloadItem, DownloadProgress, DownloadPreset, LibraryItem, FormatInfo, PostDownloadAction, SponsorBlockSegment, AppSettings, StealthProfile, CookieSource, OutputTemplate |
| Unit: URL Detection | 21 | Clipboard URL pattern matching for 19 supported sites |
| Unit: YouTube ID | 9 | Video ID extraction from watch, youtu.be, shorts URLs |
| Unit: Progress Parsing | 9 | Regex extraction of percentage, speed, ETA, total size |
| Unit: Byte/Time Parsing | 12 | GiB/MiB/KiB/GB/MB/KB/B size strings, HH:MM:SS and MM:SS |
| Unit: Metadata | 7 | MediaMetadata/PlaylistInfo JSON decoding, FormatInfo codec/resolution |
| Unit: Enums | 6 | AudioFormat, MergeOutputFormat, SubtitleFormat, Impersonate, SponsorBlock, Fixup |
| Unit: Error | 11 | YTDLPError descriptions, equality, HTTP 429/403 detection patterns |
| Unit: Channels/Schedule | various | ChannelSubscription, ScheduledDownload, DownloadResult Codable |
| Functional: Stealth | 5 | User agent pool rotation, exhaustion reset, uniqueness |
| Functional: Speed | 6 | SpeedLimiter formatting, presets |
| Security: Injection | 6 | Shell metacharacter safety, proxy/UA injection, direct script execution |
| Security: Filenames | 3 | restrict-filenames, windows-filenames, trim-filenames |
| Security: URL/Creds | 4 | SponsorBlock API encoding, notification domain-only, no hardcoded passwords |
| Integration: Binary | 4 | yt-dlp, ffmpeg, ffprobe availability, Application Support directory |
| Frame | various | App launch, view instantiation, settings/stealth round-trip |

---

## Nova API Server

Port **37445** (127.0.0.1 loopback only). No authentication required.

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/status` | App status, version, uptime |
| `GET` | `/api/ping` | Health check |
| `GET` | `/api/downloads` | Current download queue |
| `POST` | `/api/download` | Start a download (`{"url":"..."}`) |

```bash
curl -s http://127.0.0.1:37445/api/status | python3 -m json.tool
```

---

## License

MIT License -- Copyright (c) 2026 Jordan Koch

See [LICENSE](LICENSE) for the full text.

---

## Related Projects

- [Nova](https://github.com/kochj23/nova) — The AI familiar that powers the session intelligence engine
- [Nova's Journal](https://nova.digitalnoise.net) — Daily essays, security briefings, and creative writing from Nova
- [Live System Dashboard](https://gauges.digitalnoise.net/gauges) — Real-time 3D gauge cluster monitoring Nova's infrastructure

---

Written by Jordan Koch
