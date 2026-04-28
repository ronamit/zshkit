# ytdl — YouTube Downloader

A thin wrapper around [yt-dlp](https://github.com/yt-dlp/yt-dlp) that downloads the highest available quality by default and merges video + audio into a single mp4.

## Install

Run the one-time installer — it installs `yt-dlp`, `ffmpeg`, and copies the `ytdl` wrapper to `~/bin`:

```bash
bash ytdlp/setup_ytdlp.sh
```

Works on macOS (via Homebrew) and Ubuntu/Debian (via apt or pip). After it runs, `ytdl` is on your PATH.

## Usage

```bash
ytdl [OPTIONS] URL [URL...]
```

| Option | Description |
| :--- | :--- |
| _(none)_ | Download best video + audio, merged to mp4 |
| `-a` | Audio only — extracts and saves as mp3 |
| `-o DIR` | Output directory (default: current directory) |
| `-p` | Preview available formats without downloading |
| `-h` | Show help |

## Examples

```bash
# Download a video at the highest quality
ytdl https://youtu.be/dQw4w9WgXcQ

# Download audio only (mp3)
ytdl -a https://youtu.be/dQw4w9WgXcQ

# Save to a specific folder
ytdl -o ~/Videos https://youtu.be/dQw4w9WgXcQ

# Download multiple URLs
ytdl URL1 URL2 URL3

# See what formats are available before downloading
ytdl -p https://youtu.be/dQw4w9WgXcQ
```

## Notes

- Files are named `<video title>.mp4` (or `.mp3` for audio).
- Merging video and audio requires **ffmpeg** (`brew install ffmpeg` / `sudo apt install ffmpeg`). If ffmpeg is missing, yt-dlp falls back to the best pre-merged format.
- Works with any yt-dlp-supported site (YouTube, Vimeo, Twitter/X, etc.).
