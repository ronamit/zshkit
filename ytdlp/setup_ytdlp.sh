#!/usr/bin/env bash
# One-time installer for yt-dlp + ffmpeg and the ytdl wrapper script.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/bin"

green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
red() { printf '\033[31m%s\033[0m\n' "$*"; }

detect_os() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    else
        echo "other"
    fi
}

install_ytdlp() {
    if command -v yt-dlp &>/dev/null; then
        green "yt-dlp already installed: $(yt-dlp --version)"
        return
    fi

    local os
    os=$(detect_os)

    yellow "Installing yt-dlp..."
    case $os in
        macos)
            if command -v brew &>/dev/null; then
                brew install yt-dlp
            else
                pip3 install --user yt-dlp
            fi
            ;;
        debian)
            # Try apt first (Ubuntu 24.04+); fall back to pip
            if apt-cache show yt-dlp &>/dev/null 2>&1; then
                sudo apt-get install -y yt-dlp
            else
                pip3 install --user yt-dlp
            fi
            ;;
        *)
            pip3 install --user yt-dlp
            ;;
    esac

    green "yt-dlp installed: $(yt-dlp --version)"
}

install_ffmpeg() {
    if command -v ffmpeg &>/dev/null; then
        green "ffmpeg already installed: $(ffmpeg -version 2>&1 | head -1)"
        return
    fi

    local os
    os=$(detect_os)

    yellow "Installing ffmpeg (needed to merge video + audio tracks)..."
    case $os in
        macos)
            if command -v brew &>/dev/null; then
                brew install ffmpeg
            else
                red "Homebrew not found. Install ffmpeg manually: https://ffmpeg.org/download.html"
                return 1
            fi
            ;;
        debian)
            sudo apt-get install -y ffmpeg
            ;;
        *)
            red "Cannot auto-install ffmpeg on this system. Install it manually: https://ffmpeg.org/download.html"
            return 1
            ;;
    esac

    green "ffmpeg installed."
}

install_wrapper() {
    local src="$SCRIPT_DIR/ytdl"
    local dest="$BIN_DIR/ytdl"

    if [[ ! -f "$src" ]]; then
        red "ytdl script not found at $src"
        return 1
    fi

    mkdir -p "$BIN_DIR"
    cp "$src" "$dest"
    chmod +x "$dest"
    green "ytdl wrapper installed to $dest"

    # Warn if ~/bin is not on PATH
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        yellow "Note: $BIN_DIR is not in your PATH."
        yellow "Add this to ~/.zshrc.local or ~/.bashrc:"
        yellow '  export PATH="$HOME/bin:$PATH"'
    fi
}

install_noglob_alias() {
    local zshrc_local="${HOME}/.zshrc.local"
    local alias_line="alias ytdl='noglob ytdl'"

    # noglob prevents zsh from expanding '?' in URLs before passing them to the script
    if grep -qF "$alias_line" "$zshrc_local" 2>/dev/null; then
        green "noglob alias already in $zshrc_local"
        return
    fi

    printf '\n# ytdl: noglob prevents zsh from expanding ? in YouTube URLs\n%s\n' "$alias_line" >> "$zshrc_local"
    green "Added noglob alias to $zshrc_local"
    yellow "Run 'source ~/.zshrc.local' or open a new shell to apply."
}

echo ""
echo "=== ytdl installer ==="
echo ""

install_ytdlp
install_ffmpeg
install_wrapper
install_noglob_alias

echo ""
green "All done. Run: ytdl <youtube-url>"
echo ""
