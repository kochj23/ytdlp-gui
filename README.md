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

## Supported Sites

ytdlp-gui works with **any site supported by yt-dlp** — over **1,800 sites** and counting. Below are the most popular ones, organized by category.

> For the complete list, see [yt-dlp supported sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md).

### Video Platforms
| Site | Notes |
|------|-------|
| **YouTube** | Videos, playlists, channels, shorts, live streams, music |
| **Vimeo** | Videos, albums, channels, on-demand, user profiles |
| **Dailymotion** | Videos, playlists, user uploads, search |
| **Twitch** | Live streams, VODs, clips, collections |
| **Rumble** | Videos, channels, embeds |
| **Bilibili** | Videos, bangumi, audio, playlists, live, search |
| **Niconico** | Videos, live, playlists, series, user uploads |
| **PeerTube** | Any PeerTube instance, playlists |
| **Odysee / LBRY** | Videos, channels, playlists |
| **Rutube** | Videos, channels, playlists, movies |
| **BitChute** | Videos, channels |
| **Kick** | Live streams, VODs, clips |

### Social Media
| Site | Notes |
|------|-------|
| **Twitter / X** | Videos, broadcasts, Spaces, cards, Amplify |
| **Instagram** | Posts, reels, stories, IGTV |
| **TikTok** | Videos, user profiles, live, collections |
| **Facebook** | Videos, reels, ads, page videos |
| **Reddit** | Video posts |
| **Bluesky** | Video posts |
| **Pinterest** | Pins, collections |
| **Tumblr** | Video posts |
| **VK (VKontakte)** | Videos, wall posts, user videos, VK Play |
| **Weibo** | Videos, user profiles |
| **Snapchat** | Spotlight videos |

### Music & Audio
| Site | Notes |
|------|-------|
| **SoundCloud** | Tracks, playlists, sets, user profiles, search |
| **Bandcamp** | Tracks, albums, user pages, weekly features |
| **Mixcloud** | Mixes, playlists, user profiles |
| **Audiomack** | Tracks, albums |
| **JioSaavn** | Songs, albums, playlists, artist pages, shows |
| **Spotify** | Podcast episodes (limited) |
| **Apple Podcasts** | Episodes |
| **QQ Music** | Songs, albums, MVs, playlists, top lists |
| **NetEase Music** | Songs, albums, MVs, playlists, DJ radio |

### Streaming & TV
| Site | Notes |
|------|-------|
| **BBC iPlayer** | Videos, episodes, playlists |
| **ITV** | On-demand content |
| **Channel 4 (All 4)** | On-demand content |
| **ARD Mediathek** | Videos, collections, audio |
| **ZDF** | Videos, channels |
| **Arte** | Videos, playlists, categories, embeds |
| **France TV** | Videos, France Info |
| **SVT Play** | Videos, series |
| **NRK** | TV, radio, podcasts, school content |
| **DR TV** | Videos, live, series, seasons |
| **RTE** | Irish national TV and radio |
| **CBC Gem** | Videos, live, playlists |
| **SBS (Australia)** | On-demand content |
| **Crunchyroll** | Anime episodes, series |
| **Disney** | Select content |
| **Paramount+** | Via CBS News embeds |
| **Discovery+** | Videos, shows (multiple regions) |
| **Hotstar** | Videos, series |
| **Viu** | Videos, playlists (Asian content) |
| **WeTV** | Episodes, series |
| **iQIYI** | Videos, albums |

### News & Media
| Site | Notes |
|------|-------|
| **CNN** | Video clips |
| **ABC News** | Videos, articles |
| **CBS News** | Videos, embeds, live |
| **NBC News** | Videos, stations |
| **Fox News** | Videos, articles |
| **BBC News** | Articles, video clips |
| **The Washington Post** | Videos, articles |
| **The New York Times** | Videos, articles, cooking |
| **The Guardian** | Podcasts, podcast playlists |
| **C-SPAN** | Videos, congressional hearings |
| **Al Jazeera** | Videos |
| **France 24** | Via francetv |
| **DW (Deutsche Welle)** | Articles |
| **NHK** | VOD, radio, school content |
| **Sky News** | Videos, stories, Sky News AU |

### Education & Learning
| Site | Notes |
|------|-------|
| **Khan Academy** | Lessons, units |
| **Udemy** | Lectures, courses |
| **Coursera** | Via generic extractor |
| **LinkedIn Learning** | Lessons, courses |
| **MIT OpenCourseWare** | Lectures |
| **TED** | Talks, playlists, series, embeds |
| **Pluralsight** | Lessons, courses |
| **Frontend Masters** | Lessons, courses |
| **egghead.io** | Lessons, courses |
| **CuriosityStream** | Videos, collections, series |
| **BrainPOP** | Educational videos (multiple languages) |
| **Laracasts** | Videos, series |

### Live Streaming
| Site | Notes |
|------|-------|
| **Twitch** | Live streams, VODs, clips, collections |
| **Kick** | Live streams, VODs, clips |
| **YouTube Live** | Live streams, premieres |
| **TwitCasting** | Live streams, user archives |
| **AfreecaTV (SOOP)** | Live streams, catch stories, user profiles |
| **Livestream** | Live and archived content |
| **Trovo** | Live streams, VODs, channel clips |
| **LivestreamFails** | Clips |

### Podcasts & Radio
| Site | Notes |
|------|-------|
| **Apple Podcasts** | Episodes |
| **Spreaker** | Episodes, shows |
| **Podchaser** | Episodes |
| **Simplecast** | Episodes, podcasts |
| **Megaphone** | Episodes |
| **iHeartRadio** | Podcasts, episodes |
| **TuneIn** | Stations, podcasts |
| **Radio France** | Live, podcasts, profiles |
| **BBC Radio** | Via BBC extractor |
| **NPR** | Audio segments |

### Sports
| Site | Notes |
|------|-------|
| **ESPN** | Videos, articles, cricket |
| **MLB** | Videos, articles, MLB TV |
| **NFL** | Videos, articles, NFL+ episodes and replays |
| **NHL** | Videos |
| **UFC** | UFC Arabia, UFC TV |
| **PGA Tour** | Videos |
| **Bundesliga** | Videos |
| **Motorsport** | Videos |
| **Red Bull TV** | Videos, embeds |
| **Wimbledon** | Videos |
| **MLS Soccer** | Videos |

### Cloud & File Hosting
| Site | Notes |
|------|-------|
| **Archive.org** | Videos, audio, collections |
| **Dropbox** | Shared video files |
| **Google Drive** | Shared video files, folders |
| **Loom** | Screen recordings, folders |
| **Streamable** | Video clips |
| **Wistia** | Business video hosting, channels, playlists |
| **Brightcove** | Enterprise video platform |
| **SharePoint** | Microsoft hosted videos |

### Entertainment & Gaming
| Site | Notes |
|------|-------|
| **Vevo** | Music videos, playlists |
| **GameSpot** | Gaming videos |
| **IGN** | Gaming/entertainment videos |
| **Steam** | Game trailers, community content, broadcasts |
| **Rooster Teeth** | Videos, series |
| **Funimation** | Via Crunchyroll |
| **South Park** | Episodes (multiple regions) |
| **Conan Classic** | Classic episodes |
| **Comedy Central** | Episodes, clips |

### Creator Platforms
| Site | Notes |
|------|-------|
| **Patreon** | Posts, campaigns |
| **Substack** | Embedded video/audio |
| **Nebula** | Videos, channels, subscriptions |
| **Floatplane** | Videos, channels |
| **Boosty** | Creator content |
| **Imgur** | Videos, albums, galleries |
| **Flickr** | Videos |

> **Note:** Some sites require authentication (cookies or login). Use the Anti-Detection panel to import browser cookies. Some extractors may be temporarily broken — check yt-dlp's issue tracker for current status. Keeping yt-dlp updated ensures the best compatibility.

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
