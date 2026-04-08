#!/bin/bash
# ======================================================================
# ZSH Setup Script (Linux + macOS)
# ======================================================================
# Installs and configures zsh with Oh My Zsh, Powerlevel10k, and plugins.
# Safe to re-run — skips already-installed components.
# - Linux (Debian/Ubuntu): uses apt.
# - macOS: uses Homebrew (install from https://brew.sh if missing).
#
# Usage:  bash setup_zsh.sh [--yes|-y]
#   --yes / -y   skip all confirmation prompts (replace existing configs, install all tools without asking)
#                 On Linux, unattended runs still need non-interactive sudo.
#
# Optional environment (security / maintenance):
#   ZSHKIT_SKIP_ZELLIJ_PERMISSION_SEED=1
#       Do not pre-write ~/.cache/zellij/permissions.kdl — approve plugins inside Zellij (status bar → y).
#       Default seeds permissions so zjstatus runs without a prompt (same as pre–Apr 2026 zshkit).
# ======================================================================

# Fail on undefined variables and pipe errors.
set -uo pipefail

ZSHKIT_YES=0
for _arg in "$@"; do
    case "$_arg" in
        --yes|-y) ZSHKIT_YES=1 ;;
        *) echo "Unknown argument: $_arg"; exit 1 ;;
    esac
done
unset _arg

# Apple Silicon Homebrew is not in default PATH on fresh macOS; ensure brew is available.
if [[ "$(uname -s)" == "Darwin" && -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ── Globals ──────────────────────────────────────────────────────────

# Pin specific versions with env vars; leave unset to auto-fetch latest from GitHub.
# e.g. ZELLIJ_VERSION=v0.44.0 bash setup_zsh.sh
ZELLIJ_VERSION="${ZELLIJ_VERSION:-}"
ZJSTATUS_VERSION="${ZJSTATUS_VERSION:-}"
ZELLIJ_ATTENTION_VERSION="${ZELLIJ_ATTENTION_VERSION:-}"
CARAPACE_VERSION="${CARAPACE_VERSION:-}"

SSH_CONFIG="$HOME/.ssh/config"
SSH_MARKER_BEGIN="# >>> zshkit ssh defaults >>>"
SSH_MARKER_END="# <<< zshkit ssh defaults <<<"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ZSHRC_TEMPLATE="$SCRIPT_DIR/.zshrc.template.sh"
ZELLIJ_METRICS_TEMPLATE="$SCRIPT_DIR/zellij-metrics.sh"
ZELLIJ_CONFIG_TEMPLATE="$SCRIPT_DIR/templates/zellij/config.kdl.template"
ZELLIJ_LAYOUT_TEMPLATE="$SCRIPT_DIR/templates/zellij/layouts/default.kdl"
GHOSTTY_CONFIG_TEMPLATE="$SCRIPT_DIR/templates/ghostty/config.template"
P10K_TEMPLATE="$SCRIPT_DIR/templates/p10k.zsh.template"
VPN_SOURCE_DIR="$SCRIPT_DIR/vpn"
BACKUP_BASE="$HOME/.zsh_backups"
BACKUP_DIR="$BACKUP_BASE/$(date +%Y%m%d_%H%M%S)"
# Set when ~/.config/ghostty/config is replaced and a backup is created
GHOSTTY_BACKUP_PATH=""
# Set when ~/.p10k.zsh is replaced and a backup is created
P10K_BACKUP_PATH=""
STEP=0

# OS detection
if [[ "$(uname -s)" == "Darwin" ]]; then
    IS_MACOS=1
else
    IS_MACOS=0
fi

APT_PACKAGES_TO_INSTALL=()
APT_INDEX_REFRESHED=0
BREW_FORMULAS_TO_INSTALL=()

# ── Helpers ──────────────────────────────────────────────────────────

step() { STEP=$((STEP + 1)); echo ""; echo "[$STEP] $1"; }

# Fetch the latest release tag from a GitHub repo (e.g. "zellij-org/zellij").
# Prints the tag (e.g. "v0.44.0") to stdout, or $2 if the API call fails.
gh_latest_version() {
    local repo="$1" fallback="$2"
    local tag
    tag=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null \
        | grep -m1 '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    if [ -n "$tag" ]; then
        echo "$tag"
    else
        echo "  ⚠ Could not fetch latest version for ${repo}, using fallback ${fallback}" >&2
        echo "$fallback"
    fi
}

# Prompt the user to confirm before installing a tool.
# In --yes mode or non-interactive shells, proceeds automatically.
# Returns 1 if the user declines.
confirm_install() {
    local msg="$1"
    [ "$ZSHKIT_YES" -eq 1 ] && return 0
    [ -t 0 ] || return 0
    printf "  %s [y/N] " "$msg"
    local _ci_reply
    read -r _ci_reply </dev/tty
    case "$_ci_reply" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) echo "  - Skipped"; return 1 ;;
    esac
}

require_noninteractive_sudo_for_yes_mode() {
    [ "$IS_MACOS" -eq 1 ] && return 0
    [ "$ZSHKIT_YES" -eq 1 ] || return 0

    if ! command -v sudo &>/dev/null; then
        echo "Error: setup_zsh.sh --yes on Linux requires sudo for package and terminfo setup."
        echo "       Install sudo, or run the script interactively without --yes."
        exit 1
    fi

    if ! sudo -n true 2>/dev/null; then
        echo "Error: setup_zsh.sh --yes on Linux needs non-interactive sudo for apt/terminfo steps."
        echo "       Prefer: rerun without --yes and enter your password when apt runs."
        echo "       Or: use a dedicated provisioning path (e.g. short-lived NOPASSWD for this script only),"
        echo "       not blanket passwordless sudo — that widens the blast radius if your user account is compromised."
        exit 1
    fi
}

apt_update_once() {
    if [ "$APT_INDEX_REFRESHED" -eq 0 ]; then
        echo "  Refreshing apt package index..."
        if sudo apt-get update -qq; then
            APT_INDEX_REFRESHED=1
        else
            echo "  ✗ apt-get update failed"
            exit 1
        fi
    fi
}

pkg_is_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

apt_pkg_exists() {
    local pkg="$1"
    if apt-cache show "$pkg" &>/dev/null; then
        return 0
    fi
    if [ "$APT_INDEX_REFRESHED" -eq 0 ]; then
        apt_update_once
        if apt-cache show "$pkg" &>/dev/null; then return 0; fi
    fi
    return 1
}

add_pkg() {
    local pkg="$1"
    [ -z "$pkg" ] && return 0
    pkg_is_installed "$pkg" && return 0
    for existing in "${APT_PACKAGES_TO_INSTALL[@]+"${APT_PACKAGES_TO_INSTALL[@]}"}"; do
        [ "$existing" = "$pkg" ] && return 0
    done
    APT_PACKAGES_TO_INSTALL+=("$pkg")
}

add_pkg_if_missing_cmd() {
    local cmd="$1" pkg="$2"
    command -v "$cmd" &>/dev/null || add_pkg "$pkg"
}

add_best_effort_pkg_if_missing_cmd() {
    local cmd="$1" pkg="$2"
    command -v "$cmd" &>/dev/null && return 0
    pkg_is_installed "$pkg" && return 0
    if apt_pkg_exists "$pkg"; then
        add_pkg "$pkg"
    else
        echo "  - Skipping $pkg (not found in apt)"
    fi
}

add_best_effort_pkg() {
    local pkg="$1"
    pkg_is_installed "$pkg" && return 0
    if apt_pkg_exists "$pkg"; then
        add_pkg "$pkg"
    else
        echo "  - Skipping $pkg (not found in apt)"
    fi
}

backup_file_if_exists() {
    local src="$1" dest="$2"
    if [ -f "$src" ]; then
        mkdir -p "$BACKUP_DIR"
        cp "$src" "$dest"
        echo "  ✓ Backup → $dest"
    fi
}

backup_dir_if_exists() {
    local src="$1" dest="$2"
    if [ -d "$src" ]; then
        mkdir -p "$BACKUP_DIR"
        cp -R "$src" "$dest"
        echo "  ✓ Backup → $dest"
    fi
}

# Install ~/.p10k.zsh from zshkit's templates/p10k.zsh.template (maintainer's Powerlevel10k export).
# Backs up an existing file to $BACKUP_DIR/.p10k.zsh. Sets P10K_BACKUP_PATH when a backup is created.
install_home_p10k_zsh() {
    local src="$P10K_TEMPLATE"
    local target="$HOME/.p10k.zsh"
    local tmp

    P10K_BACKUP_PATH=""
    if [ ! -f "$src" ]; then
        echo "  ✗ Missing Powerlevel10k template: $src"
        return 1
    fi

    tmp=$(mktemp)
    if ! cp "$src" "$tmp"; then
        rm -f "$tmp"
        echo "  ✗ Failed to read Powerlevel10k template"
        return 1
    fi

    if [ -f "$target" ]; then
        if [ "$ZSHKIT_YES" -eq 0 ] && [ -t 0 ]; then
            printf "  ~/.p10k.zsh already exists. Replace with zshkit template? [y/N] "
            read -r _p10k_reply </dev/tty
            case "$_p10k_reply" in
                [Yy]|[Yy][Ee][Ss]) ;;
                *)
                    rm -f "$tmp"
                    echo "  - Keeping existing ~/.p10k.zsh"
                    return 0
                    ;;
            esac
        fi
        if ! mkdir -p "$BACKUP_DIR"; then
            rm -f "$tmp"
            echo "  ✗ Failed to create backup directory: $BACKUP_DIR"
            return 1
        fi
        P10K_BACKUP_PATH="$BACKUP_DIR/.p10k.zsh"
        if ! cp "$target" "$P10K_BACKUP_PATH"; then
            rm -f "$tmp"
            echo "  ✗ Failed to back up ~/.p10k.zsh"
            return 1
        fi
        echo "  ✓ Backup → $P10K_BACKUP_PATH"
    fi

    if ! mv "$tmp" "$target"; then
        rm -f "$tmp"
        echo "  ✗ Failed to install ~/.p10k.zsh"
        return 1
    fi
    echo "  ✓ Installed ~/.p10k.zsh from zshkit template"
    return 0
}

# Install the Ghostty config from a zshkit template into ~/.config/ghostty/.
# Backs up an existing file into $BACKUP_DIR and records the backup path in
# GHOSTTY_LAST_BACKUP_PATH for the caller to store.
install_home_ghostty_template() {
    local src="$1"
    local target="$2"
    local display_target="$3"
    local tmp

    GHOSTTY_LAST_BACKUP_PATH=""
    if [ ! -f "$src" ]; then
        echo "  ✗ Missing Ghostty template: $src"
        return 1
    fi

    tmp=$(mktemp)
    if ! cp "$src" "$tmp"; then
        rm -f "$tmp"
        echo "  ✗ Failed to read Ghostty template"
        return 1
    fi

    mkdir -p "$(dirname "$target")"

    if [ -f "$target" ]; then
        if [ "$ZSHKIT_YES" -eq 0 ] && [ -t 0 ]; then
            printf "  %s already exists. Replace with zshkit template? [y/N] " "$display_target"
            read -r _ghostty_reply </dev/tty
            case "$_ghostty_reply" in
                [Yy]|[Yy][Ee][Ss]) ;;
                *)
                    rm -f "$tmp"
                    echo "  - Keeping existing $display_target"
                    return 0
                    ;;
            esac
        fi
        if ! mkdir -p "$BACKUP_DIR"; then
            rm -f "$tmp"
            echo "  ✗ Failed to create backup directory: $BACKUP_DIR"
            return 1
        fi
        GHOSTTY_LAST_BACKUP_PATH="$BACKUP_DIR/$(basename "$target")"
        if ! cp "$target" "$GHOSTTY_LAST_BACKUP_PATH"; then
            rm -f "$tmp"
            echo "  ✗ Failed to back up $display_target"
            return 1
        fi
        echo "  ✓ Backup → $GHOSTTY_LAST_BACKUP_PATH"
    fi

    if ! mv "$tmp" "$target"; then
        rm -f "$tmp"
        echo "  ✗ Failed to install $display_target"
        return 1
    fi
    echo "  ✓ Installed $display_target from zshkit template"
    return 0
}

install_home_ghostty_conf() {
    GHOSTTY_BACKUP_PATH=""
    if ! install_home_ghostty_template \
        "$GHOSTTY_CONFIG_TEMPLATE" \
        "$HOME/.config/ghostty/config" \
        "~/.config/ghostty/config"; then
        return 1
    fi
    GHOSTTY_BACKUP_PATH="$GHOSTTY_LAST_BACKUP_PATH"
}

template_must_exist() {
    local path="$1"
    if [ ! -f "$path" ]; then
        echo "  ✗ Missing template: $path"
        exit 1
    fi
}

render_template_to_file() {
    local src="$1" dest="$2"
    local tmp_current tmp_next placeholder value escaped_value
    shift 2

    template_must_exist "$src"
    tmp_current=$(mktemp)
    cp "$src" "$tmp_current"

    while [ "$#" -gt 0 ]; do
        placeholder="$1"
        value="$2"
        shift 2
        escaped_value=$(printf '%s' "$value" | sed 's/[&|\\]/\\&/g')
        tmp_next=$(mktemp)
        sed "s|$placeholder|$escaped_value|g" "$tmp_current" > "$tmp_next"
        rm -f "$tmp_current"
        tmp_current="$tmp_next"
    done

    mv "$tmp_current" "$dest"
}

download_to_file() {
    local url="$1" dest="$2"
    local curl_bin=""

    if [ -x /usr/bin/curl ]; then
        curl_bin="/usr/bin/curl"
    elif command -v curl &>/dev/null; then
        curl_bin="$(command -v curl)"
    fi

    if [ -n "$curl_bin" ]; then
        if "$curl_bin" -fsSL "$url" -o "$dest"; then
            [ -s "$dest" ] && return 0
            rm -f "$dest"
        else
            rm -f "$dest"
        fi
    fi

    if command -v wget &>/dev/null; then
        if wget -q -O "$dest" "$url"; then
            [ -s "$dest" ] && return 0
            rm -f "$dest"
        else
            rm -f "$dest"
        fi
    fi

    return 1
}

install_ghostty() {
    step "Installing Ghostty..."

    if [ "$IS_MACOS" -eq 1 ]; then
        if brew list --cask ghostty &>/dev/null 2>&1; then
            echo "  ✓ Ghostty is already installed via Homebrew"
        elif confirm_install "Install Ghostty (Homebrew cask)?"; then
            if ! brew install --cask ghostty; then
                echo "  ✗ Failed to install Ghostty via Homebrew"
                exit 1
            fi
            echo "  ✓ Ghostty installed"
        fi
    else
        if command -v ghostty &>/dev/null; then
            echo "  ✓ Ghostty is already installed — skipping"
            return 0
        fi
        # Ubuntu: snap is officially listed on ghostty.org and works across Ubuntu versions.
        if command -v snap &>/dev/null; then
            if confirm_install "Install Ghostty (snap)?"; then
                if ! snap install ghostty --classic; then
                    echo "  ✗ Failed to install Ghostty via snap"
                    exit 1
                fi
                echo "  ✓ Ghostty installed via snap"
            fi
        else
            echo "  ⚠ snap not found — install Ghostty manually:"
            echo "    snap: snap install ghostty --classic"
            echo "    .deb: bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)\""
        fi
    fi
}

install_brew_formula_if_missing() {
    local cmd="$1" formula="$2"
    if command -v "$cmd" &>/dev/null; then
        return 0
    fi
    echo "  Installing Homebrew formula: $formula"
    if brew install "$formula"; then
        return 0
    else
        echo "  ✗ Failed to install Homebrew formula: $formula"
        exit 1
    fi
}

# Queue a Homebrew formula for batched installation (skips if cmd already exists).
add_brew() {
    local cmd="$1" formula="$2"
    command -v "$cmd" &>/dev/null && return 0
    local f
    for f in "${BREW_FORMULAS_TO_INSTALL[@]+"${BREW_FORMULAS_TO_INSTALL[@]}"}"; do
        [ "$f" = "$formula" ] && return 0
    done
    BREW_FORMULAS_TO_INSTALL+=("$formula")
}

# Install all queued Homebrew formulas in a single brew install call.
flush_brew_installs() {
    if [ "${#BREW_FORMULAS_TO_INSTALL[@]}" -eq 0 ]; then
        echo "  ✓ All Homebrew packages already installed"
        return 0
    fi
    echo "  Formulas to install: ${BREW_FORMULAS_TO_INSTALL[*]}"
    if confirm_install "Install these Homebrew formulas?"; then
        if brew install "${BREW_FORMULAS_TO_INSTALL[@]}"; then
            BREW_FORMULAS_TO_INSTALL=()
        else
            echo "  ✗ brew install failed for: ${BREW_FORMULAS_TO_INSTALL[*]}"
            exit 1
        fi
    fi
}

clone_if_missing() {
    local label="$1" url="$2" dir="$3" name="$4"
    step "$label"
    if [ -d "$dir" ]; then
        echo "  ✓ $name already installed"
    elif confirm_install "Install $name?"; then
        if git clone --depth=1 "$url" "$dir"; then
            echo "  ✓ $name installed"
        else
            echo "  ✗ Failed to clone $name from $url"
            exit 1
        fi
    fi
}

has_meslo_nerd_font() {
    if command -v fc-list &>/dev/null && fc-list 2>/dev/null | grep -qi 'MesloLGS'; then
        return 0
    fi
    compgen -G "$HOME/.local/share/fonts/MesloLGS*.ttf" >/dev/null 2>&1 && return 0
    # macOS Homebrew cask or user fonts
    compgen -G "$HOME/Library/Fonts/MesloLGS*.ttf" >/dev/null 2>&1 && return 0
    return 1
}

create_zshrc_local_template() {
    cat > "$HOME/.zshrc.local" << 'EOF'
# ~/.zshrc.local — Personal settings (not managed by setup_zsh.sh)
# Add exports, tokens, and machine-specific overrides here.
# Toggle live auto-list while typing (cd/path suggestions):
# export ZSH_AUTOLIST_ON_TYPE=1   # 1=on (default), 0=off
# Auto-open `cd ` list only when local dir count is small:
# export ZSH_AUTOLIST_CD_EMPTY_MAX=20
# Min characters before auto-list (reduces lag on slow filesystems):
# export ZSH_AUTOLIST_MIN_CHARS=3

# export GITHUB_TOKEN="ghp_xxxxx"
# export OPENAI_API_KEY="sk-xxxxx"
# export HF_TOKEN="hf_xxxxx"

# ── VPN helper (type `vpn-connect`, `vpn-status`, or `sshv`) ──
# export ZSHKIT_VPN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zshkit/vpn"
# export ZSHKIT_VPN_CONFIG_FILE="$HOME/client.ovpn"
# export ZSHKIT_VPN_CREDENTIALS_FILE="/path/to/vpn-credentials.txt"
# export ZSHKIT_VPN_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/zshkit/vpn"

# ── EC2 VM helper (type `vm` for usage) ──
# export EC2_SSH_HOST="myserver"           # hostname/IP — set this to SSH directly, no AWS needed
# export EC2_SSH_USER="ubuntu"
# export EC2_SSH_KEY="$HOME/.ssh/my-key.pem"
# export EC2_INSTANCE_ID="i-0abc123..."   # add for start/stop/status via AWS
# export EC2_REGION="us-east-2"
# export EC2_AWS_PROFILE="my-profile"
EOF
    echo "  ✓ Created ~/.zshrc.local template"
}

vpn_managed_dir() {
    if [ "$IS_MACOS" -eq 1 ]; then
        printf '%s' "$HOME/Library/Application Support/zshkit/vpn"
    else
        printf '%s' "${XDG_DATA_HOME:-$HOME/.local/share}/zshkit/vpn"
    fi
}

vpn_state_dir() {
    if [ "$IS_MACOS" -eq 1 ]; then
        printf '%s' "$(vpn_managed_dir)/state"
    else
        printf '%s' "${XDG_STATE_HOME:-$HOME/.local/state}/zshkit/vpn"
    fi
}

install_vpn_bundle() {
    local managed_dir state_dir creds_file src_file
    local file
    managed_dir="$(vpn_managed_dir)"
    state_dir="$(vpn_state_dir)"
    creds_file="$managed_dir/vpn-credentials.txt"

    mkdir -p "$managed_dir" "$state_dir" "$HOME/.local/bin"
    chmod 700 "$state_dir" 2>/dev/null || true

    for file in vpn-common.sh vpn-connect.sh vpn-disconnect.sh vpn-status.sh vpn-credentials.txt.template; do
        src_file="$VPN_SOURCE_DIR/$file"
        if [ ! -f "$src_file" ]; then
            echo "  ✗ Missing VPN helper source: $src_file"
            exit 1
        fi
        cp "$src_file" "$managed_dir/$file"
        case "$file" in
            *.sh) chmod +x "$managed_dir/$file" ;;
        esac
    done

    if [ ! -f "$creds_file" ]; then
        cp "$managed_dir/vpn-credentials.txt.template" "$creds_file"
        chmod 600 "$creds_file"
        echo "  ✓ Created VPN credentials placeholder: $creds_file"
    else
        echo "  ✓ Preserved VPN credentials file: $creds_file"
    fi

    ln -sf "$managed_dir/vpn-connect.sh" "$HOME/.local/bin/vpn-connect"
    ln -sf "$managed_dir/vpn-disconnect.sh" "$HOME/.local/bin/vpn-disconnect"
    ln -sf "$managed_dir/vpn-status.sh" "$HOME/.local/bin/vpn-status"
    echo "  ✓ Installed VPN helper commands in ~/.local/bin"
}

# ── Pre-flight ───────────────────────────────────────────────────────

echo "======================================================================"
if [ "$IS_MACOS" -eq 1 ]; then
    echo "ZSH Setup (macOS)"
else
    echo "ZSH Setup (Linux)"
fi
echo "======================================================================"

if [ ! -f "$ZSHRC_TEMPLATE" ]; then
    echo "Error: Missing .zshrc.template.sh at $ZSHRC_TEMPLATE"
    exit 1
fi

if [ "$IS_MACOS" -eq 1 ]; then
    if ! command -v brew &>/dev/null; then
        echo "Error: Homebrew not found. Install from https://brew.sh then re-run."
        exit 1
    fi
else
    if ! command -v apt-get &>/dev/null; then
        echo "Error: apt-get not found. This script supports Ubuntu/Debian or macOS (Homebrew)."
        exit 1
    fi
    # Prepend ~/.local/bin so symlinks created later in this script (e.g. fd →
    # fdfind) are immediately usable by subsequent steps in the same process.
    export PATH="$HOME/.local/bin:$PATH"
fi

require_noninteractive_sudo_for_yes_mode

# ── Resolve latest tool versions from GitHub ─────────────────────────

step "Resolving latest tool versions from GitHub..."
[ -z "$ZELLIJ_VERSION" ]           && ZELLIJ_VERSION=$(gh_latest_version "zellij-org/zellij" "v0.44.0")
[ -z "$ZJSTATUS_VERSION" ]         && ZJSTATUS_VERSION=$(gh_latest_version "dj95/zjstatus" "v0.22.0")
[ -z "$ZELLIJ_ATTENTION_VERSION" ] && ZELLIJ_ATTENTION_VERSION=$(gh_latest_version "KiryuuLight/zellij-attention" "v0.3.1")
[ -z "$CARAPACE_VERSION" ]         && CARAPACE_VERSION=$(gh_latest_version "carapace-sh/carapace-bin" "v1.6.4")
echo "  Zellij:            $ZELLIJ_VERSION"
echo "  zjstatus:          $ZJSTATUS_VERSION"
echo "  zellij-attention:  $ZELLIJ_ATTENTION_VERSION"
echo "  carapace-bin:      $CARAPACE_VERSION"

# ── Bootstrap: zsh, curl, git ────────────────────────────────────────

step "Installing core dependencies (zsh, curl, git)..."
if [ "$IS_MACOS" -eq 1 ]; then
    add_brew zsh zsh
    add_brew curl curl
    add_brew git git
    flush_brew_installs
    echo "  ✓ Core tools checked (Homebrew)"
else
BOOTSTRAP=()
command -v zsh  &>/dev/null || BOOTSTRAP+=("zsh")
command -v curl &>/dev/null || BOOTSTRAP+=("curl")
command -v git  &>/dev/null || BOOTSTRAP+=("git")

if [ "${#BOOTSTRAP[@]}" -gt 0 ]; then
    apt_update_once
    if sudo apt-get install -y "${BOOTSTRAP[@]}"; then
        echo "  ✓ Installed: ${BOOTSTRAP[*]}"
    else
        echo "  ✗ Failed to install bootstrap packages: ${BOOTSTRAP[*]}"
        exit 1
    fi
else
    echo "  ✓ zsh, curl, git already present"
fi
fi

# ── Oh My Zsh ────────────────────────────────────────────────────────

step "Installing Oh My Zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "  ✓ Oh My Zsh already installed"
elif confirm_install "Install Oh My Zsh?"; then
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
        echo "  ✓ Oh My Zsh installed"
    else
        echo "  ✗ Failed to install Oh My Zsh"
        exit 1
    fi
fi

# ── Plugins & Theme ──────────────────────────────────────────────────

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

clone_if_missing "Powerlevel10k theme" \
    "https://github.com/romkatv/powerlevel10k.git" \
    "$ZSH_CUSTOM/themes/powerlevel10k" "Powerlevel10k"

clone_if_missing "zsh-autosuggestions" \
    "https://github.com/zsh-users/zsh-autosuggestions.git" \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions" "zsh-autosuggestions"

clone_if_missing "fast-syntax-highlighting" \
    "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" \
    "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" "fast-syntax-highlighting"

clone_if_missing "zsh-history-substring-search" \
    "https://github.com/zsh-users/zsh-history-substring-search.git" \
    "$ZSH_CUSTOM/plugins/zsh-history-substring-search" "zsh-history-substring-search"

clone_if_missing "zsh-defer" \
    "https://github.com/romkatv/zsh-defer.git" \
    "$ZSH_CUSTOM/plugins/zsh-defer" "zsh-defer"

# ── APT packages (Linux) ──────────────────────────────────────────────

step "Collecting required/recommended packages..."
if [ "$IS_MACOS" -eq 1 ]; then
    add_brew fzf fzf
    add_brew tree tree
    add_brew zellij zellij
    add_brew screen screen
    add_brew openvpn openvpn
    add_brew rg ripgrep
    add_brew fd fd
    add_brew bat bat
    add_brew lsd lsd
    add_brew zoxide zoxide
    add_brew lazygit lazygit
    add_brew fastfetch fastfetch
    # Modern terminal file manager (recommended over ranger)
    add_brew yazi yazi
    # Interactive disk usage analyzer
    add_brew ncdu ncdu
    # Modern terminal text editor
    add_brew micro micro
    # Git diff pager (syntax-highlighted diffs)
    add_brew delta git-delta
    # JSON processor
    add_brew jq jq
    # Per-project environment variables
    add_brew direnv direnv
    # GitHub CLI
    add_brew gh gh
    # Python package manager (fast drop-in for pip/venv)
    add_brew uv uv
    # Interactive cheatsheet tool with fzf widget
    add_brew navi navi
    flush_brew_installs
else

# Core tools
add_pkg_if_missing_cmd wget  wget
add_pkg_if_missing_cmd unzip unzip
add_pkg_if_missing_cmd curl  curl
add_pkg_if_missing_cmd fc-cache fontconfig
add_pkg_if_missing_cmd tic ncurses-bin

# CLI tools used by aliases/functions
add_pkg_if_missing_cmd fzf  fzf
add_pkg_if_missing_cmd tree tree
add_pkg_if_missing_cmd rg   ripgrep
add_best_effort_pkg_if_missing_cmd lsd lsd

if ! command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    add_pkg "fd-find"
fi
if ! command -v bat &>/dev/null && ! command -v batcat &>/dev/null; then
    add_pkg "bat"
fi

# Port inspection
if ! command -v ss &>/dev/null && ! command -v netstat &>/dev/null; then
    add_best_effort_pkg iproute2
fi

# Python quality-of-life
if ! command -v python &>/dev/null; then
    if apt_pkg_exists python-is-python3; then
        add_pkg "python-is-python3"
    else
        add_best_effort_pkg python3
    fi
fi
add_best_effort_pkg_if_missing_cmd pip3 python3-pip
add_best_effort_pkg python3-venv

# Archive helpers for extract()
add_best_effort_pkg_if_missing_cmd 7z p7zip-full
if ! command -v unrar &>/dev/null; then
    if apt_pkg_exists unrar; then
        add_pkg "unrar"
    elif apt_pkg_exists unrar-free; then
        add_pkg "unrar-free"
    fi
fi

# Oh My Zsh command-not-found backend
add_best_effort_pkg_if_missing_cmd command-not-found command-not-found

# Optional enhancements
add_best_effort_pkg fonts-powerline
add_best_effort_pkg_if_missing_cmd eza eza
if ! command -v delta &>/dev/null; then
    add_best_effort_pkg git-delta
fi

# Navigation, git TUI, system info
add_best_effort_pkg_if_missing_cmd zoxide zoxide
add_best_effort_pkg_if_missing_cmd lazygit lazygit
add_best_effort_pkg_if_missing_cmd fastfetch fastfetch
add_best_effort_pkg_if_missing_cmd screen screen
add_best_effort_pkg_if_missing_cmd openvpn openvpn

# Modern terminal file manager (recommended over ranger)
add_best_effort_pkg_if_missing_cmd yazi yazi
# Interactive disk usage analyzer
add_best_effort_pkg_if_missing_cmd ncdu ncdu
# Modern terminal text editor
add_best_effort_pkg_if_missing_cmd micro micro

# Data tools and workflow helpers
add_pkg_if_missing_cmd jq jq
add_best_effort_pkg_if_missing_cmd direnv direnv
add_best_effort_pkg_if_missing_cmd gh gh
# Interactive GPU process monitor
add_best_effort_pkg_if_missing_cmd nvtop nvtop

# Clipboard helpers (used by micro editor)
if ! command -v xclip &>/dev/null && ! command -v wl-copy &>/dev/null; then
    add_best_effort_pkg xclip
    add_best_effort_pkg wl-clipboard
fi

if [ "${#APT_PACKAGES_TO_INSTALL[@]}" -gt 0 ]; then
    echo "  Packages to install: ${APT_PACKAGES_TO_INSTALL[*]}"
    if confirm_install "Install these apt packages?"; then
        apt_update_once
        if sudo apt-get install -y "${APT_PACKAGES_TO_INSTALL[@]}"; then
            echo "  ✓ Packages installed"
        else
            echo "  ✗ Failed to install one or more packages"
            exit 1
        fi
    fi
else
    echo "  ✓ All packages already present"
fi

# Use OSC 52 clipboard so copy works inside Zellij/SSH (wl-copy loses clipboard when micro exits)
# micro settings: use external clipboard (xclip shim routes to wl-copy on Wayland)
# keymenu shows a key binding bar at the bottom of the editor.
_micro_settings="$HOME/.config/micro/settings.json"
mkdir -p "$(dirname "$_micro_settings")"
if [ ! -f "$_micro_settings" ]; then
    printf '{\n    "clipboard": "external",\n    "keymenu": true\n}\n' > "$_micro_settings"
    echo "  ✓ Wrote micro settings (clipboard: external, keymenu: true)"
else
    _micro_updated=0
    if ! grep -q '"clipboard"' "$_micro_settings"; then
        jq '. + {"clipboard": "external"}' "$_micro_settings" > "${_micro_settings}.tmp" \
            && mv "${_micro_settings}.tmp" "$_micro_settings" \
            && _micro_updated=1
    fi
    if ! grep -q '"keymenu"' "$_micro_settings"; then
        jq '. + {"keymenu": true}' "$_micro_settings" > "${_micro_settings}.tmp" \
            && mv "${_micro_settings}.tmp" "$_micro_settings" \
            && _micro_updated=1
    fi
    (( _micro_updated )) && echo "  ✓ Updated micro settings" || echo "  ✓ micro settings already up to date"
fi

# xclip shim (Linux): on Wayland, real xclip only reaches the X11 clipboard; Wayland apps can't see it.
# Install unconditionally so headless/SSH/tmux installs still get the shim; Wayland vs X11 is decided at runtime.
if [ "$IS_MACOS" -eq 0 ]; then
    _xclip_shim="$HOME/.local/bin/xclip"
    mkdir -p "$(dirname "$_xclip_shim")"
    cat > "$_xclip_shim" << 'XCLIP_SHIM'
#!/bin/bash
# Delegate to system xclip unless we are on Wayland with wl-clipboard available.
if [[ -z "${WAYLAND_DISPLAY:-}" ]] || ! command -v wl-copy &>/dev/null || ! command -v wl-paste &>/dev/null; then
    exec /usr/bin/xclip "$@"
fi
_is_read=false
_selection=""
_expect_selection_value=false
for _arg in "$@"; do
    if $_expect_selection_value; then
        _selection="$_arg"
        _expect_selection_value=false
        continue
    fi
    case "$_arg" in
        -o) _is_read=true ;;
        -selection|-sel) _expect_selection_value=true ;;
        clipboard|primary) _selection="$_arg" ;;
    esac
done

if [[ "$_selection" == "clipboard" && $_is_read == true ]]; then
    exec wl-paste --no-newline
elif [[ "$_selection" == "clipboard" ]]; then
    exec wl-copy
elif [[ "$_selection" == "primary" && $_is_read == true ]]; then
    exec wl-paste --no-newline --primary
elif [[ "$_selection" == "primary" ]]; then
    exec wl-copy --primary
else
    exec /usr/bin/xclip "$@"
fi
XCLIP_SHIM
    chmod +x "$_xclip_shim"
    echo "  ✓ Installed xclip shim at $_xclip_shim (routes to wl-copy when Wayland + wl-clipboard are active)"
fi

# yazi often not in apt on older Ubuntu/Debian; try snap if still missing (--classic required)
if ! command -v yazi &>/dev/null && command -v snap &>/dev/null; then
    if confirm_install "Install yazi (snap, not in apt)?"; then
        echo "  Installing yazi via snap..."
        if sudo snap install yazi --classic 2>/dev/null; then
            echo "  ✓ yazi installed via snap"
        else
            echo "  - yazi snap install failed; install manually: sudo snap install yazi --classic"
        fi
    fi
fi

# uv: not in apt; install via the official installer to ~/.local/bin/uv
if ! command -v uv &>/dev/null; then
    if confirm_install "Install uv Python package manager?"; then
        echo "  Installing uv Python package manager..."
        if curl -LsSf https://astral.sh/uv/install.sh | sh; then
            echo "  ✓ uv installed"
        else
            echo "  ⚠ uv install failed — install manually: curl -LsSf https://astral.sh/uv/install.sh | sh"
        fi
    fi
else
    echo "  ✓ uv already installed"
fi

# navi: not in apt; install via the official installer to ~/.local/bin/navi
if ! command -v navi &>/dev/null; then
    if confirm_install "Install navi interactive cheatsheet tool?"; then
        echo "  Installing navi interactive cheatsheet tool..."
        if BIN_DIR="$HOME/.local/bin" bash <(curl -sL https://raw.githubusercontent.com/denisidoro/navi/master/scripts/install) 2>/dev/null; then
            echo "  ✓ navi installed"
        else
            echo "  ⚠ navi install failed — install manually: BIN_DIR=~/.local/bin bash <(curl -sL https://raw.githubusercontent.com/denisidoro/navi/master/scripts/install)"
        fi
    fi
else
    echo "  ✓ navi already installed"
fi

fi

_carapace_installed_version="$(carapace --version 2>/dev/null | awk '{print $2}')"
if [ "$_carapace_installed_version" != "${CARAPACE_VERSION#v}" ]; then
    step "Installing carapace-bin ${CARAPACE_VERSION}..."
    if confirm_install "Install carapace-bin ${CARAPACE_VERSION}?"; then
        mkdir -p "$HOME/.local/bin"
        if [ "$IS_MACOS" -eq 1 ]; then
            install_brew_formula_if_missing carapace carapace-sh/carapace/carapace
        else
            case "$(uname -m)" in
                x86_64|amd64) _carapace_arch="amd64" ;;
                aarch64|arm64) _carapace_arch="arm64" ;;
                *)
                    echo "  ✗ Unsupported architecture for carapace auto-install: $(uname -m)"
                    exit 1
                    ;;
            esac
            _carapace_tar="${TMPDIR:-/tmp}/carapace.tar.gz"
            _carapace_url="https://github.com/carapace-sh/carapace-bin/releases/download/${CARAPACE_VERSION}/carapace-bin_${CARAPACE_VERSION#v}_linux_${_carapace_arch}.tar.gz"
            if download_to_file "$_carapace_url" "$_carapace_tar" \
                && tar -xzf "$_carapace_tar" -C "$HOME/.local/bin" carapace \
                && chmod +x "$HOME/.local/bin/carapace" \
                && [ -x "$HOME/.local/bin/carapace" ]; then
                echo "  ✓ Installed carapace-bin ${CARAPACE_VERSION}"
            else
                echo "  ✗ Failed to download carapace-bin ${CARAPACE_VERSION} for ${_carapace_arch}"
                rm -f "$_carapace_tar"
                rm -f "$HOME/.local/bin/carapace"
                exit 1
            fi
            rm -f "$_carapace_tar"
        fi
    fi
else
    echo "  ✓ carapace-bin ${CARAPACE_VERSION} already installed"
fi

_zellij_installed_version="$(zellij --version 2>/dev/null | awk '{print $2}')"
if [ "$IS_MACOS" -eq 0 ] && [ "$_zellij_installed_version" != "${ZELLIJ_VERSION#v}" ]; then
    step "Installing Zellij ${ZELLIJ_VERSION}..."
    if confirm_install "Install Zellij ${ZELLIJ_VERSION}?"; then
        mkdir -p "$HOME/.local/bin"
        case "$(uname -m)" in
            x86_64|amd64) _zellij_arch="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) _zellij_arch="aarch64-unknown-linux-musl" ;;
            *)
                echo "  ✗ Unsupported Linux architecture for Zellij auto-install: $(uname -m)"
                exit 1
                ;;
        esac
        _zellij_tar="${TMPDIR:-/tmp}/zellij.tar.gz"
        _zellij_url="https://github.com/zellij-org/zellij/releases/download/${ZELLIJ_VERSION}/zellij-${_zellij_arch}.tar.gz"
        if download_to_file "$_zellij_url" "$_zellij_tar" \
            && tar -xzf "$_zellij_tar" -C "$HOME/.local/bin" zellij \
            && chmod +x "$HOME/.local/bin/zellij" \
            && [ -x "$HOME/.local/bin/zellij" ]; then
            echo "  ✓ Installed Zellij ${ZELLIJ_VERSION}"
        else
            echo "  ✗ Failed to download Zellij ${ZELLIJ_VERSION} for ${_zellij_arch}"
            rm -f "$_zellij_tar"
            rm -f "$HOME/.local/bin/zellij"
            exit 1
        fi
        rm -f "$_zellij_tar"
    fi
fi

# ── Ubuntu tool-name symlinks (Linux only) ────────────────────────────

if [ "$IS_MACOS" -eq 0 ]; then
mkdir -p "$HOME/.local/bin"
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    echo "  ✓ Symlinked fd → fdfind"
fi
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    echo "  ✓ Symlinked bat → batcat"
fi
fi

# ── Zellij defaults ─────────────────────────────────────────────────

step "Configuring Zellij..."
ZELLIJ_CONFIG_DIR="$HOME/.config/zellij"
ZELLIJ_LAYOUTS_DIR="$ZELLIJ_CONFIG_DIR/layouts"
ZELLIJ_PLUGIN_DIR="$ZELLIJ_CONFIG_DIR/plugins"
backup_dir_if_exists "$ZELLIJ_CONFIG_DIR" "$BACKUP_DIR/zellij_config_dir"
mkdir -p "$ZELLIJ_LAYOUTS_DIR" "$ZELLIJ_PLUGIN_DIR" "$HOME/.local/bin"

backup_file_if_exists "$ZELLIJ_CONFIG_DIR/config.kdl" "$BACKUP_DIR/zellij_config.kdl"
backup_file_if_exists "$ZELLIJ_LAYOUTS_DIR/default.kdl" "$BACKUP_DIR/zellij_default_layout.kdl"
backup_file_if_exists "$ZELLIJ_PLUGIN_DIR/zjstatus.wasm" "$BACKUP_DIR/zjstatus.wasm"
backup_file_if_exists "$ZELLIJ_PLUGIN_DIR/zellij-attention.wasm" "$BACKUP_DIR/zellij-attention.wasm"

if [ -f "$ZELLIJ_METRICS_TEMPLATE" ]; then
    cp "$ZELLIJ_METRICS_TEMPLATE" "$HOME/.local/bin/zellij-metrics"
    chmod +x "$HOME/.local/bin/zellij-metrics"
    echo "  ✓ Installed ~/.local/bin/zellij-metrics"
else
    echo "  ✗ Missing metrics helper: $ZELLIJ_METRICS_TEMPLATE"
    exit 1
fi

step "Installing Zellij status plugin (zjstatus)..."
if confirm_install "Install zjstatus ${ZJSTATUS_VERSION}?"; then
    _zjstatus_url="https://github.com/dj95/zjstatus/releases/download/${ZJSTATUS_VERSION}/zjstatus.wasm"
    if download_to_file "$_zjstatus_url" "$ZELLIJ_PLUGIN_DIR/zjstatus.wasm"; then
        echo "  ✓ Installed zjstatus ${ZJSTATUS_VERSION}"
    else
        echo "  ✗ Failed to download zjstatus ${ZJSTATUS_VERSION}"
        rm -f "$ZELLIJ_PLUGIN_DIR/zjstatus.wasm"
        exit 1
    fi
fi

ZELLIJ_CACHE_DIR="$HOME/.cache/zellij"
PERM_FILE="$ZELLIJ_CACHE_DIR/permissions.kdl"
PLUGIN_ABSOLUTE_PATH="$ZELLIJ_PLUGIN_DIR/zjstatus.wasm"
ZJSTATUS_PLUGIN_URL="file:$PLUGIN_ABSOLUTE_PATH"
ZJSTATUS_PERM_KEY="file:$PLUGIN_ABSOLUTE_PATH"
_ATTENTION_PERM_KEY="file:$ZELLIJ_PLUGIN_DIR/zellij-attention.wasm"

step "Installing Zellij attention plugin (zellij-attention)..."
if confirm_install "Install zellij-attention ${ZELLIJ_ATTENTION_VERSION}?"; then
    _attention_url="https://github.com/KiryuuLight/zellij-attention/releases/download/${ZELLIJ_ATTENTION_VERSION}/zellij-attention.wasm"
    if download_to_file "$_attention_url" "$ZELLIJ_PLUGIN_DIR/zellij-attention.wasm"; then
        echo "  ✓ Installed zellij-attention ${ZELLIJ_ATTENTION_VERSION}"
    else
        echo "  ✗ Failed to download zellij-attention ${ZELLIJ_ATTENTION_VERSION}"
        rm -f "$ZELLIJ_PLUGIN_DIR/zellij-attention.wasm"
        exit 1
    fi
fi

# Pre-seed ~/.cache/zellij/permissions.kdl so zjstatus works without an interactive prompt (RunCommands).
# Zellij may change this cache format or path in future versions.
# Set ZSHKIT_SKIP_ZELLIJ_PERMISSION_SEED=1 to skip (you approve plugins in Zellij instead).
case "${ZSHKIT_SKIP_ZELLIJ_PERMISSION_SEED:-0}" in
    1|yes|true|on)
        echo "  ✓ Zellij plugin permissions: not pre-seeded (ZSHKIT_SKIP_ZELLIJ_PERMISSION_SEED — approve in Zellij if prompted)"
        ;;
    *)
        mkdir -p "$ZELLIJ_CACHE_DIR"
        if [ ! -f "$PERM_FILE" ] || ! grep -qF "$ZJSTATUS_PERM_KEY" "$PERM_FILE"; then
            echo "  ! Seeding Zellij permissions cache for zjstatus"
            printf '\n"%s" {\n    ReadApplicationState\n    ChangeApplicationState\n    RunCommands\n}\n' \
                "$ZJSTATUS_PERM_KEY" >> "$PERM_FILE"
        else
            echo "  ✓ Zellij permissions for zjstatus already seeded"
        fi
        if [ ! -f "$PERM_FILE" ] || ! grep -qF "$_ATTENTION_PERM_KEY" "$PERM_FILE"; then
            echo "  ! Seeding Zellij permissions cache for zellij-attention"
            printf '\n"%s" {\n    ReadApplicationState\n    ChangeApplicationState\n}\n' \
                "$_ATTENTION_PERM_KEY" >> "$PERM_FILE"
        else
            echo "  ✓ Zellij permissions for zellij-attention already seeded"
        fi
        ;;
esac

render_template_to_file \
    "$ZELLIJ_CONFIG_TEMPLATE" \
    "$ZELLIJ_CONFIG_DIR/config.kdl" \
    "__SCROLLBACK_EDITOR_LINE__" 'scrollback_editor "micro"'
echo "  ✓ Wrote $ZELLIJ_CONFIG_DIR/config.kdl"

template_must_exist "$ZELLIJ_LAYOUT_TEMPLATE"
render_template_to_file \
    "$ZELLIJ_LAYOUT_TEMPLATE" \
    "$ZELLIJ_LAYOUTS_DIR/default.kdl" \
    "__ZJSTATUS_PLUGIN_URL__" "$ZJSTATUS_PLUGIN_URL"
echo "  ✓ Wrote $ZELLIJ_LAYOUTS_DIR/default.kdl"

echo "    Zellij permissions for bundled plugins are pre-seeded by setup (see script header to skip)."
echo "    If a prompt still appears after a plugin update or cache reset, focus the status bar and press 'y'."

# ── SSH keepalive defaults ───────────────────────────────────────────

step "Configuring SSH defaults (keepalive + color forwarding)..."
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh" 2>/dev/null || true

SSH_BLOCK=$(cat << 'EOF'
# >>> zshkit ssh defaults >>>
Host *
    ServerAliveInterval 30
    ServerAliveCountMax 3
    TCPKeepAlive yes
    # Forward COLORTERM so remote apps can use truecolor when supported.
    SendEnv COLORTERM
# <<< zshkit ssh defaults <<<
EOF
)

if [ -f "$SSH_CONFIG" ]; then
    mkdir -p "$BACKUP_DIR"
    cp "$SSH_CONFIG" "$BACKUP_DIR/ssh_config"
    echo "  ✓ Backup → $BACKUP_DIR/ssh_config"
    if grep -qF "$SSH_MARKER_BEGIN" "$SSH_CONFIG" && grep -qF "$SSH_MARKER_END" "$SSH_CONFIG"; then
        _ssh_block_tmp=$(mktemp)
        printf '%s\n' "$SSH_BLOCK" > "$_ssh_block_tmp"
        awk -v start="$SSH_MARKER_BEGIN" -v end="$SSH_MARKER_END" -v bfile="$_ssh_block_tmp" '
            $0 == start { while ((getline line < bfile) > 0) print line; close(bfile); in_block=1; next }
            $0 == end   { in_block=0; next }
            !in_block   { print }
        ' "$SSH_CONFIG" > "$SSH_CONFIG.tmp"
        rm -f "$_ssh_block_tmp"
        mv "$SSH_CONFIG.tmp" "$SSH_CONFIG"
        echo "  ✓ Updated managed SSH defaults block"
    else
        printf "\n%s\n" "$SSH_BLOCK" >> "$SSH_CONFIG"
        echo "  ✓ Appended SSH defaults block to $SSH_CONFIG"
    fi
else
    (umask 077 && printf "%s\n" "$SSH_BLOCK" > "$SSH_CONFIG")
    echo "  ✓ Created $SSH_CONFIG"
fi
chmod 600 "$SSH_CONFIG" 2>/dev/null || true

# ── Ghostty install ───────────────────────────────────────────────────

# Ghostty is a local GUI app — skip over SSH.
if [ -z "${SSH_CONNECTION:-}" ]; then
    install_ghostty
else
    step "Installing Ghostty..."
    echo "  - Skipping Ghostty install in SSH session (GUI app for local machine)"
fi

# ── Ghostty defaults ──────────────────────────────────────────────────

if [ -z "${SSH_CONNECTION:-}" ]; then
    step "Installing Ghostty config..."
    if ! install_home_ghostty_conf; then
        exit 1
    fi
else
    step "Installing Ghostty config..."
    echo "  - Skipping Ghostty config in SSH session"
fi

# ── MesloLGS NF (Powerlevel10k recommended font) ─────────────────────

step "Installing MesloLGS NF..."
_MESLO_BASE="https://github.com/romkatv/powerlevel10k-media/raw/master"
_MESLO_FILES=("MesloLGS NF Regular.ttf" "MesloLGS NF Bold.ttf" "MesloLGS NF Italic.ttf" "MesloLGS NF Bold Italic.ttf")

if has_meslo_nerd_font; then
    echo "  ✓ MesloLGS NF already installed"
elif confirm_install "Install MesloLGS NF font (recommended by Powerlevel10k)?"; then
    if [ "$IS_MACOS" -eq 1 ]; then
        FONT_DIR="$HOME/Library/Fonts"
    else
        FONT_DIR="$HOME/.local/share/fonts"
    fi
    mkdir -p "$FONT_DIR"
    _font_ok=1
    for _f in "${_MESLO_FILES[@]}"; do
        _encoded="${_f// /%20}"
        if ! curl -fsSL -o "$FONT_DIR/$_f" "$_MESLO_BASE/$_encoded" 2>/dev/null; then
            echo "  ⚠ Failed to download '$_f'"
            _font_ok=0
        fi
    done
    if [ "$_font_ok" -eq 1 ]; then
        [ "$IS_MACOS" -eq 0 ] && fc-cache -f >/dev/null 2>&1
        echo "  ✓ MesloLGS NF installed"
    else
        echo "  ⚠ Font install incomplete — download manually from https://github.com/romkatv/powerlevel10k#fonts"
    fi
fi

# ── Modern terminal terminfo (Ghostty, Kitty, etc.) ─────────────────
# Install terminfo for popular modern terminals so SSH sessions from
# these terminals get full color support without any manual steps.
# Installed to ~/.terminfo/ (user-local, no root needed).

step "Installing modern terminal terminfo entries..."

install_terminfo_from_url() {
    local name="$1" url="$2"
    if infocmp "$name" &>/dev/null 2>&1; then
        echo "  ✓ $name terminfo already available"
        return 0
    fi
    local tmpfile
    tmpfile=$(mktemp)
    if curl -fsSL --connect-timeout 10 -o "$tmpfile" "$url" 2>/dev/null && [ -s "$tmpfile" ]; then
        if tic -x -o "$HOME/.terminfo" "$tmpfile" 2>/dev/null; then
            echo "  ✓ Installed $name terminfo"
            rm -f "$tmpfile"
            return 0
        fi
    fi
    rm -f "$tmpfile"
    return 1
}

mkdir -p "$HOME/.terminfo"

if command -v tic &>/dev/null; then
    # Ghostty (xterm-ghostty)
    if ! infocmp xterm-ghostty &>/dev/null 2>&1; then
        if ! install_terminfo_from_url "xterm-ghostty" \
            "https://raw.githubusercontent.com/ghostty-org/ghostty/main/src/terminfo/ghostty.terminfo"; then
            echo "  - Could not install xterm-ghostty terminfo; zsh will fall back to xterm-256color when needed"
        fi
    else
        echo "  ✓ xterm-ghostty terminfo already available"
    fi

    # Kitty (xterm-kitty)
    if ! infocmp xterm-kitty &>/dev/null 2>&1; then
        if ! install_terminfo_from_url "xterm-kitty" \
            "https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/kitty.terminfo"; then
            echo "  - Could not install xterm-kitty terminfo; zsh will fall back to xterm-256color when needed"
        fi
    else
        echo "  ✓ xterm-kitty terminfo already available"
    fi

    # WezTerm
    if ! infocmp wezterm &>/dev/null 2>&1; then
        if ! install_terminfo_from_url "wezterm" \
            "https://raw.githubusercontent.com/wezterm/wezterm/main/termwiz/data/wezterm.terminfo"; then
            echo "  - Could not install wezterm terminfo; zsh will fall back to xterm-256color when needed"
        fi
    else
        echo "  ✓ wezterm terminfo already available"
    fi
else
    echo "  - tic not found; skipping terminfo installation"
fi

# Install terminfo system-wide so sudo/root sessions also find them.
# Without this, `sudo nano` etc. fail with "Error opening terminal: xterm-ghostty".
for _ti_name in xterm-ghostty xterm-kitty wezterm; do
    if infocmp "$_ti_name" &>/dev/null 2>&1; then
        if ! sudo infocmp "$_ti_name" &>/dev/null 2>&1; then
            echo "  Installing $_ti_name terminfo system-wide (for sudo)..."
            infocmp -x "$_ti_name" | sudo tic -x - 2>/dev/null \
                && echo "  ✓ $_ti_name available for root" \
                || echo "  - Could not install $_ti_name system-wide (no sudo?)"
        fi
    fi
done
unset _ti_name

# ── VPN helper bundle ────────────────────────────────────────────────

step "Installing VPN helper bundle..."
install_vpn_bundle

# ── Migrate exports → ~/.zshrc.local ────────────────────────────────

step "Setting up ~/.zshrc.local..."

if [ -f "$HOME/.zshrc.local" ]; then
    echo "  ✓ ~/.zshrc.local already exists (not touched)"
elif [ -f "$HOME/.zshrc" ]; then
    # Broad pattern: any export whose name contains TOKEN, KEY, SECRET, or starts with AWS_/HF_/GITHUB_/WANDB_
    grep -E '^export +([A-Za-z_][A-Za-z0-9_]*(TOKEN|KEY|SECRET)[A-Za-z0-9_]*|AWS_[A-Za-z0-9_]*|HF_[A-Za-z0-9_]*|GITHUB_[A-Za-z0-9_]*|WANDB_[A-Za-z0-9_]*)=' \
        "$HOME/.zshrc" > "$HOME/.zshrc.local" 2>/dev/null || true

    if [ -s "$HOME/.zshrc.local" ]; then
        echo "  ✓ Migrated exports to ~/.zshrc.local (values redacted):"
        awk -F= '{print "    " $1 "=<redacted>"}' "$HOME/.zshrc.local"
    else
        create_zshrc_local_template
    fi
else
    create_zshrc_local_template
fi

# ── Install ~/.zshrc ─────────────────────────────────────────────────

step "Installing ~/.zshrc from template..."
BACKUP_PATH=""
if [ -f "$HOME/.zshrc" ]; then
    if mkdir -p "$BACKUP_DIR"; then
        BACKUP_PATH="$BACKUP_DIR/.zshrc"
    else
        echo "  ✗ Failed to create backup directory: $BACKUP_DIR"
        exit 1
    fi
    if cp "$HOME/.zshrc" "$BACKUP_PATH"; then
        echo "  ✓ Backup → $BACKUP_PATH"
    else
        echo "  ✗ Failed to back up ~/.zshrc"
        exit 1
    fi
fi
if cp "$ZSHRC_TEMPLATE" "$HOME/.zshrc"; then
    echo "  ✓ Installed ~/.zshrc"
else
    echo "  ✗ Failed to install ~/.zshrc from template"
    exit 1
fi

# ── Install ~/.p10k.zsh (Powerlevel10k user config) ───────────────────

step "Installing ~/.p10k.zsh from zshkit template..."
if ! install_home_p10k_zsh; then
    exit 1
fi

# ── Git aliases (for muscle memory / faster branch switching) ─────────

step "Ensuring git switch aliases..."
if command -v git &>/dev/null; then
    git config --global alias.sw switch
    git config --global alias.swc 'switch --create'
    echo "  ✓ Set git aliases: sw, swc"
else
    echo "  ⚠ git not found; skipped git alias setup"
fi

step "Configuring delta as git pager..."
if command -v delta &>/dev/null; then
    git config --global core.pager delta
    git config --global interactive.diffFilter 'delta --color-only'
    git config --global delta.navigate true
    git config --global delta.side-by-side true
    echo "  ✓ delta configured as git pager"
else
    echo "  - delta not found; skipping (install git-delta and re-run)"
fi

# ── ~/.zshenv (skip_global_compinit) ─────────────────────────────────

step "Ensuring ~/.zshenv compatibility..."
ZSHENV_LINE="skip_global_compinit=1"
if [ -f "$HOME/.zshenv" ]; then
    if grep -q "^${ZSHENV_LINE}$" "$HOME/.zshenv"; then
        echo "  ✓ ~/.zshenv already has $ZSHENV_LINE"
    else
        { echo "# zsh completion: avoid global compinit conflicts."; echo "$ZSHENV_LINE"; echo ""; cat "$HOME/.zshenv"; } > "$HOME/.zshenv.tmp"
        mv "$HOME/.zshenv.tmp" "$HOME/.zshenv"
        echo "  ✓ Added $ZSHENV_LINE to ~/.zshenv"
    fi
else
    printf "# zsh completion: avoid global compinit conflicts.\n%s\n" "$ZSHENV_LINE" > "$HOME/.zshenv"
    echo "  ✓ Created ~/.zshenv"
fi

# ── Default shell → zsh ─────────────────────────────────────────────

step "Setting default shell to zsh..."
if command -v chsh &>/dev/null; then
    if [ "$IS_MACOS" -eq 1 ]; then
        CURRENT_SHELL=$(dscl . -read "/Users/${USER:-$(whoami)}" UserShell 2>/dev/null | awk '{print $2}')
    else
        CURRENT_SHELL=$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)
    fi
    ZSH_PATH=$(command -v zsh)
    if [ -z "$CURRENT_SHELL" ] || [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
        if [ -n "${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-}" ] || [ ! -t 0 ]; then
            echo "  - Skipping chsh in SSH/non-interactive session; run manually later: chsh -s $ZSH_PATH"
        elif chsh -s "$ZSH_PATH" 2>/dev/null; then
            echo "  ✓ Default shell → $ZSH_PATH"
        else
            echo "  ⚠ chsh failed — run manually: chsh -s $ZSH_PATH"
        fi
    else
        echo "  ✓ Default shell is already zsh"
    fi
else
    echo "  ⚠ chsh not available"
fi

# ── .bashrc fallback auto-launch ────────────────────────────────────

step "Adding .bashrc zsh auto-launch fallback..."
BASHRC="$HOME/.bashrc"
if [ -f "$BASHRC" ] && ! grep -q "Auto-launch zsh" "$BASHRC"; then
    cat >> "$BASHRC" << 'EOF'

# Auto-launch zsh if available (added by zshkit setup)
if [ -t 1 ] && [ -z "$ZSH_VERSION" ] && command -v zsh >/dev/null 2>&1; then
    export SHELL=$(command -v zsh)
    exec zsh
fi
EOF
    echo "  ✓ Added zsh auto-launch to .bashrc"
else
    echo "  ✓ .bashrc already configured"
fi

# ── Write backup manifest ────────────────────────────────────────────

if [ -d "$BACKUP_DIR" ]; then
    {
        echo "zshkit backup — $(date)"
        echo "Run: bash $SCRIPT_DIR/rollback.sh"
        echo ""
        find "$BACKUP_DIR" -not -name "manifest.txt" | sort | sed "s|$BACKUP_DIR/||"
    } > "$BACKUP_DIR/manifest.txt"
    echo ""
    echo "Backup saved: $BACKUP_DIR"
    echo "To restore:   bash $SCRIPT_DIR/rollback.sh"
fi

# ── Done ─────────────────────────────────────────────────────────────

echo ""
echo "======================================================================"
echo "✓ Setup complete!"
echo "======================================================================"
echo ""
echo "Powerlevel10k — interactive prompt setup:"
echo "  After you open zsh (new terminal or: exec zsh), run:"
echo ""
echo "    p10k configure"
echo ""
echo "  That starts the guided wizard (prompt style, colors, icons, segments)."
echo "  Choices are saved to ~/.p10k.zsh. zshkit installed its default from"
echo "  templates/p10k.zsh.template; use the wizard whenever you want to change the look."
echo ""
echo "Next steps:"
echo ""
echo "  1. Add personal exports/tokens to ~/.zshrc.local"
if [ -n "$BACKUP_PATH" ] || [ -n "$P10K_BACKUP_PATH" ] || [ -n "$GHOSTTY_BACKUP_PATH" ]; then
    echo "     Previous file(s) backed up under: $BACKUP_DIR"
    [ -n "$BACKUP_PATH" ] && echo "       - .zshrc → $BACKUP_PATH"
    [ -n "$P10K_BACKUP_PATH" ] && echo "       - .p10k.zsh → $P10K_BACKUP_PATH"
    [ -n "$GHOSTTY_BACKUP_PATH" ] && echo "       - ghostty/config → $GHOSTTY_BACKUP_PATH"
fi
echo "     Optional VPN helper:"
echo "       - Edit $(vpn_managed_dir)/vpn-credentials.txt"
echo "       - Set ZSHKIT_VPN_CONFIG_FILE in ~/.zshrc.local if your .ovpn file is not ~/client.ovpn"
echo ""
echo "  2. Start a new terminal (or run: exec zsh)"
echo ""
echo "  3. Set your terminal font to 'MesloLGS NF' (recommended by Powerlevel10k — see https://github.com/romkatv/powerlevel10k/tree/master?tab=readme-ov-file#fonts)"
echo ""
echo "  4. Open ~/.config/ghostty/config to customize Ghostty."
echo "     Reload changes with Ctrl+Shift+, (Cmd+Shift+, on macOS) without restarting."
echo ""
echo "  5. Run: p10k configure   (same as the banner above — guided Powerlevel10k wizard;"
echo "     saves to ~/.p10k.zsh. Re-run setup_zsh.sh to restore the repo template default.)"
echo ""
echo "  6. Zellij: plugin permissions are pre-seeded by setup; if prompted, focus the status bar and press 'y' (or use ZSHKIT_SKIP_ZELLIJ_PERMISSION_SEED=1 next run to approve manually)."
echo ""
if [ "$IS_MACOS" -eq 1 ]; then
    echo "  7. Use Ghostty (installed above) as your main terminal."
    echo "     Ghostty supports OSC 52, so Zellij clipboard copy works over SSH."
else
    echo "  7. Use Ghostty (installed above) as your main terminal."
    echo "     Ghostty supports OSC 52, so Zellij clipboard copy works over SSH."
    echo "     With GNOME Terminal or other terminals that lack OSC 52, use Shift+drag then Ctrl+Shift+C instead."
fi
echo ""
echo "Setup details: $SCRIPT_DIR/SETUP_DETAILS.md"
echo "Usage guide:  $SCRIPT_DIR/USAGE_GUIDE.md"
echo "======================================================================"
