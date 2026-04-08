#!/usr/bin/env bash
# generate-screenshots.sh — regenerate all README screenshots via VHS
#
# Usage:
#   cd <repo-root>
#   bash tools/generate-screenshots.sh
#
# Dependencies installed automatically if missing:
#   vhs   v0.11.0  (charmbracelet/vhs)
#   ttyd  1.7.7    (tsl0922/ttyd)
#   ffmpeg         (via apt)
#
# VHS renders each tools/tapes/*.tape into assets/*.gif
# Edit the .tape files to change what's recorded.

set -euo pipefail

# ── Resolve repo root ─────────────────────────────────────────────────
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || { cd "$(dirname "$0")/.." && pwd; })"
cd "$REPO_ROOT"

echo "==> Repo root: $REPO_ROOT"

# ── Dependency versions (pin these for reproducibility) ───────────────
VHS_VERSION="v0.11.0"
TTYD_VERSION="1.7.7"

LOCALBIN="$HOME/.local/bin"
mkdir -p "$LOCALBIN"

# ── Install helpers ───────────────────────────────────────────────────
install_vhs() {
    echo "==> Installing vhs $VHS_VERSION …"
    local tmp; tmp="$(mktemp -d)"
    curl -sL "https://github.com/charmbracelet/vhs/releases/download/${VHS_VERSION}/vhs_${VHS_VERSION#v}_Linux_x86_64.tar.gz" \
        -o "$tmp/vhs.tar.gz"
    tar -xzf "$tmp/vhs.tar.gz" -C "$tmp"
    mv "$tmp/vhs" "$LOCALBIN/vhs"
    chmod +x "$LOCALBIN/vhs"
    rm -rf "$tmp"
    echo "    ✓ vhs $(vhs --version)"
}

install_ttyd() {
    echo "==> Installing ttyd $TTYD_VERSION …"
    curl -sL "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.x86_64" \
        -o "$LOCALBIN/ttyd"
    chmod +x "$LOCALBIN/ttyd"
    echo "    ✓ ttyd $(ttyd --version 2>&1 | head -1)"
}

install_ffmpeg() {
    echo "==> Installing ffmpeg via apt …"
    sudo apt-get install -y ffmpeg
}

# ── Check / install dependencies ──────────────────────────────────────
if ! command -v vhs &>/dev/null; then
    install_vhs
else
    echo "==> vhs: $(vhs --version)"
fi

if ! command -v ttyd &>/dev/null; then
    install_ttyd
else
    echo "==> ttyd: ok"
fi

if ! command -v ffmpeg &>/dev/null; then
    install_ffmpeg
else
    echo "==> ffmpeg: ok"
fi

# ── Pre-seed zoxide database so z-jump demo works ─────────────────────
if command -v zoxide &>/dev/null; then
    zoxide add "$HOME/repos/zshkit" "$HOME/.config/ghostty" "$HOME/.config/zellij" \
               "$HOME/repos/aidoc-cloud-infra" 2>/dev/null || true
    echo "==> zoxide: pre-seeded demo directories"
fi

# ── Generate screenshots ──────────────────────────────────────────────
TAPES_DIR="tools/tapes"
ASSETS_DIR="assets"
mkdir -p "$ASSETS_DIR"

TAPES=(
    hero.tape
    zoxide.tape
)

echo ""
echo "==> Generating screenshots …"
FAILED=()

for tape in "${TAPES[@]}"; do
    tape_path="$TAPES_DIR/$tape"
    if [[ ! -f "$tape_path" ]]; then
        echo "  ✗ Missing: $tape_path"
        FAILED+=("$tape")
        continue
    fi
    echo -n "  → $tape … "
    if vhs "$tape_path" 2>/dev/null; then
        # Extract output filename from tape
        output="$(grep -m1 '^Output ' "$tape_path" | awk '{print $2}')"
        size="$(du -sh "$output" 2>/dev/null | cut -f1)"
        echo "✓  ($size)"
    else
        echo "FAILED"
        FAILED+=("$tape")
    fi
done

# ── Summary ───────────────────────────────────────────────────────────
echo ""
if [[ ${#FAILED[@]} -eq 0 ]]; then
    echo "==> All screenshots generated in $ASSETS_DIR/"
    ls -lh "$ASSETS_DIR"/*.gif 2>/dev/null
else
    echo "==> ${#FAILED[@]} tape(s) failed: ${FAILED[*]}"
    exit 1
fi
