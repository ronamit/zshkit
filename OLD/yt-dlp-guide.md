# yt-dlp Guide: Downloading YouTube Videos in Highest Quality (Default)

A quick reference guide for downloading YouTube videos using `yt-dlp`. **Default: highest quality** — commands below use `bestvideo+bestaudio/best` merged to MP4 unless noted (e.g. 403 fallback or audio-only).

## Installation

```bash
# Install pipx (recommended for Python CLI tools)
sudo apt install -y pipx
pipx ensurepath

# Install yt-dlp
pipx install yt-dlp

# Install ffmpeg (required for merging video+audio)
sudo apt install -y ffmpeg
```

## Basic Commands

### Download a Single Video (Highest Quality)

```bash
yt-dlp -f "bestvideo+bestaudio/best" --merge-output-format mp4 "VIDEO_URL"
```

### Download with Custom Filename

```bash
yt-dlp -f "bestvideo+bestaudio/best" --merge-output-format mp4 -o "%(title)s.%(ext)s" "VIDEO_URL"
```

### Download to Specific Directory

```bash
yt-dlp -f "bestvideo+bestaudio/best" --merge-output-format mp4 -o "~/Videos/%(title)s.%(ext)s" "VIDEO_URL"
```

## Downloading Playlists

### Download Entire Playlist (Highest Quality)

```bash
yt-dlp -f "bestvideo+bestaudio/best" --merge-output-format mp4 \
  -o "%(playlist_index)s - %(title)s.%(ext)s" "PLAYLIST_URL"
```

### Download Playlist to Specific Folder

```bash
mkdir -p ~/Videos/MyPlaylist
yt-dlp -f "bestvideo+bestaudio/best" --merge-output-format mp4 \
  -o "~/Videos/MyPlaylist/%(playlist_index)s - %(title)s.%(ext)s" "PLAYLIST_URL"
```

### Download Specific Videos from Playlist

```bash
# Download videos 1-5
yt-dlp --playlist-items 1-5 -f "bestvideo+bestaudio/best" "PLAYLIST_URL"

# Download videos 1, 3, 5, 7
yt-dlp --playlist-items 1,3,5,7 -f "bestvideo+bestaudio/best" "PLAYLIST_URL"
```

## Quality Selection

### List Available Formats

```bash
yt-dlp -F "VIDEO_URL"
```

### Download Specific Resolution

```bash
# Best video up to 1080p + best audio
yt-dlp -f "bestvideo[height<=1080]+bestaudio/best" --merge-output-format mp4 "VIDEO_URL"

# Best video up to 720p + best audio
yt-dlp -f "bestvideo[height<=720]+bestaudio/best" --merge-output-format mp4 "VIDEO_URL"

# Best video up to 4K + best audio
yt-dlp -f "bestvideo[height<=2160]+bestaudio/best" --merge-output-format mp4 "VIDEO_URL"
```

### Download by Format ID

```bash
# First list formats with: yt-dlp -F "VIDEO_URL"
# Then download specific format IDs
yt-dlp -f 137+140 "VIDEO_URL"  # 137=1080p video, 140=audio
```

## Audio Only

### Download Best Audio as MP3

```bash
yt-dlp -x --audio-format mp3 --audio-quality 0 "VIDEO_URL"
```

### Download Best Audio (Original Format)

```bash
yt-dlp -f "bestaudio" "VIDEO_URL"
```

### Download Playlist as MP3s

```bash
yt-dlp -x --audio-format mp3 --audio-quality 0 \
  -o "%(playlist_index)s - %(title)s.%(ext)s" "PLAYLIST_URL"
```

## Useful Options

| Option | Description |
|--------|-------------|
| `-f "bestvideo+bestaudio/best"` | **Default:** highest quality (best video + best audio, merged) |
| `--merge-output-format mp4` | Merge video+audio into MP4 container |
| `--embed-thumbnail` | Embed thumbnail in the video file |
| `--embed-subs` | Embed subtitles in the video |
| `--write-subs` | Download subtitles as separate files |
| `--sub-lang en` | Download English subtitles |
| `--write-auto-subs` | Download auto-generated subtitles |
| `--no-playlist` | Download only the video, not the playlist |
| `--yes-playlist` | Download the whole playlist |
| `--download-archive file.txt` | Track downloaded videos and skip on re-run |
| `--limit-rate 5M` | Limit download speed to 5MB/s |
| `--sleep-interval 5` | Wait 5 seconds between downloads |
| `--cookies-from-browser firefox` | Use cookies from browser (for private videos) |
| `--extractor-args "youtube:player_client=android"` | Use Android client (more reliable, lower quality) |

## Output Template Variables

Use these in `-o` option:

| Variable | Description |
|----------|-------------|
| `%(title)s` | Video title |
| `%(id)s` | Video ID |
| `%(ext)s` | File extension |
| `%(playlist_index)s` | Index in playlist (01, 02, etc.) |
| `%(playlist_title)s` | Playlist name |
| `%(uploader)s` | Channel name |
| `%(upload_date)s` | Upload date (YYYYMMDD) |
| `%(duration)s` | Duration in seconds |
| `%(resolution)s` | Resolution (e.g., 1920x1080) |

## Common Examples

### Download Course/Tutorial Playlist

```bash
mkdir -p ~/Videos/CourseName
cd ~/Videos/CourseName
yt-dlp -f "bestvideo+bestaudio/best" --merge-output-format mp4 \
  --embed-thumbnail --embed-subs --write-auto-subs --sub-lang en \
  -o "%(playlist_index)s - %(title)s.%(ext)s" \
  "PLAYLIST_URL"
```

### Download Music Playlist as MP3

```bash
mkdir -p ~/Music/PlaylistName
yt-dlp -x --audio-format mp3 --audio-quality 0 \
  --embed-thumbnail \
  -o "~/Music/PlaylistName/%(playlist_index)s - %(title)s.%(ext)s" \
  "PLAYLIST_URL"
```

### Archive Channel (Skip Already Downloaded)

```bash
yt-dlp -f "bestvideo+bestaudio/best" --merge-output-format mp4 \
  --download-archive downloaded.txt \
  -o "%(upload_date)s - %(title)s.%(ext)s" \
  "CHANNEL_URL"
```

### Download with Subtitles

```bash
yt-dlp -f "bestvideo+bestaudio/best" --merge-output-format mp4 \
  --write-subs --write-auto-subs --sub-lang "en,es" --embed-subs \
  "VIDEO_URL"
```

### Download Playlist with HTTP 403 Workaround

If you encounter HTTP 403 errors, use the Android client with rate limiting:

```bash
mkdir -p ~/Videos/ConferenceName
yt-dlp -f "best[ext=mp4]/best" \
  --extractor-args "youtube:player_client=android" \
  --sleep-interval 3 \
  -o "~/Videos/ConferenceName/%(playlist_index)s - %(title)s.%(ext)s" \
  "PLAYLIST_URL"
```

This uses the Android player client which is more reliable but may provide lower quality (typically 360p-720p).

### Download Conference/Talk Playlist (Real Example)

```bash
# Example: Download GenML 2025 conference (27 videos; first 27 of MDLI channel)
mkdir -p ~/Videos/GenML2025
yt-dlp -f "bestvideo+bestaudio/best" --merge-output-format mp4 \
  --force-overwrites --playlist-items 1-27 --sleep-interval 3 \
  -o "~/Videos/GenML2025/%(playlist_index)s - %(title)s.%(ext)s" \
  "https://www.youtube.com/channel/UCfmK_Tsp2VJVFokMb6N3r1Q/videos"
```

The `--sleep-interval 3` adds a 3-second delay between downloads to avoid rate limiting.

## Updating yt-dlp

YouTube frequently changes its API, so keeping yt-dlp updated is important for avoiding download errors:

```bash
# Update yt-dlp
pipx upgrade yt-dlp

# Check current version
yt-dlp --version
```

**Tip:** If you encounter persistent download issues, update yt-dlp first before trying other troubleshooting steps.

## Troubleshooting

### "ffmpeg not installed" Warning
```bash
sudo apt install -y ffmpeg
```

### "No JavaScript runtime" Warning
This is usually harmless, but you can install Node.js if issues occur:
```bash
sudo apt install -y nodejs
```

### HTTP Error 403: Forbidden
If you encounter "HTTP Error 403: Forbidden" when downloading videos, use the Android player client:

```bash
# Single video
yt-dlp -f "best[ext=mp4]/best" --extractor-args "youtube:player_client=android" "VIDEO_URL"

# Playlist with rate limiting
yt-dlp -f "best[ext=mp4]/best" --extractor-args "youtube:player_client=android" --sleep-interval 3 -o "%(playlist_index)s - %(title)s.%(ext)s" "PLAYLIST_URL"
```

**Quality Trade-offs:**
- The Android client typically provides 360p-720p quality (good for conference talks, tutorials, lectures)
- More reliable and less likely to be blocked by YouTube
- Good for downloading large playlists where reliability > quality
- For higher quality, try the standard method first; use Android client as fallback

**Tip:** For conference/educational content, 720p is usually sufficient and you'll save storage space!

### Video Unavailable / Private
Use browser cookies:
```bash
yt-dlp --cookies-from-browser firefox "VIDEO_URL"
# or
yt-dlp --cookies-from-browser chrome "VIDEO_URL"
```

### Rate Limited
Add delays between downloads:
```bash
yt-dlp --sleep-interval 5 --max-sleep-interval 30 "PLAYLIST_URL"
```

### Resume Failed Playlist Downloads
If a playlist download fails partway through, use `--download-archive` to skip already downloaded videos:

```bash
# First download (or failed download)
yt-dlp -f "best[ext=mp4]/best" \
  --extractor-args "youtube:player_client=android" \
  --download-archive downloaded.txt \
  --sleep-interval 3 \
  -o "~/Videos/Playlist/%(playlist_index)s - %(title)s.%(ext)s" \
  "PLAYLIST_URL"
```

The `downloaded.txt` file tracks completed downloads. If you run the command again, it will skip videos already in the archive.

### Partial/Corrupted Downloads
Clean up partial downloads before retrying:
```bash
# Remove partial files (*.part)
rm ~/Videos/Playlist/*.part

# Remove incomplete video files
rm ~/Videos/Playlist/*.f299.mp4
rm ~/Videos/Playlist/*.f303.webm
```

## Tips & Best Practices

1. **Always try the standard method first** - It provides better quality (1080p+)
2. **Use Android client as fallback** - If you get HTTP 403 errors
3. **Add sleep intervals for playlists** - Prevents rate limiting (3-5 seconds)
4. **Use download archives for large playlists** - Resume failed downloads easily
5. **Keep yt-dlp updated** - YouTube API changes frequently
6. **Clean partial files before retrying** - Remove `*.part` and `*.f299.mp4` files
7. **For conferences/tutorials** - 720p (Android client) is usually sufficient
8. **Create organized folders** - Use `~/Videos/PlaylistName/` structure

## Quick Reference

```bash
# Single video, highest quality (default)
yt-dlp -f "bestvideo+bestaudio/best" --merge-output-format mp4 "URL"

# Playlist, highest quality (default), numbered files
yt-dlp -f "bestvideo+bestaudio/best" --merge-output-format mp4 \
  -o "%(playlist_index)s - %(title)s.%(ext)s" "URL"

# Playlist with HTTP 403 workaround (if standard method fails)
yt-dlp -f "best[ext=mp4]/best" --extractor-args "youtube:player_client=android" \
  --sleep-interval 3 -o "%(playlist_index)s - %(title)s.%(ext)s" "URL"

# Resume failed playlist download
yt-dlp -f "best[ext=mp4]/best" --extractor-args "youtube:player_client=android" \
  --download-archive downloaded.txt --sleep-interval 3 \
  -o "%(playlist_index)s - %(title)s.%(ext)s" "URL"

# Audio only as MP3
yt-dlp -x --audio-format mp3 "URL"

# List available formats
yt-dlp -F "URL"

# Check yt-dlp version
yt-dlp --version

# Update yt-dlp
pipx upgrade yt-dlp
```
