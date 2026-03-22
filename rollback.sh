#!/bin/bash
# ======================================================================
# rollback.sh — Restore a previous zshkit backup
# ======================================================================
# Usage: bash rollback.sh
# Lists backups under ~/.zsh_backups/, lets you pick one, and restores
# the files that were saved. Uses fzf when available, numbered list otherwise.
# ======================================================================

set -uo pipefail

BACKUP_BASE="$HOME/.zsh_backups"

# ── Check backups exist ───────────────────────────────────────────────

if [ ! -d "$BACKUP_BASE" ]; then
    echo "No backups found — $BACKUP_BASE does not exist."
    exit 1
fi

mapfile -t backups < <(find "$BACKUP_BASE" -mindepth 1 -maxdepth 1 -type d | sort -r)

if [ "${#backups[@]}" -eq 0 ]; then
    echo "No backups found under $BACKUP_BASE."
    exit 1
fi

# ── Select a backup ───────────────────────────────────────────────────

select_with_fzf() {
    printf '%s\n' "${backups[@]}" | \
        fzf --prompt="Select backup to restore > " \
            --height=12 \
            --preview="cat {}/manifest.txt 2>/dev/null || ls -1 {}" \
            --preview-window=right:50%
}

select_numbered() {
    echo "Available backups (newest first):" >&2
    for i in "${!backups[@]}"; do
        ts=$(basename "${backups[$i]}")
        manifest_line=$(head -1 "${backups[$i]}/manifest.txt" 2>/dev/null || echo "")
        echo "  $((i+1))) $ts  $manifest_line" >&2
    done
    echo "" >&2
    read -r -p "Enter number (or q to quit): " choice
    [[ "$choice" == "q" || "$choice" == "Q" ]] && echo "Cancelled." >&2 && exit 0
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#backups[@]}" ]; then
        echo "Invalid selection." >&2 && exit 1
    fi
    echo "${backups[$((choice-1))]}"
}

if command -v fzf &>/dev/null && [ -t 0 ] && [ -t 1 ]; then
    selected=$(select_with_fzf)
else
    selected=$(select_numbered)
fi

[ -z "$selected" ] && echo "Cancelled." && exit 0

# ── Show contents and confirm ─────────────────────────────────────────

echo ""
echo "Selected: $selected"
echo ""
if [ -f "$selected/manifest.txt" ]; then
    cat "$selected/manifest.txt"
else
    echo "Contents:"
    ls -1 "$selected"
fi
echo ""
read -r -p "Restore this backup? [y/N] " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

# ── Restore ───────────────────────────────────────────────────────────

restored=0

restore_file() {
    local src="$1" dest="$2" label="$3"
    if [ -f "$src" ]; then
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        echo "  ✓ Restored $label"
        restored=$((restored+1))
    fi
}

restore_dir() {
    local src="$1" dest="$2" label="$3"
    if [ -d "$src" ]; then
        mkdir -p "$dest"
        cp -R "$src/." "$dest/"
        echo "  ✓ Restored $label"
        restored=$((restored+1))
    fi
}

echo ""
restore_file "$selected/.zshrc"          "$HOME/.zshrc"              "~/.zshrc"
restore_file "$selected/.p10k.zsh"       "$HOME/.p10k.zsh"           "~/.p10k.zsh"
restore_file "$selected/ssh_config"      "$HOME/.ssh/config"         "~/.ssh/config"
restore_dir  "$selected/zellij_config_dir" "$HOME/.config/zellij"   "~/.config/zellij/"

if [ "$restored" -eq 0 ]; then
    echo "  Nothing to restore in this backup."
    exit 1
fi

echo ""
echo "✓ Restored $restored item(s) from $(basename "$selected")."
echo "Open a new terminal (or run: exec zsh) to apply changes."
