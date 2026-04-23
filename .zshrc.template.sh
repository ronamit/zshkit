# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Fastfetch: show system info on interactive local sessions only.
# Placed after instant prompt so P10k can render the prompt frame immediately
# while fastfetch output scrolls above it.
if [[ -z "${SSH_CONNECTION:-}" && -o interactive ]] && command -v fastfetch &>/dev/null; then
    fastfetch
fi

# ── Oh My Zsh core ───────────────────────────────────────────────────

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Some IDE terminals start with TERM=dumb, which disables prompt/command colors.
if [[ -o interactive && -t 1 && "$TERM" == "dumb" ]]; then
    export TERM=xterm-256color
fi

# If TERM is not recognized (no terminfo entry), fall back to xterm-256color.
# This commonly happens when SSHing from terminals like Ghostty (xterm-ghostty),
# Kitty, or WezTerm to servers that don't have their terminfo installed.
if [[ -o interactive && -t 1 && "$TERM" != "dumb" ]]; then
    if ! infocmp "$TERM" &>/dev/null 2>&1; then
        export TERM=xterm-256color
    fi
fi

# Ensure COLORTERM is set for truecolor support (especially over SSH where
# SendEnv may not be accepted by the server's sshd_config).
if [[ -o interactive && -t 1 && -z "${COLORTERM:-}" ]]; then
    if [[ "$TERM" == *256color* || "$TERM" == *ghostty* || "$TERM" == *kitty* ]]; then
        export COLORTERM=truecolor
    elif infocmp "$TERM" 2>/dev/null | grep -q 'colors#0*16777216\|setrgbf\|RGB' 2>/dev/null; then
        export COLORTERM=truecolor
    fi
fi

# Reset terminal input modes that commonly leak after abrupt app/SSH exits.
# Pass --leave-alt-screen only after full-screen apps disconnect unexpectedly.
_zshkit_reset_terminal_input_modes() {
    [[ -o interactive && -t 1 ]] || return 0
    local leave_alt_screen=0
    [[ "${1:-}" == "--leave-alt-screen" ]] && leave_alt_screen=1
    # \e[?1049l — exit alternate screen (Zellij/vim/less can leave terminal in alt buffer on crash)
    # \e[?1l  — DECCKM: restore normal cursor keys (prevents raw 29A / OA leakage)
    # \e[?1000l–?1015l — disable all mouse reporting modes
    # \e[?2004l — disable bracketed paste
    (( leave_alt_screen )) && printf '\e[?1049l'
    printf '\e[?1l\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1015l\e[?2004l'
    # Pop Kitty keyboard protocol stack — covers Kitty and Ghostty (which uses
    # TERM_PROGRAM=ghostty rather than KITTY_WINDOW_ID / TERM=xterm-kitty).
    if [[ -n "${KITTY_WINDOW_ID:-}" || "$TERM" == "xterm-kitty" || "$TERM_PROGRAM" == "ghostty" ]]; then
        printf '\e[<u'
    fi
}

# Disable mouse reporting so scroll in SSH (and plain shells) doesn't dump raw escape codes.
# Apps like vim/less will re-enable it when they start.
_zshkit_reset_terminal_input_modes

HYPHEN_INSENSITIVE="true"
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13
HIST_STAMPS="yyyy-mm-dd"

# ── Plugin detection & compatibility ─────────────────────────────────

_zsh_autosuggest_plugin="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
_zsh_highlight_plugin="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
_zsh_defer_plugin="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-defer/zsh-defer.plugin.zsh"
typeset -gi _zsh_autosuggest_loaded=0
[[ -r "$_zsh_autosuggest_plugin" ]] && _zsh_autosuggest_loaded=1
typeset -gi _zsh_highlight_loaded=0
[[ -r "$_zsh_highlight_plugin" ]] && _zsh_highlight_loaded=1
typeset -gi _lsd_installed=0
command -v lsd &>/dev/null && _lsd_installed=1
typeset -gi _command_not_found_enabled=1

# command-not-found can add latency on slower/remote sessions.
# Defaults: disabled over SSH, enabled locally. Override with:
#   ZSH_ENABLE_COMMAND_NOT_FOUND=1  (force on)
#   ZSH_ENABLE_COMMAND_NOT_FOUND=0  (force off)
if [[ -n "${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-}" ]]; then
    _command_not_found_enabled=0
fi
if [[ -n "${ZSH_ENABLE_COMMAND_NOT_FOUND:-}" ]]; then
    case "${ZSH_ENABLE_COMMAND_NOT_FOUND:l}" in
        1|on|true|yes) _command_not_found_enabled=1 ;;
        0|off|false|no) _command_not_found_enabled=0 ;;
    esac
fi

plugins=(
    git
    colored-man-pages
    extract
    fzf
)
# Load z plugin only when zoxide is not installed (zoxide provides the z command)
command -v zoxide &>/dev/null || plugins+=(z)
(( _command_not_found_enabled )) && plugins+=(command-not-found)

# Load complist (provides menu-select widget for navigable completion menus).
zmodload -i zsh/complist

# Skip OMZ's git-based update check (use `omz update` manually instead).
# Disable magic-functions (URL-paste escaping) which hooks into self-insert and adds latency.
DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"

# Wrap compinit so it runs exactly once with caching, then becomes a no-op.
# OMZ calls compinit early via compfix.zsh (which also defines compdef for plugins).
# The wrapper intercepts that first call, runs the cached version, then blocks the
# redundant end-of-script compinit call OMZ makes after all plugins are loaded.
function compinit() {
    unfunction compinit
    autoload -Uz compinit
    setopt localoptions extended_glob
    if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
        compinit "$@"
    else
        compinit -C "$@"
    fi
    function compinit() {}
}
[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# syntax-highlighting and autosuggestions are sourced at the very end of this file
# so that autosuggestions wraps the final widget set.

# ══════════════════════════════════════════════════════════════════════
# Everything below runs AFTER oh-my-zsh so our settings are not
# overridden. This is critical for completion styling to work.
# ══════════════════════════════════════════════════════════════════════

# ── Completion styling ───────────────────────────────────────────────

# Re-apply menu select after oh-my-zsh (it can get overridden).
zstyle ':completion:*' menu select

# Ensure the cache directory exists before any cache writes below.
[[ -d "$HOME/.zsh/cache" ]] || mkdir -p "$HOME/.zsh/cache"

# Ensure LS_COLORS is set (Ubuntu doesn't always export it in zsh).
if [[ -z "$LS_COLORS" ]]; then
    if command -v dircolors &>/dev/null; then
        _dircolors_cache="$HOME/.zsh/cache/dircolors.zsh"
        if [[ ! -f "$_dircolors_cache" || "$(command -v dircolors)" -nt "$_dircolors_cache" ]]; then
            dircolors -b >| "$_dircolors_cache"
        fi
        source "$_dircolors_cache"
        unset _dircolors_cache
    else
        export LS_COLORS='di=1;34:ln=36:so=35:pi=33:ex=32:bd=1;33:cd=1;33:su=37;41:sg=30;43:tw=30;42:ow=34;42'
    fi
fi

# Color completions by file type (dirs=blue, exes=green, symlinks=cyan)
# and highlight the currently selected item.
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:*:*:*:default' list-colors "${(s.:.)LS_COLORS}"

# Group completions by type with subtle headers (directory, file, alias, etc.)
zstyle ':completion:*' group-name ''
# Keep native completion headers styled.
zstyle ':completion:*:descriptions' format '%F{8}── %d ──%f'
zstyle ':completion:*:warnings'     format '%F{red}no matches%f'

# Case-insensitive + partial matching ("doc" → "Documents", "dl" → "Downloads").
# Try exact case first, then fall back to case-insensitive, then partial.
zstyle ':completion:*' matcher-list \
    '' \
    'm:{a-zA-Z}={A-Za-z}' \
    'r:|[._-]=* r:|=*' \
    'l:|=* r:|=*'

# Show descriptions for options (e.g. git --verbose "be more verbose").
zstyle ':completion:*' verbose yes
# apt package enumeration is extremely slow with verbose on — disable descriptions
# to avoid the "Killed by signal in _describe after Xs" timeout.
zstyle ':completion:*:apt*:argument-rest:*' verbose no
zstyle ':completion:*:apt-get*:argument-rest:*' verbose no

# Directories first for cd; don't offer . or ..
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*' ignore-parents parent pwd

# Completion cache (makes repeated completions instant)
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zsh/cache"

# kill: color PIDs and show process info
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# SSH/SCP: cache hostnames from known_hosts + ssh config to keep startup fast.
_ssh_cache_file="$HOME/.zsh/cache/ssh_hosts"
_refresh_ssh_hosts_cache=0
[[ ! -f "$_ssh_cache_file" ]] && _refresh_ssh_hosts_cache=1
[[ -r ~/.ssh/known_hosts && ~/.ssh/known_hosts -nt "$_ssh_cache_file" ]] && _refresh_ssh_hosts_cache=1
[[ -r ~/.ssh/config && ~/.ssh/config -nt "$_ssh_cache_file" ]] && _refresh_ssh_hosts_cache=1
if (( _refresh_ssh_hosts_cache )); then
    {
        if [[ -r ~/.ssh/known_hosts ]]; then
            awk '{print $1}' ~/.ssh/known_hosts \
                | tr ',' '\n' \
                | sed 's/\[//;s/\]:.*//' \
                | grep -vE '^(\||#|$)'
        fi
        if [[ -r ~/.ssh/config ]]; then
            grep -i '^Host ' ~/.ssh/config | awk '{for(i=2;i<=NF;i++) if($i !~ /[*?]/) print $i}'
        fi
    } | grep -vE '^\s*$' | sort -u >| "${_ssh_cache_file}.tmp" \
        && command mv -- "${_ssh_cache_file}.tmp" "$_ssh_cache_file"
fi
_ssh_hosts=()
[[ -r "$_ssh_cache_file" ]] && _ssh_hosts=(${(f)"$(cat "$_ssh_cache_file")"})
if (( ${#_ssh_hosts} )); then
    zstyle ':completion:*:(ssh|scp|rsync):*' hosts $_ssh_hosts
fi
unset _ssh_hosts _ssh_cache_file _refresh_ssh_hosts_cache

# ── Environment ──────────────────────────────────────────────────────

# Editor: prefer micro if installed, fallback to nano or vim
if command -v micro &>/dev/null; then
    export EDITOR='micro'
    alias edit='micro'
elif command -v nano &>/dev/null; then
    export EDITOR='nano'
else
    export EDITOR='vim'
fi

# Keep PATH unique while prepending user bins and snap (yazi and other snaps live in /snap/bin).
typeset -U path PATH
[[ -d "$HOME/.local/bin" ]]  && path=("$HOME/.local/bin" $path)
[[ -d "$HOME/bin" ]]         && path=("$HOME/bin" $path)
[[ -d /snap/bin ]]           && path=("/snap/bin" $path)
[[ -d "$HOME/.cargo/bin" ]]  && path=("$HOME/.cargo/bin" $path)
export PATH

# zoxide: smarter cd with frequency+recency ranking (overrides z plugin's z command when installed)
if command -v zoxide &>/dev/null; then
    _zoxide_cache="$HOME/.zsh/cache/zoxide_init.zsh"
    if [[ ! -f "$_zoxide_cache" || "$(command -v zoxide)" -nt "$_zoxide_cache" ]]; then
        zoxide init zsh >| "$_zoxide_cache"
    fi
    source "$_zoxide_cache"
    unset _zoxide_cache
fi

# direnv: load/unload .envrc files when entering/leaving directories
if command -v direnv &>/dev/null; then
    _direnv_cache="$HOME/.zsh/cache/direnv_hook.zsh"
    if [[ ! -f "$_direnv_cache" || "$(command -v direnv)" -nt "$_direnv_cache" ]]; then
        direnv hook zsh >| "$_direnv_cache"
    fi
    source "$_direnv_cache"
    unset _direnv_cache
fi

# navi: interactive cheatsheet widget — Ctrl+G opens the fzf picker
if command -v navi &>/dev/null; then
    _navi_cache="$HOME/.zsh/cache/navi_widget.zsh"
    if [[ ! -f "$_navi_cache" || "$(command -v navi)" -nt "$_navi_cache" ]]; then
        navi widget zsh >| "$_navi_cache"
    fi
    source "$_navi_cache"
    unset _navi_cache
fi

# run-help: Alt+H or "help <cmd>" shows man for builtins/commands (e.g. help git).
autoload -Uz run-help
unalias run-help 2>/dev/null
alias help=run-help
autoload -Uz run-help-git run-help-ip run-help-openssl run-help-sudo run-help-svn

# Colored man pages (bold/underline in less); plugin adds semantics, this improves rendering.
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;38;5;74m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[38;5;246m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[04;38;5;146m'

# ── Utility: open URL/path with system opener ────────────────────────

_open_default() {
    local target="$1"
    if command -v xdg-open &>/dev/null; then
        xdg-open "$target" >/dev/null 2>&1 &
    elif command -v open &>/dev/null; then
        open "$target" >/dev/null 2>&1 &
    elif command -v wslview &>/dev/null; then
        wslview "$target" >/dev/null 2>&1 &
    else
        echo "No URL opener found (xdg-open/open/wslview)."
        return 1
    fi
}

# ── Aliases: Navigation & Files ──────────────────────────────────────

alias cls='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'   # Go to previous directory (complements AUTO_PUSHD)

if (( _lsd_installed )); then
    alias ls='lsd'
    alias l='lsd -l'
    alias la='lsd -la'
    alias ll='lsd -lah'
else
    alias l='ls -lFh'
    alias la='ls -lAFh'
    if [[ "$OSTYPE" == darwin* ]]; then
        alias ll='ls -lAh -FG'
    elif ls --group-directories-first -d . &>/dev/null 2>&1; then
        alias ll='ls -lAh --group-directories-first --color=auto'
    else
        alias ll='ls -lAh'
    fi
fi
alias lt='tree -L 2'
alias ldot='command ls -ld .*'

# Use bat for cat (plain output, no paging). setup_zsh.sh symlinks batcat→bat in ~/.local/bin when needed.
if command -v bat &>/dev/null; then
    alias cat='bat --style=plain --paging=never'
    alias catt='bat'
fi

alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -I'         # Prompt only for >3 files or recursive deletes
alias mkdir='mkdir -pv'

if command -v rg &>/dev/null; then
    if [[ "$TERM_PROGRAM" == "ghostty" ]]; then
        alias rg='rg --hyperlink-format=osc8'
    elif [[ -n "${KITTY_WINDOW_ID:-}" || "$TERM" == "xterm-kitty" ]]; then
        alias rg='rg --hyperlink-format=kitty'
    fi
fi
alias grep='grep --color=auto'

alias df='df -h'
alias du='du -h'
command -v free &>/dev/null && alias free='free -h'
alias myip='curl -s ifconfig.me'
# Local IP: Linux (hostname -I) or macOS (ipconfig getifaddr)
localip() {
    if command -v hostname &>/dev/null && hostname -I &>/dev/null; then
        hostname -I | awk '{print $1}'
    elif command -v ipconfig &>/dev/null; then
        ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "No primary IP"
    else
        echo "No localip helper"
    fi
}
alias h='history'
alias path='echo "$PATH" | tr ":" "\n"'

if command -v kitten &>/dev/null; then
    alias clipcopy='kitten clipboard'
    alias clippaste='kitten clipboard --get-clipboard'
    alias icat='kitten icat'
elif [[ "$TERM_PROGRAM" == "ghostty" || -n "${ZELLIJ:-}" ]]; then
    # OSC 52 clipboard — works in Ghostty locally and through Zellij over SSH.
    # Use 'function' keyword: protects name from alias expansion at parse time.
    function clipcopy  { printf '\e]52;c;'; base64 | tr -d '\n'; printf '\a'; }
    function clippaste { printf '\e]52;c;?\a'; }
fi
# Ghostty supports OSC 8 hyperlinks natively; hg wraps rg with clickable paths.
if command -v rg &>/dev/null && [[ "$TERM_PROGRAM" == "ghostty" ]]; then
    alias hg='rg --hyperlink-format=osc8'
elif command -v kitten &>/dev/null; then
    alias hg='kitten hyperlinked-grep'
fi

# Safety nets for recursive operations (GNU only; macOS BSD chown/chmod lack these)
if [[ "$(uname -s)" != "Darwin" ]]; then
    alias chown='chown --preserve-root'
    alias chmod='chmod --preserve-root'
    alias chgrp='chgrp --preserve-root'
fi

# Editor: cursor > code
if command -v cursor &>/dev/null; then
    alias c='cursor'
elif command -v code &>/dev/null; then
    alias c='code'
fi

# VPN helpers (installed by setup_zsh.sh)
_zshkit_vpn_default_dir() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        print -r -- "$HOME/Library/Application Support/zshkit/vpn"
    else
        print -r -- "${XDG_DATA_HOME:-$HOME/.local/share}/zshkit/vpn"
    fi
}

_zshkit_vpn_help() {
    local cmd_name="${1:-vpn}"
    local vpn_dir="${ZSHKIT_VPN_DIR:-$(_zshkit_vpn_default_dir)}"
    local creds_file="${ZSHKIT_VPN_CREDENTIALS_FILE:-$vpn_dir/vpn-credentials.txt}"
    local config_file="${ZSHKIT_VPN_CONFIG_FILE:-$HOME/client.ovpn}"
    echo "$cmd_name is not available yet."
    echo "Run setup_zsh.sh to install the managed VPN helpers."
    echo "Then add your VPN credentials to: $creds_file"
    echo "VPN config defaults to: $config_file"
}

_zshkit_vpn_run() {
    local cmd_name="${1:?usage: _zshkit_vpn_run CMD [ARGS...]}"
    shift
    local cmd_path
    cmd_path="$(whence -p "$cmd_name" 2>/dev/null)"
    if [[ -z "$cmd_path" ]]; then
        _zshkit_vpn_help "$cmd_name"
        return 1
    fi
    "$cmd_path" "$@"
}

vpn-connect() { _zshkit_vpn_run vpn-connect "$@"; }
vpn-disconnect() { _zshkit_vpn_run vpn-disconnect "$@"; }
vpn-status() { _zshkit_vpn_run vpn-status "$@"; }

# AWS SSO login shortcut
command -v aws &>/dev/null && alias aws-login='aws sso login'

# Refresh AWS SSO session (checks first; prompts only if expired)
aws-sso() {
    if ! command -v aws &>/dev/null; then
        echo "aws-sso: aws CLI not installed."
        return 1
    fi
    local profile="${EC2_AWS_PROFILE:-${AWS_PROFILE:-default}}"
    if aws sts get-caller-identity --profile "$profile" &>/dev/null; then
        echo "AWS session is valid (profile: $profile)."
        return 0
    fi
    echo "AWS session expired. Opening SSO login (profile: $profile)..."
    aws sso login --profile "$profile"
}

# Push local terminfo to a remote server so SSH preserves full color support.
# Usage: ssh-fix-colors user@host
ssh-fix-colors() {
    local host="${1:?usage: ssh-fix-colors user@host}"
    if ! command -v infocmp &>/dev/null; then
        echo "infocmp not found (install ncurses-bin)"
        return 1
    fi
    echo "Installing '$TERM' terminfo on $host..."
    local terminfo
    terminfo=$(infocmp -x "$TERM" 2>/dev/null) || {
        echo "Failed — could not read terminfo for '$TERM' locally"
        return 1
    }
    printf '%s\n' "$terminfo" | command ssh "$host" -- \
        'command -v tic >/dev/null 2>&1 || { echo "remote: tic not found (e.g. install ncurses-bin)" >&2; exit 1; }; exec tic -x -' \
        && echo "Done — '$TERM' is now available on $host" \
        || echo "Failed — ensure tic/ncurses exists on the remote"
}

# VPN-aware SSH helper.
# Features:
#   - Leaves normal `ssh` untouched.
#   - Adds ConnectTimeout=15 if unset (override with -o ConnectTimeout=…).
#   - Adds ServerAliveInterval=10 and ServerAliveCountMax=2 if unset (override with
#     -o ServerAliveInterval=… / ServerAliveCountMax=…) so dead TCP paths fail
#     within ~20s instead of hanging; pairs with the duration-gated retry on exit 255.
#   - Resets terminal mouse tracking and Kitty keyboard mode before and after every session.
#   - On failure in interactive shells, offers vpn-connect and retries once.
sshv() {
    if [[ $# -eq 0 ]]; then
        echo "usage: sshv [ssh-options] user@host [command]"
        return 1
    fi
    local -a original_args=("$@")
    # Reset local terminal input modes before connecting so stale SSH/app state
    # doesn't leak raw mouse or Kitty/Ghostty keyboard escape sequences into the shell.
    _zshkit_reset_terminal_input_modes --leave-alt-screen

    local has_timeout=0 has_alive=0 connect_timeout=15
    local arg
    for arg in "$@"; do
        if [[ "$arg" == ConnectTimeout=* ]]; then
            has_timeout=1; connect_timeout="${arg#ConnectTimeout=}"
        elif [[ "$arg" == *ConnectTimeout* ]]; then
            has_timeout=1
        fi
        [[ "$arg" == *ServerAliveInterval* ]] && has_alive=1
    done

    local -a ssh_args=("$@")
    (( has_timeout )) || ssh_args=(-o ConnectTimeout=${connect_timeout} "${ssh_args[@]}")
    # Force client to detect dead tunnels (2 missed 10s pings ≈ 20s to disconnect).
    (( has_alive )) || ssh_args=(-o ServerAliveInterval=10 -o ServerAliveCountMax=2 "${ssh_args[@]}")

    local start_time=$SECONDS
    command ssh "${ssh_args[@]}"
    local ssh_rc=$?
    local duration=$(( SECONDS - start_time ))
    _zshkit_reset_terminal_input_modes --leave-alt-screen
    (( ssh_rc == 0 )) && return 0

    # Non-interactive — just return the exit code.
    if [[ ! -t 0 || ! -t 1 ]]; then
        return "$ssh_rc"
    fi

    # ── One-time auto-retry on connection drop (exit 255) ──
    # Only retry when the session was actually established: duration must exceed
    # ConnectTimeout, otherwise the host was unreachable (e.g. VPN down) and
    # an immediate retry would just time out again.
    if (( ssh_rc == 255 && duration > connect_timeout + 2 )); then
        stty echo icanon 2>/dev/null
        command -v tput &>/dev/null && tput rmcup 2>/dev/null
        local _dur_str
        if (( duration >= 60 )); then
            _dur_str="${$(( duration / 60 ))}m $(( duration % 60 ))s"
        else
            _dur_str="${duration}s"
        fi
        printf "sshv: connection lost (dropped after %s) — retrying once… (Ctrl+C to cancel)\n" "$_dur_str"
        # Suppress echo before the wait + retry so keystrokes don't print as raw escape sequences.
        stty -echo 2>/dev/null
        sleep 1
        _zshkit_reset_terminal_input_modes --leave-alt-screen

        # For plain `sshv host` calls (not zjs, which already has `zellij attach
        # session` baked into ssh_args), inject a one-shot smart remote command:
        # attach to the first existing Zellij session or fall back to a login shell.
        local -a _retry_args=("${ssh_args[@]}")
        if [[ "${_SSHV_NO_HINTS:-}" != 1 ]]; then
            _retry_args=(-t "${ssh_args[@]}"
                'sess=$(PATH=$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH zellij list-sessions --short --no-formatting 2>/dev/null | head -1); [[ -n "$sess" ]] && exec zellij attach "$sess" || exec $SHELL -l')
        fi

        command ssh "${_retry_args[@]}"
        ssh_rc=$?
        stty echo icanon 2>/dev/null
        _zshkit_reset_terminal_input_modes --leave-alt-screen
        (( ssh_rc == 0 )) && return 0
    fi

    # Caller handles hints (e.g. zjs) — just return.
    [[ "${_SSHV_NO_HINTS:-}" == 1 ]] && return "$ssh_rc"

    # ── Hints: reconnect command + possible VPN issue ──
    printf "sshv: connection failed (exit %d) — this may be a VPN issue. Try running vpn-connect and retrying.\n" "$ssh_rc"
    printf "  Reconnect with: sshv %s\n" "${(j: :)${(@q-)original_args}}"
    return "$ssh_rc"
}

# ── EC2 VM helper ────────────────────────────────────────────────────
# One-command access to a dev VM. Two modes:
#
# Direct SSH (no AWS required) — configure in ~/.zshrc.local:
#   export EC2_SSH_HOST="myserver"              # hostname or IP; vm connect uses this directly
#   export EC2_SSH_USER="ubuntu"
#   export EC2_SSH_KEY="$HOME/.ssh/my-key.pem"
#
# Full AWS mode (start/stop/status/auto-IP) — also add:
#   export EC2_INSTANCE_ID="i-0abc123..."
#   export EC2_REGION="us-east-2"
#   export EC2_AWS_PROFILE="my-profile"         # optional, defaults to $AWS_PROFILE
vm() {
    local ssh_host="${EC2_SSH_HOST:-}"
    local instance_id="${EC2_INSTANCE_ID:-}"
    local region="${EC2_REGION:-us-east-2}"
    local ssh_user="${EC2_SSH_USER:-ubuntu}"
    local ssh_key="${EC2_SSH_KEY:-}"
    local profile="${EC2_AWS_PROFILE:-${AWS_PROFILE:-default}}"
    local subcmd="${1:-connect}"

    if [[ -z "$ssh_key" ]]; then
        echo "vm: EC2_SSH_KEY not set. Add to ~/.zshrc.local:"
        echo "  export EC2_SSH_KEY=\"\$HOME/.ssh/your-key.pem\""
        return 1
    fi

    if [[ -z "$ssh_host" && -z "$instance_id" ]]; then
        echo "vm: not configured. Add to ~/.zshrc.local:"
        echo ""
        echo "  # Direct SSH (no AWS required):"
        echo "  export EC2_SSH_HOST=\"myserver\"             # hostname or IP"
        echo ""
        echo "  # Or full AWS integration (start/stop/status):"
        echo "  export EC2_INSTANCE_ID=\"i-0abc123...\"     # your instance ID"
        echo "  export EC2_REGION=\"us-east-2\"              # AWS region"
        echo "  export EC2_AWS_PROFILE=\"my-profile\"         # AWS CLI profile (optional)"
        echo ""
        echo "  # Required for either mode:"
        echo "  export EC2_SSH_USER=\"ubuntu\"               # SSH username"
        echo "  export EC2_SSH_KEY=\"\$HOME/.ssh/key.pem\"   # path to SSH key"
        echo ""
        echo "Reload with: source ~/.zshrc"
        return 1
    fi

    _vm_require_aws() {
        if ! command -v aws &>/dev/null; then
            echo "vm: aws CLI not installed. Required for $1."
            return 1
        fi
        if [[ -z "$instance_id" ]]; then
            echo "vm: EC2_INSTANCE_ID not set. Required for $1. Add to ~/.zshrc.local:"
            echo "  export EC2_INSTANCE_ID=\"i-0abc123...\""
            return 1
        fi
    }

    _vm_ensure_aws() {
        _vm_require_aws "$1" || return 1
        if aws sts get-caller-identity --profile "$profile" &>/dev/null; then
            return 0
        fi
        echo "AWS session expired. Opening SSO login..."
        aws sso login --profile "$profile" || { echo "SSO login failed."; return 1; }
    }

    _vm_state() {
        aws ec2 describe-instances \
            --instance-ids "$instance_id" \
            --profile "$profile" --region "$region" \
            --query 'Reservations[0].Instances[0].State.Name' \
            --output text 2>/dev/null
    }

    _vm_ip() {
        aws ec2 describe-instances \
            --instance-ids "$instance_id" \
            --profile "$profile" --region "$region" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text 2>/dev/null
    }

    case "$subcmd" in
        status)
            _vm_ensure_aws status || return 1
            local state=$(_vm_state)
            local ip=$(_vm_ip)
            echo "Instance: $instance_id ($region)"
            echo "State:    $state"
            [[ "$ip" != "None" && -n "$ip" ]] && echo "IP:       $ip"
            ;;
        start)
            _vm_ensure_aws start || return 1
            local state=$(_vm_state)
            if [[ "$state" == "running" ]]; then
                echo "Already running. IP: $(_vm_ip)"
                return 0
            fi
            echo "Starting instance..."
            aws ec2 start-instances --instance-ids "$instance_id" \
                --profile "$profile" --region "$region" >/dev/null
            echo "Waiting for instance to start..."
            aws ec2 wait instance-running --instance-ids "$instance_id" \
                --profile "$profile" --region "$region"
            echo "Running. IP: $(_vm_ip)"
            ;;
        stop)
            _vm_ensure_aws stop || return 1
            echo "Stopping instance..."
            aws ec2 stop-instances --instance-ids "$instance_id" \
                --profile "$profile" --region "$region" >/dev/null
            echo "Stop initiated."
            ;;
        ip)
            _vm_ensure_aws ip || return 1
            _vm_ip
            ;;
        connect|ssh)
            if [[ -n "$ssh_host" ]]; then
                echo "Connecting to $ssh_host..."
                command ssh -i "$ssh_key" -o ConnectTimeout=10 "$ssh_user@$ssh_host"
                return
            fi
            # No EC2_SSH_HOST — use AWS to look up IP and manage instance state
            _vm_ensure_aws connect || return 1
            local state=$(_vm_state)
            if [[ "$state" == "stopped" ]]; then
                echo "Instance is stopped. Starting it..."
                aws ec2 start-instances --instance-ids "$instance_id" \
                    --profile "$profile" --region "$region" >/dev/null
                echo "Waiting for instance to boot..."
                aws ec2 wait instance-running --instance-ids "$instance_id" \
                    --profile "$profile" --region "$region"
                echo "Waiting for SSH to be ready..."
                aws ec2 wait instance-status-ok --instance-ids "$instance_id" \
                    --profile "$profile" --region "$region"
            elif [[ "$state" != "running" ]]; then
                echo "Instance is $state — cannot connect."
                return 1
            fi
            local ip=$(_vm_ip)
            if [[ -z "$ip" || "$ip" == "None" ]]; then
                echo "vm: instance has no public IP. Does it have an Elastic IP or auto-assign enabled?"
                return 1
            fi
            echo "Connecting to $ip..."
            command ssh -i "$ssh_key" -o ConnectTimeout=10 "$ssh_user@$ip"
            ;;
        *)
            echo "Usage: vm [connect|status|start|stop|ip]"
            echo ""
            echo "  connect  Connect via SSH (default). Uses EC2_SSH_HOST directly if set;"
            echo "           otherwise uses AWS to find the IP (starts instance if stopped)."
            echo "  status   Show instance state and IP.  (AWS)"
            echo "  start    Start the instance.          (AWS)"
            echo "  stop     Stop the instance.           (AWS)"
            echo "  ip       Print the public IP.         (AWS)"
            ;;
    esac
}

# ── Remote mount helper (SSHFS) ──────────────────────────────────────
# Mount remote directories over SSH for local browsing and drag-and-drop.
# Mount points live under ~/mnt/<host>/ mirroring the remote path structure.
#
# Usage:
#   rmount <host> [remote_path]  mount remote path (default: home dir) at ~/mnt/<host>[/path]
#   rmount ls                    list active rmount mounts
#   rmount umount <host> [path]  unmount; omit path to unmount the host home mount
#   rmount open <host> [path]    mount and open in file manager
#
# Hosts from ~/.ssh/config are tab-completed.
# Requires: sshfs (installed by setup_zsh.sh).
rmount() {
    local mnt_base="$HOME/mnt"

    if ! command -v sshfs &>/dev/null; then
        echo "rmount: sshfs is not installed."
        if [[ "$(uname -s)" == "Darwin" ]]; then
            echo "  Install: brew install --cask macfuse && brew install sshfs"
            echo "  Note: macFUSE requires kernel extension approval in System Settings → Privacy & Security."
        else
            echo "  Install: sudo apt install sshfs"
        fi
        return 1
    fi

    local subcmd="${1:-}"

    case "$subcmd" in
        ls|list)
            if [[ "$(uname -s)" == "Darwin" ]]; then
                mount | grep -E "macfuse|sshfs" | grep "$mnt_base" | awk '{print $3 " ← " $1}' | sort
            else
                grep "fuse.sshfs" /proc/mounts 2>/dev/null | awk '{print $2 " ← " $1}' | grep "$mnt_base" | sort
            fi
            return 0
            ;;
        umount|unmount)
            shift
            if [[ $# -eq 0 ]]; then
                echo "usage: rmount umount <host> [remote_path]"
                return 1
            fi
            local host="$1" rpath="${2:-}"
            local mnt_dir
            if [[ -z "$rpath" ]]; then
                mnt_dir="$mnt_base/$host"
            else
                mnt_dir="$mnt_base/$host/${rpath#/}"
            fi
            if [[ ! -d "$mnt_dir" ]]; then
                echo "rmount: no mount directory at $mnt_dir"
                return 1
            fi
            local rc=0
            if [[ "$(uname -s)" == "Darwin" ]]; then
                umount "$mnt_dir" 2>/dev/null || { diskutil unmount "$mnt_dir" 2>/dev/null; rc=$?; }
            else
                fusermount -u "$mnt_dir" 2>/dev/null || { umount "$mnt_dir" 2>/dev/null; rc=$?; }
            fi
            if (( rc == 0 )); then
                echo "rmount: unmounted $mnt_dir"
                rmdir "$mnt_dir" 2>/dev/null
            else
                echo "rmount: failed to unmount $mnt_dir (rc=$rc)"
            fi
            return $rc
            ;;
        open)
            shift
            local _do_open=1
            local host="${1:-}" rpath="${2:-}"
            ;;
        -h|--help|"")
            echo "usage:"
            echo "  rmount <host> [remote_path]  mount (default: home dir)"
            echo "  rmount ls                    list active mounts"
            echo "  rmount umount <host> [path]  unmount"
            echo "  rmount open  <host> [path]   mount + open in file manager"
            [[ -z "$subcmd" ]] && return 0 || return 1
            ;;
        *)
            # First arg is the host
            local _do_open=0
            local host="$subcmd" rpath="${2:-}"
            ;;
    esac

    if [[ -z "${host:-}" ]]; then
        echo "rmount: missing host"
        echo "  usage: rmount <host> [remote_path]"
        return 1
    fi

    local mnt_dir
    if [[ -z "$rpath" ]]; then
        mnt_dir="$mnt_base/$host"
    else
        mnt_dir="$mnt_base/$host/${rpath#/}"
    fi

    # Already mounted — just report (and open if requested)
    if [[ "$(uname -s)" == "Darwin" ]]; then
        mount | grep -qE " $mnt_dir " && {
            echo "rmount: already mounted at $mnt_dir"
            (( ${_do_open:-0} )) && _open_default "$mnt_dir"
            return 0
        }
    else
        grep -q " $mnt_dir " /proc/mounts 2>/dev/null && {
            echo "rmount: already mounted at $mnt_dir"
            (( ${_do_open:-0} )) && _open_default "$mnt_dir"
            return 0
        }
    fi

    mkdir -p "$mnt_dir"

    local remote_spec
    if [[ -z "$rpath" ]]; then
        remote_spec="${host}:"          # sshfs treats empty path as home dir
    else
        remote_spec="${host}:${rpath}"
    fi

    echo "rmount: mounting $remote_spec → $mnt_dir"
    sshfs "$remote_spec" "$mnt_dir" \
        -o reconnect \
        -o ServerAliveInterval=15 \
        -o ServerAliveCountMax=3 \
        -o ConnectTimeout=10
    local rc=$?

    if (( rc == 0 )); then
        echo "rmount: mounted at $mnt_dir"
        (( ${_do_open:-0} )) && _open_default "$mnt_dir"
    else
        echo "rmount: failed to mount $remote_spec"
        rmdir "$mnt_dir" 2>/dev/null
        return $rc
    fi
}

# Tab-completion for rmount: subcommands + SSH hostnames from ~/.ssh/config
_rmount_hosts() {
    local -a hosts
    [[ -r ~/.ssh/config ]] && hosts=(${(f)"$(awk '/^[Hh]ost /{for(i=2;i<=NF;i++) if($i !~ /[*?!]/) print $i}' ~/.ssh/config 2>/dev/null)"})
    compadd -a hosts
}
_rmount_completion() {
    local state
    case $CURRENT in
        2)
            _alternative \
                'subcommands:subcommand:((ls\:"list active mounts" umount\:"unmount a mount" open\:"mount and open in file manager"))' \
                'hosts:SSH host:_rmount_hosts'
            ;;
        3)
            case $words[2] in
                umount|unmount|open) _rmount_hosts ;;
            esac
            ;;
    esac
}
compdef _rmount_completion rmount

# ── Aliases: Git (extras beyond Oh My Zsh git plugin) ────────────────

alias glog='git log --oneline --decorate --graph'
alias glp='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'
alias cdg='cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"'
alias gnb='git checkout -b'  # git new branch: gnb <branch-name>
command -v lazygit &>/dev/null && alias lg='lazygit'

# Interactive branch switcher (requires fzf)
if command -v fzf &>/dev/null; then
    unalias gbr 2>/dev/null
    function gbr {
        local branch
        branch=$(git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null | fzf) || return
        [[ -n "$branch" ]] && git checkout "$branch"
    }
fi

# Delete current branch and return to main/master
branch_bye() {
    local current main
    current=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || { echo "Not on a local branch"; return 1; }
    main=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    [[ -z "$main" ]] && main=$(git branch --list main master 2>/dev/null | sed 's/^[* ]*//' | head -n1)
    [[ -z "$main" ]] && main="main"
    [[ "$current" == "$main" ]] && { echo "Already on '$main'"; return 1; }
    git checkout "$main" && git branch -D "$current"
}

# Open PR/MR page in browser (GitHub + GitLab)
pr() {
    local remote_url repo_url branch
    remote_url=$(git config --get remote.origin.url) || { echo "No remote.origin.url found"; return 1; }

    case "$remote_url" in
        git@*:*)
            local host="${remote_url#git@}" repo_path="${remote_url#*:}"
            host="${host%%:*}"
            repo_url="https://${host}/${repo_path%.git}" ;;
        ssh://git@*)
            repo_url="https://${remote_url#ssh://git@}"
            repo_url="${repo_url%.git}" ;;
        http://*|https://*)
            repo_url="${remote_url%.git}" ;;
        *)
            echo "Unsupported remote URL: $remote_url"; return 1 ;;
    esac

    branch=$(git symbolic-ref --quiet --short HEAD) || { echo "Not on a local branch"; return 1; }

    if echo "$repo_url" | grep -qi "gitlab"; then
        local mr_url="${repo_url}/-/merge_requests/new?merge_request[source_branch]=${branch}"
        if command -v glab >/dev/null 2>&1; then
            glab mr create --web >/dev/null 2>&1 || _open_default "$mr_url" || echo "$mr_url"
        else
            _open_default "$mr_url" || echo "$mr_url"
        fi
    else
        local pr_url="${repo_url}/pull/new/${branch}"
        _open_default "$pr_url" || echo "$pr_url"
    fi
}

# ── Aliases: Python ──────────────────────────────────────────────────

alias v='source .venv/bin/activate 2>/dev/null || source venv/bin/activate 2>/dev/null || echo "No .venv or venv found"'
alias pyrun='python -m'
alias pyserver='python -m http.server'

# Auto-activate/deactivate virtualenvs on cd
_venv_auto_activate() {
    # 1. Deactivate if we've left the current virtualenv's project directory
    if [[ -n "$VIRTUAL_ENV" ]]; then
        if [[ -n "${_ZSHKIT_VENV_ANCHOR:-}" ]]; then
            # UV (or similar) env outside the repo: anchored to the directory where we auto-activated
            if [[ "$PWD" != "${_ZSHKIT_VENV_ANCHOR}" && "$PWD" != "${_ZSHKIT_VENV_ANCHOR}"/* ]]; then
                deactivate 2>/dev/null
                unset _ZSHKIT_VENV_ANCHOR
            fi
        else
            local project_dir="$VIRTUAL_ENV"
            [[ "$project_dir" == */.venv ]] && project_dir="${project_dir%/.venv}"
            [[ "$project_dir" == */venv ]] && project_dir="${project_dir%/venv}"
            # In-project .venv / venv only; external paths (no suffix) skip auto-deactivate
            if [[ "$VIRTUAL_ENV" != "$project_dir" && "$PWD" != "$project_dir" && "$PWD" != "$project_dir"/* ]]; then
                deactivate 2>/dev/null
            fi
        fi
    else
        unset _ZSHKIT_VENV_ANCHOR
    fi

    # 2. Activate if we are in a directory with a virtualenv (and not already in one)
    if [[ -z "$VIRTUAL_ENV" ]]; then
        if [[ -d .venv ]]; then
            source .venv/bin/activate 2>/dev/null
        elif [[ -d venv ]]; then
            source venv/bin/activate 2>/dev/null
        elif [[ -f pyproject.toml && -n "${UV_PROJECT_ENVIRONMENT:-}" && -r "$UV_PROJECT_ENVIRONMENT/bin/activate" ]]; then
            # uv: non-default venv path (see https://docs.astral.sh/uv/concepts/projects/#project-environment-path)
            source "$UV_PROJECT_ENVIRONMENT/bin/activate" 2>/dev/null && _ZSHKIT_VENV_ANCHOR="$PWD"
        fi
    fi
}
add-zsh-hook chpwd _venv_auto_activate
_venv_auto_activate

# ── FZF configuration ────────────────────────────────────────────────

if command -v fzf &>/dev/null; then
    if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi
    export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND:-}"

    # Neutral color scheme (works on light and dark terminals)
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --inline-info'

    if command -v bat &>/dev/null; then
        export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :500 {}'"
    fi
fi

# ── Functions ────────────────────────────────────────────────────────

# Yazi wrapper: quit yazi and cd into the directory you navigated to.
yy() {
    local tmp cwd
    tmp="$(mktemp "${TMPDIR:-/tmp}/yazi-cwd.XXXXXX")"
    {
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
            builtin cd -- "$cwd"
        fi
    } always {
        rm -f -- "$tmp"
    }
}

# Find files by name
ff() {
    local pattern="${1:?usage: ff PATTERN}"
    if command -v fd &>/dev/null; then
        fd -HI -t f --glob "*${pattern}*" .
    else
        find . -type f -iname "*${pattern}*" 2>/dev/null
    fi
}

# Find text in files (prefer ripgrep)
ftext() {
    local pattern="${1:?usage: ftext PATTERN}"
    if command -v rg &>/dev/null; then
        rg --smart-case --hidden -g '!.git' "$pattern"
    else
        grep -RIn --exclude-dir=.git -e "$pattern" . 2>/dev/null
    fi
}

# Show listening ports/processes
ports() {
    if command -v ss &>/dev/null; then
        ss -tulanp
    elif command -v netstat &>/dev/null; then
        if [[ "$(uname -s)" == "Darwin" ]]; then
            local netstat_out
            netstat_out="$(netstat -an -f inet | grep -E 'LISTEN|ESTABLISHED' || true)"
            if [[ -n "$netstat_out" ]]; then
                echo "$netstat_out"
            else
                echo "No LISTEN/ESTABLISHED IPv4 sockets found."
            fi
        else
            netstat -tulanp
        fi
    elif command -v lsof &>/dev/null; then
        lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null
    else
        echo "No port tool found (install ss, netstat, or lsof)."
        return 1
    fi
}

# Open current directory in file manager
f() { _open_default "."; }

# Create directory and cd into it
mkcd() { [[ -z "$1" ]] && { echo "usage: mkcd <dir>"; return 1; }; mkdir -p "$1" && cd "$1"; }

# Delete a Zellij session if it is listed as EXITED (dead process, safe to remove).
_zshkit_zellij_delete_if_exited() {
    local session="${1:?session name required}"
    zellij list-sessions --no-formatting 2>/dev/null | grep -q "^${session} .*EXITED" || return 0
    echo "zj: session '$session' has exited, removing..."
    if ! zellij delete-session --force "$session" 2>/dev/null; then
        echo "zj: failed to remove exited session '$session'; run 'zellij delete-session --force $session' and retry."
        return 1
    fi
    return 0
}

# Zellij session helper
# Usage: zj [session-name]   outside Zellij: attach to or create a named session
#        zj                  pick from existing sessions, or start a new one
# Inside Zellij: ensures the target session exists, then prints the shortcut to switch.
zj() {
    if ! command -v zellij &>/dev/null; then
        echo "zj: zellij is not installed. Run setup_zsh.sh first."
        return 1
    fi

    local session
    if [[ $# -eq 0 ]]; then
        local sessions
        # Exclude EXITED sessions — they show up in --short output but aren't usable.
        sessions=$(zellij list-sessions --no-formatting 2>/dev/null | grep -v "EXITED" | sed 's/ .*//')
        if [[ -z "$sessions" ]]; then
            # Default new session name to current directory name
            session="${PWD##*/}"
            echo "No active Zellij sessions. Starting '$session'..."
        elif command -v fzf &>/dev/null; then
            session=$(printf '%s\n' "$sessions" | fzf --prompt="session > " --height=10 --layout=reverse --border) || return 0
        else
            echo "Active sessions:"
            printf '%s\n' "$sessions" | nl -ba -w2 -s') '
            printf "Pick session (or Enter for 'main'): "
            read -r session
            [[ -z "$session" ]] && session="main"
        fi
    else
        session="$1"
    fi

    if [[ -n "${ZELLIJ:-}" ]]; then
        _zshkit_zellij_delete_if_exited "$session" || return 1
        if ! zellij list-sessions --short --no-formatting 2>/dev/null | grep -Fxq "$session"; then
            zellij attach --create-background "$session" || return 1
            echo "zj: session '$session' created. Press Ctrl+o → w to switch to it."
        else
            echo "zj: press Ctrl+o → w to switch to '$session'."
        fi
    else
        _zshkit_zellij_delete_if_exited "$session" || return 1
        zellij attach --create "$session"
        local zj_rc=$?
        # Zellij can leave mouse or Kitty/Ghostty keyboard modes enabled after an abrupt
        # exit, which causes raw escape sequences to leak into the shell prompt.
        _zshkit_reset_terminal_input_modes --leave-alt-screen
        return $zj_rc
    fi
}

# Delete all Zellij sessions, scrollback/resurrection data, and plugin cache.
zjclean() {
    local all_sessions sessions active_session
    all_sessions=$(zellij list-sessions --no-formatting 2>/dev/null)
    sessions=$(printf '%s\n' "$all_sessions" | sed 's/ .*//')
    active_session="${ZELLIJ_SESSION_NAME:-}"

    if [[ -z "$sessions" ]]; then
        echo "No Zellij sessions. Clearing cache only."
    else
        echo "Sessions to delete:"
        printf '%s\n' "$all_sessions" | sed 's/^/  /'
    fi
    if ! read -q "_zjclean_confirm?Delete all sessions, scrollback, and plugin cache? [y/N] "; then
        echo -e "\nAborted."
        return 0
    fi
    echo ""
    if [[ -n "$sessions" ]]; then
        printf '%s\n' "$sessions" | while IFS= read -r s; do
            if [[ "$s" == "$active_session" ]]; then
                echo "  ~ $s (skipped: cannot delete active session, detach first)"
                continue
            fi
            zellij delete-session --force "$s" 2>/dev/null \
                && echo "  ✓ $s" \
                || echo "  ✗ $s (failed)"
        done
    fi
    if [[ -d "${HOME}/.cache/zellij" ]]; then
        rm -rf "${HOME}/.cache/zellij"
        echo "  ✓ cache cleared (~/.cache/zellij)"
    fi
}

# SSH into a host and attach to (or create) a named Zellij session.
# Requires zshkit (and therefore zellij) installed on the remote.
# Usage: zjs host [session]
#   zjs myserver          → attach to/create session "main"
#   zjs myserver work     → attach to/create session "work"
zjs() {
    local host="${1:?usage: zjs host [session]}"
    local session="${2:-main}"
    local remote_cmd

    # Kill stale zjs clients for this session so Zellij resizes to our terminal.
    # Zellij constrains a session to the smallest attached client; lingering SSH
    # processes from a previous connection hold the session at the old (smaller) size.
    remote_cmd=$(cat <<EOF
pkill -x zjs-"$session" 2>/dev/null
sleep 0.3
if PATH=\$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:\$PATH zellij list-sessions --no-formatting 2>/dev/null | grep -q "^$session .*EXITED"; then
    echo "zjs: session '$session' has exited on remote, removing..."
    PATH=\$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:\$PATH zellij delete-session --force "$session" 2>/dev/null || {
        echo "zjs: failed to remove exited remote session '$session'."
        exit 1
    }
fi
PATH=\$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:\$PATH exec -a zjs-"$session" zellij attach --create "$session"
EOF
)
    printf "Connecting to %s (session: %s)…\n" "$host" "$session"
    _SSHV_NO_HINTS=1 sshv -o ConnectTimeout=15 -t "$host" "$remote_cmd"
    local zjs_rc=$?
    _zshkit_reset_terminal_input_modes --leave-alt-screen
    if (( zjs_rc != 0 )) && [[ -t 0 && -t 1 ]]; then
        printf "zjs: connection failed (exit %d) — this may be a VPN issue. Try running vpn-connect and retrying.\n" "$zjs_rc"
        printf "  Reconnect with: zjs %s %s\n" "$host" "$session"
    fi
    return $zjs_rc
}


# Auto-fetch git remotes in the background so the p10k prompt ahead/behind
# counts stay current. Runs at most once per 60 seconds per repo.
_zshkit_auto_fetch() {
    local repo
    repo=$(git rev-parse --show-toplevel 2>/dev/null) || return
    local marker="$repo/.git/.zshkit_last_fetch"
    local mtime=0
    [[ -f "$marker" ]] && mtime=$(stat -c %Y "$marker" 2>/dev/null || stat -f %m "$marker" 2>/dev/null || echo 0)
    if (( EPOCHSECONDS - mtime > 60 )); then
        touch "$marker"
        git -C "$repo" fetch -q --all </dev/null &!
    fi
}
add-zsh-hook precmd _zshkit_auto_fetch

# Show disk usage of directories (top 10)
# sort -h (human-readable) is GNU coreutils; macOS BSD sort lacks it.
ducks() {
    if command -v gsort &>/dev/null; then
        du -sh * 2>/dev/null | gsort -hr | head -11
    elif [[ "$(uname -s)" != "Darwin" ]]; then
        du -sh * 2>/dev/null | sort -hr | head -11
    else
        du -sk * 2>/dev/null | sort -rn | head -11 | awk '{printf "%s\t%s\n", $1"K", $2}'
    fi
}

# Quick reload
alias reload='source ~/.zshrc && echo "✓ zsh config reloaded"'
# One-command setup/update from this repo.
# Set ZSHKIT_DIR in ~/.zshrc.local to point at your clone if it's not at ~/repos/zshkit.
zsetup() {
    local dir="${ZSHKIT_DIR:-$HOME/repos/zshkit}"
    local script="$dir/setup_zsh.sh"
    [[ -x "$script" || -f "$script" ]] || { echo "zsetup: $script not found (set ZSHKIT_DIR in ~/.zshrc.local)"; return 1; }
    bash "$script" && exec zsh
}

# Safe multiline paste: write a command block to a temp file, then review and run it.
# Usage: paste-run, paste your command block, press Ctrl+D, then: bash /tmp/paste-run.XXXX.sh
paste-run() {
    emulate -L zsh
    local tmp
    tmp="$(mktemp "${TMPDIR:-/tmp}/paste-run.XXXXXX.sh")" || return 1
    echo "Paste your command block, then press Ctrl+D:"
    cat > "$tmp"
    chmod +x "$tmp"
    echo
    echo "Saved to: $tmp"
    echo "Review with:  sed -n '1,200p' $tmp"
    echo "Run with:     bash $tmp"
}


# ── History ──────────────────────────────────────────────────────────

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY
typeset -g _share_history_pref="${ZSH_SHARE_HISTORY:-0}"
case "${_share_history_pref:l}" in
    1|on|true|yes) setopt SHARE_HISTORY ;;
    *) unsetopt SHARE_HISTORY ;;
esac
unset _share_history_pref
# INC_APPEND_HISTORY is implied by SHARE_HISTORY; only set when not sharing.
[[ -o sharehistory ]] || setopt INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY

# ── Autosuggestions ──────────────────────────────────────────────────

# Show suggestions as you type (history first, then completion fallback).
# match_prev_cmd: prefer history entries that followed the same previous command
# (e.g. after `git add`, suggest `git commit` over `git log`).
ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=80
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'  # visible ghost text on both light/dark
# We define custom widgets later, so do one bind pass after all widget changes.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
# Don't suggest dangerous commands from history.
ZSH_AUTOSUGGEST_HISTORY_IGNORE='rm -rf *|sudo rm *|:(){ :|:& };:'

# Autosuggestions plugin is sourced at the very end of this file (after syntax-highlighting).

# Keep autosuggest acceptance explicit: Ctrl+Space/End/Right (not Tab or Up/Down).
typeset -ga ZSH_AUTOSUGGEST_ACCEPT_WIDGETS
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(
    autosuggest-accept
    end-of-line
    vi-end-of-line
    vi-add-eol
)

typeset -ga ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS=(
    vi-forward-char
    forward-char
    forward-word
    _forward_char_with_autolist
    _forward_word_with_autolist
)

# ── Shell QoL options ────────────────────────────────────────────────

# Prevent accidental Ctrl+S from freezing terminal output (XON/XOFF flow control),
# which is especially confusing inside multiplexers over SSH.
if [[ -o interactive ]]; then
    stty -ixon -ixoff 2>/dev/null || true
fi

setopt AUTO_CD              # Type a dir name to cd into it (no 'cd' needed)
setopt AUTO_PUSHD           # cd pushes onto the dir stack (use 'cd -N' to go back)
setopt PUSHD_IGNORE_DUPS    # No duplicate dirs on the stack
setopt PUSHD_SILENT         # Don't print dir stack after pushd/popd
typeset -g _correct_pref="${ZSH_ENABLE_CORRECTION:-0}"
case "${_correct_pref:l}" in
    1|on|true|yes) setopt CORRECT ;;  # Offer correction for mistyped commands
    *) unsetopt CORRECT ;;
esac
unset _correct_pref
setopt INTERACTIVE_COMMENTS # Allow # comments in interactive shell
setopt GLOB_DOTS            # Include dotfiles in glob patterns
setopt AUTO_LIST            # Show completion options below prompt on ambiguous matches
setopt AUTO_MENU            # Repeated completion keys cycle through matches
unsetopt MENU_COMPLETE      # Keep list+menu behavior instead of replacing buffer immediately

# Prompt before printing very large completion lists (prevents terminal spam).
LISTMAX=20

# ── Key bindings ─────────────────────────────────────────────────────

# Sticky prefix history search: keeps original typed query while cycling.
# Uses a flag + saved HISTNO instead of LASTWIDGET (which plugin wrapping can
# alter). All _* widgets must clear POSTDISPLAY manually since zsh-autosuggestions
# skips wrapping them.
typeset -g _history_prefix_query=""
typeset -gi _history_scroll_active=0
typeset -gi _history_scroll_histno=0
typeset -g _history_scroll_last_buffer=""
_history_prefix_search_up() {
    # zsh-autosuggestions skips wrapping _* widgets, so clear ghost text manually.
    unset POSTDISPLAY
    if (( !_history_scroll_active )) || [[ "$BUFFER" != "$_history_scroll_last_buffer" ]]; then
        _history_prefix_query="$BUFFER"
        _history_scroll_active=1
    else
        # Restore history position so the search continues where we left off.
        HISTNO=$_history_scroll_histno
    fi
    CURSOR=${#_history_prefix_query}
    zle .history-beginning-search-backward
    _history_scroll_histno=$HISTNO
    zle .end-of-line
    _history_scroll_last_buffer="$BUFFER"
}
_history_prefix_search_down() {
    unset POSTDISPLAY
    if (( !_history_scroll_active )) || [[ "$BUFFER" != "$_history_scroll_last_buffer" ]]; then
        _history_prefix_query="$BUFFER"
        _history_scroll_active=1
        _history_scroll_histno=$HISTNO
    else
        HISTNO=$_history_scroll_histno
    fi
    local -i old_histno=$HISTNO
    CURSOR=${#_history_prefix_query}
    zle .history-beginning-search-forward
    if (( HISTNO == old_histno )); then
        # No forward match — restore original input
        BUFFER="$_history_prefix_query"
        CURSOR=${#BUFFER}
        _history_scroll_active=0
    else
        _history_scroll_histno=$HISTNO
        zle .end-of-line
    fi
    _history_scroll_last_buffer="$BUFFER"
}
zle -N _history_prefix_search_up
zle -N _history_prefix_search_down

# Smart Down: keep history scrolling when active; otherwise open a navigable
# completion menu for cd/pushd/popd, AUTO_CD-style path input, or path-like
# args without eagerly applying the first match.
_down_history_or_dirs() {
    unset POSTDISPLAY
    local in_history_scroll=0

    # Detect active history scroll: flag is set AND buffer hasn't been edited.
    if (( _history_scroll_active )) && [[ "$BUFFER" == "$_history_scroll_last_buffer" ]]; then
        in_history_scroll=1
    fi

    if (( in_history_scroll )); then
        zle _history_prefix_search_down
    elif [[ -n "$_auto_list_last_buffer" && "$LBUFFER" == "$_auto_list_last_buffer" ]]; then
        # Auto-list is showing for the current position — Down enters the grid
        # so the user can navigate with arrow keys and select with Enter.
        _auto_list_last_buffer=""
        if (( $+widgets[menu-select] )); then
            zle menu-select
        elif (( $+widgets[expand-or-complete] )); then
            zle expand-or-complete
        else
            zle .expand-or-complete
        fi
    else
        zle _history_prefix_search_down
    fi
}
zle -N _down_history_or_dirs

_tab_complete_and_autolist() {
    # Enter the native completion menu. expand-or-complete inserts directly for a
    # unique match; for multiple matches menu select (configured via zstyle) opens
    # the interactive grid automatically.
    _auto_list_last_buffer=""
    local _lbuf_before="$LBUFFER"
    if (( $+widgets[expand-or-complete] )); then
        zle expand-or-complete
    else
        zle .expand-or-complete
    fi
    # If the buffer didn't change, Tab showed a list rather than auto-inserting.
    # Arm _auto_list_last_buffer so Down immediately enters the menu.
    [[ "$LBUFFER" == "$_lbuf_before" ]] && _auto_list_last_buffer="$LBUFFER"
}
zle -N _tab_complete_and_autolist

_cd_tab_complete() {
    # Deterministic cd drill-down: append / if dir, then open native menu.
    (( CURSOR == ${#BUFFER} )) || { zle list-choices; return 0; }

    local _tail="${BUFFER##*[[:space:]]}"
    local _expanded=""

    if [[ "$_tail" == /* ]]; then
        _expanded="$_tail"
    elif [[ "$_tail" == ~* ]]; then
        _expanded="${_tail/#\~/$HOME}"
    elif [[ -n "$_tail" ]]; then
        _expanded="$PWD/$_tail"
    fi

    if [[ -n "$_tail" && "$BUFFER" != */ && -d "$_expanded" ]]; then
        BUFFER="${BUFFER}/"
        CURSOR=${#BUFFER}
    fi

    _auto_list_last_buffer=""
    zle expand-or-complete
    local LISTMAX=0
    zle list-choices
}
zle -N _cd_tab_complete

_tab_accept_or_complete() {
    # If autosuggestion ghost text is visible, Tab accepts it fully.
    if [[ -n "$POSTDISPLAY" ]]; then
        (( $+widgets[autosuggest-accept] )) && zle autosuggest-accept
        # After accepting ghost text for a cd command, if the result ends in /
        # immediately show the next level so the user doesn't need a second Tab.
        local _cmd="${BUFFER%%[[:space:]]*}"
        if [[ "$_cmd" == "cd" || "$_cmd" == "pushd" || "$_cmd" == "popd" ]] \
           && [[ "$BUFFER" == */ ]]; then
            _auto_list_last_buffer="$LBUFFER"
            local LISTMAX=0
            zle list-choices
        fi
        return 0
    fi
    # cd/pushd/popd: deterministic drill-down with / appending.
    local _cmd="${BUFFER%%[[:space:]]*}"
    if [[ "$_cmd" == "cd" || "$_cmd" == "pushd" || "$_cmd" == "popd" ]]; then
        zle _cd_tab_complete
        return 0
    fi
    # No ghost text and not a cd command — enter the completion menu.
    zle _tab_complete_and_autolist
}
zle -N _tab_accept_or_complete

# Auto-show completion list while typing (for manageable candidate sets).
# Configurable: 1/on/true/yes enables; 0/off/false/no disables.
# Default is OFF — safer for pasting multiline commands. Opt in via ~/.zshrc.local.
: "${ZSH_AUTOLIST_ON_TYPE:=0}"
# When typing `cd ` + space with an empty argument, auto-open early only when
# local directory count is small (keeps this useful but non-spammy).
: "${ZSH_AUTOLIST_CD_EMPTY_MAX:=20}"
# Minimum characters before auto-list triggers (reduces lag on slow filesystems).
: "${ZSH_AUTOLIST_MIN_CHARS:=3}"
typeset -g _auto_list_last_buffer=""
typeset -gi _auto_list_in_paste=0
# Tracks last self-insert time; used to detect rapid programmatic input (e.g. VSCode play button).
typeset -gF _zshkit_last_selfinsert_rt=0.0
typeset -g _autolist_cd_cache_pwd=""
typeset -gi _autolist_cd_cache_count=-1
typeset -gi _autolist_cd_cache_limit=-1

_autolist_invalidate_cd_cache() {
    _autolist_cd_cache_pwd=""
    _autolist_cd_cache_count=-1
    _autolist_cd_cache_limit=-1
}

_should_autolist_empty_cd_arg() {
    local _raw="${ZSH_AUTOLIST_CD_EMPTY_MAX:-20}"
    local -i _max=20
    local -i _count=0
    local _d

    [[ "$_raw" == <-> ]] && _max=$_raw
    (( _max < 0 )) && _max=0

    # Reuse count in same directory to avoid repeated glob scans while typing.
    if [[ "$_autolist_cd_cache_pwd" == "$PWD" && $_autolist_cd_cache_count -ge 0 ]] \
       && (( _autolist_cd_cache_limit < 0 || _max <= _autolist_cd_cache_limit )); then
        _count=$_autolist_cd_cache_count
    else
        # Count local directory candidates quickly and stop once threshold is passed.
        setopt localoptions nullglob
        for _d in * .*; do
            [[ "$_d" == "." || "$_d" == ".." ]] && continue
            [[ -d "$_d" ]] || continue
            (( _count++ ))
            (( _count > _max )) && break
        done
        _autolist_cd_cache_pwd="$PWD"
        _autolist_cd_cache_count=$_count
        if (( _count > _max )); then
            _autolist_cd_cache_limit=$_max
        else
            _autolist_cd_cache_limit=-1
        fi
    fi
    (( _count <= _max ))
}

_maybe_auto_list_choices() {
    # Only while typing at end-of-line; avoid noisy redraws.
    (( _auto_list_in_paste )) && return
    # Never fire for multiline buffers (e.g. continued commands after paste).
    [[ "$BUFFER" == *$'\n'* ]] && return
    (( KEYS_QUEUED_COUNT > 0 )) && return
    (( CURSOR == ${#BUFFER} )) || return
    [[ "$LBUFFER" == "$_auto_list_last_buffer" ]] && return

    local -a _words _path_popup_cmds
    local _current _cmd _is_cd_context=0 _is_ssh_context=0 _has_trailing_space=0
    local -i _is_path_cmd=0 _is_path_like=0
    _path_popup_cmds=(
        cd pushd popd
        ls cat less more vim nano
        rm cp mv mkdir rmdir touch
        ssh scp rsync
    )
    [[ "$LBUFFER" == *[[:space:]] ]] && _has_trailing_space=1
    _words=(${(z)LBUFFER})
    (( ${#_words} )) || return
    _current="${_words[-1]}"
    _cmd="${_words[1]}"
    (( ${_path_popup_cmds[(Ie)$_cmd]} )) && _is_path_cmd=1

    # Always allow path completion previews for cd-like commands once an
    # argument has started (e.g., "cd D" should immediately list candidates).
    if [[ "$_cmd" == "cd" || "$_cmd" == "pushd" || "$_cmd" == "popd" ]]; then
        (( ${#_words} >= 2 )) && _is_cd_context=1
    fi
    if [[ "$_cmd" == "ssh" || "$_cmd" == "scp" || "$_cmd" == "rsync" ]]; then
        (( ${#_words} >= 2 )) && _is_ssh_context=1
    fi

    # After a space, refresh completions for the next argument position.
    if (( _has_trailing_space )); then
        # On bare `cd `, only auto-open if candidate set is small.
        if [[ "$_cmd" == "cd" || "$_cmd" == "pushd" || "$_cmd" == "popd" ]]; then
            if (( ${#_words} == 1 )); then
                if _should_autolist_empty_cd_arg; then
                    _auto_list_last_buffer="$LBUFFER"
                    local LISTMAX=0
                    zle list-choices
                fi
                return
            fi
        fi

        # Keep command-position noise off in auto mode.
        (( ${#_words} >= 2 )) || return
        # Restrict auto-popups to path/host oriented commands.
        if (( ! _is_path_cmd )); then
            return
        fi
        _auto_list_last_buffer="$LBUFFER"
        local LISTMAX=0
        zle list-choices
        return
    fi

    # Keep command-position auto-list quiet (avoid external command spam).
    if (( ${#_words} == 1 )) && [[ "$_current" != */* && "$_current" != .* && "$_current" != ~* ]]; then
        return
    fi

    # Don't spam for tiny prefixes or option flags; respect min chars to reduce lag.
    [[ -n "$_current" ]] || return
    local -i _min_chars=3
    [[ "${ZSH_AUTOLIST_MIN_CHARS:-3}" == <-> ]] && _min_chars=$ZSH_AUTOLIST_MIN_CHARS
    if (( ! _is_cd_context )); then
        (( ${#_current} >= _min_chars )) || return
        [[ "$_current" == -* ]] && return
    fi

    [[ "$_current" == */* || "$_current" == .* || "$_current" == ~* || "$_current" == <-> ]] && _is_path_like=1

    # Keep it focused to common completion contexts.
    if (( _is_cd_context || _is_ssh_context || (_is_path_like && _is_path_cmd) )); then
        _auto_list_last_buffer="$LBUFFER"
        local LISTMAX=0
        zle list-choices
    fi
}
zle -N _maybe_auto_list_choices

_self_insert_with_autolist() {
    local _now=$EPOCHREALTIME
    # Chars arriving <30ms apart = programmatic injection (e.g. VSCode play button).
    # Skip autolist to prevent flickering menu and per-char completion lookups.
    local -i _rapid=$(( (_now - _zshkit_last_selfinsert_rt) < 0.030 ))
    _zshkit_last_selfinsert_rt=$_now

    (( _auto_list_in_paste || KEYS_QUEUED_COUNT > 0 || _rapid )) && {
        if (( $+widgets[autosuggest-self-insert] )); then
            zle autosuggest-self-insert
        else
            zle .self-insert
        fi
        return
    }

    if (( $+widgets[autosuggest-self-insert] )); then
        zle autosuggest-self-insert
    else
        zle .self-insert
    fi
    _history_scroll_active=0
    zle _maybe_auto_list_choices
}
zle -N _self_insert_with_autolist

_magic_space_with_autolist() {
    if (( $+widgets[autosuggest-magic-space] )); then
        zle autosuggest-magic-space
    else
        zle .magic-space
    fi
    _history_scroll_active=0
    _auto_list_last_buffer=""
    zle _maybe_auto_list_choices
}
zle -N _magic_space_with_autolist

_accept_line_with_autolist_reset() {
    _history_scroll_active=0
    _auto_list_last_buffer=""
    if (( $+widgets[autosuggest-accept-line] )); then
        zle autosuggest-accept-line
    else
        zle .accept-line
    fi
}
zle -N _accept_line_with_autolist_reset

_bracketed_paste_with_autofix() {
    local _old_autolist="${ZSH_AUTOLIST_ON_TYPE:-0}"
    local _paste
    local _lbuf_before="$LBUFFER" _rbuf_before="$RBUFFER"
    local -i _line_count _char_count

    _auto_list_in_paste=1
    ZSH_AUTOLIST_ON_TYPE=0
    _history_scroll_active=0
    _auto_list_last_buffer=""
    unset POSTDISPLAY

    zle .bracketed-paste _paste

    BUFFER="${_lbuf_before}${_paste}${_rbuf_before}"
    _line_count=${#${(f)_paste}}
    _char_count=${#_paste}

    # For multiline pastes, anchor cursor at the start of the inserted block
    # so the top is visible first. Huge pastes open in the editor instead.
    if [[ "$_paste" == *$'\n'* ]]; then
        if (( _line_count >= 40 || _char_count > COLUMNS * 32 )); then
            CURSOR=${#_lbuf_before}
            _auto_list_in_paste=0
            ZSH_AUTOLIST_ON_TYPE="$_old_autolist"
            _history_scroll_active=0
            _auto_list_last_buffer=""
            autoload -Uz edit-command-line
            (( $+widgets[edit-command-line] )) || zle -N edit-command-line
            zle edit-command-line
            return
        else
            CURSOR=${#_lbuf_before}
        fi
    else
        CURSOR=$(( ${#_lbuf_before} + ${#_paste} ))
    fi

    _auto_list_in_paste=0
    ZSH_AUTOLIST_ON_TYPE="$_old_autolist"
    _history_scroll_active=0
    _auto_list_last_buffer=""
    zle -I
    zle redisplay
}
zle -N _bracketed_paste_with_autofix

_forward_char_with_autolist() {
    zle .forward-char
    _auto_list_last_buffer=""
    zle _maybe_auto_list_choices
}
zle -N _forward_char_with_autolist

_forward_word_with_autolist() {
    zle .forward-word
    _auto_list_last_buffer=""
    zle _maybe_auto_list_choices
}
zle -N _forward_word_with_autolist

_backward_delete_char_with_autolist() {
    zle .backward-delete-char
    _history_scroll_active=0
    _auto_list_last_buffer=""
    zle _maybe_auto_list_choices
}
zle -N _backward_delete_char_with_autolist

_autolist_is_enabled() {
    local _v="${ZSH_AUTOLIST_ON_TYPE:-0}"
    _v="${_v:l}"
    [[ "$_v" == "1" || "$_v" == "on" || "$_v" == "true" || "$_v" == "yes" ]]
}

_apply_autolist_mode() {
    if _autolist_is_enabled; then
        zle -N self-insert _self_insert_with_autolist
        zle -N magic-space _magic_space_with_autolist
        zle -N accept-line _accept_line_with_autolist_reset
        zle -N bracketed-paste _bracketed_paste_with_autofix
        zle -N forward-char _forward_char_with_autolist
        zle -N forward-word _forward_word_with_autolist
        zle -N backward-delete-char _backward_delete_char_with_autolist
    else
        if (( $+widgets[autosuggest-self-insert] )); then
            zle -A autosuggest-self-insert self-insert
        else
            zle -A .self-insert self-insert
        fi
        if (( $+widgets[autosuggest-magic-space] )); then
            zle -A autosuggest-magic-space magic-space
        else
            zle -A .magic-space magic-space
        fi
        if (( $+widgets[autosuggest-accept-line] )); then
            zle -A autosuggest-accept-line accept-line
        else
            zle -A .accept-line accept-line
        fi
        zle -A .forward-char forward-char
        zle -A .forward-word forward-word
        zle -A .backward-delete-char backward-delete-char
    fi
    # Always register auto-fix paste handler regardless of autolist mode.
    zle -N bracketed-paste _bracketed_paste_with_autofix
}

# Reset history scroll flag at each new prompt so stale state never leaks.
_reset_history_scroll() { _history_scroll_active=0; }

# Reset terminal input modes before each prompt so an abrupt SSH/Zellij
# disconnect never leaves the terminal dumping raw escape sequences.
_reset_terminal_input_modes() {
    _zshkit_reset_terminal_input_modes
}

# Keep directory-count cache fresh while avoiding repeated scans in a single edit.
if (( $+functions[add-zsh-hook] )); then
    add-zsh-hook -D precmd _reset_history_scroll 2>/dev/null
    add-zsh-hook precmd _reset_history_scroll
    add-zsh-hook -D precmd _reset_terminal_input_modes 2>/dev/null
    add-zsh-hook precmd _reset_terminal_input_modes
    add-zsh-hook -D chpwd _autolist_invalidate_cd_cache 2>/dev/null
    add-zsh-hook chpwd _autolist_invalidate_cd_cache
    # Ensure our paste auto-fix stays registered. zsh-autosuggestions overrides
    # bracketed-paste when it loads (via zsh-defer). This precmd hook re-registers
    # our widget before each prompt so the override can't stick.
    _ensure_paste_autofix() {
        [[ "${widgets[bracketed-paste]:-}" == "user:_bracketed_paste_with_autofix" ]] && return
        (( $+functions[_bracketed_paste_with_autofix] )) && \
            zle -N bracketed-paste _bracketed_paste_with_autofix
    }
    add-zsh-hook -D precmd _ensure_paste_autofix 2>/dev/null
    add-zsh-hook precmd _ensure_paste_autofix
fi

if [[ -o interactive ]]; then
    # Apply autolist widget wrappers before plugins load so zsh-autosuggestions
    # wraps _self_insert_with_autolist (not the raw builtin), preserving ghost text.
    _apply_autolist_mode

    # Arrow keys → sticky prefix history search
    [[ -n "${terminfo[kcuu1]}" ]] && bindkey "${terminfo[kcuu1]}" _history_prefix_search_up
    [[ -n "${terminfo[kcud1]}" ]] && bindkey "${terminfo[kcud1]}" _down_history_or_dirs
    bindkey '^[[A' _history_prefix_search_up
    bindkey '^[[B' _down_history_or_dirs
    bindkey '^[OA' _history_prefix_search_up
    bindkey '^[OB' _down_history_or_dirs
    bindkey '^P'   _history_prefix_search_up
    bindkey '^N'   _down_history_or_dirs
    bindkey '^I' _tab_accept_or_complete
    bindkey '^[[Z' reverse-menu-complete      # Shift+Tab

    # Completion menu navigation
    bindkey -M menuselect '^I'   menu-complete
    bindkey -M menuselect '^[[Z' reverse-menu-complete
    [[ -n "${terminfo[kcuu1]}" ]] && bindkey -M menuselect "${terminfo[kcuu1]}" up-line-or-history
    [[ -n "${terminfo[kcud1]}" ]] && bindkey -M menuselect "${terminfo[kcud1]}" down-line-or-history
    bindkey -M menuselect '^[[A' up-line-or-history
    bindkey -M menuselect '^[[B' down-line-or-history
    bindkey -M menuselect '^[OA' up-line-or-history
    bindkey -M menuselect '^[OB' down-line-or-history
    # Escape cancels menu selection; Left/Right move across grid-style menus.
    bindkey -M menuselect '\e'    send-break
    bindkey -M menuselect '^[[C'  forward-char
    bindkey -M menuselect '^[OC'  forward-char
    bindkey -M menuselect '^[[D'  backward-char
    bindkey -M menuselect '^[OD'  backward-char

    # Right arrow: partial-accept one char from suggestion (forward-char in ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS)
    # Ctrl+Right / Alt+F: partial-accept one word from suggestion (forward-word)
    # Ctrl+Space / End: accept the full autosuggestion
    # Tab: accept ghost text if present, otherwise open native completion menu
    bindkey '^[[C' forward-char
    bindkey '^[OC' forward-char
    bindkey '^[[F' end-of-line
    bindkey '^[OF' end-of-line

    # Ctrl+Right / Alt+F: partial-accept one word from suggestion
    bindkey '^[[1;5C' forward-word
    bindkey '^[f'     forward-word

    # Ctrl+Z: undo last edit on command line
    bindkey '^Z' undo


fi

# ── Pyenv (if installed) ────────────────────────────────────────────

if [ -d "$HOME/.pyenv" ]; then
    # Avoid pyenv/conda PATH collisions when conda is active.
    # Override with ZSH_FORCE_PYENV=1 to keep pyenv wrappers enabled.
    typeset -gi _conda_active=0
    [[ -n "${CONDA_PREFIX:-}" ]] && _conda_active=1
    if [[ "${CONDA_SHLVL:-0}" == <-> ]] && (( CONDA_SHLVL > 0 )); then
        _conda_active=1
    fi
    if (( ! _conda_active )) || [[ "${ZSH_FORCE_PYENV:-0}" == "1" ]]; then
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        _pyenv_bootstrap() {
            unfunction _pyenv_bootstrap pyenv python pip pip3 2>/dev/null
            eval "$(command pyenv init -)"
            if command pyenv commands 2>/dev/null | grep -q virtualenv-init; then
                eval "$(command pyenv virtualenv-init -)"
            fi
        }
        pyenv()  { _pyenv_bootstrap; command pyenv "$@"; }
        python() { _pyenv_bootstrap; command python "$@"; }
        pip()    { _pyenv_bootstrap; command pip "$@"; }
        pip3()   { _pyenv_bootstrap; command pip3 "$@"; }
    fi
    unset _conda_active
fi

# ── Powerlevel10k config ─────────────────────────────────────────────

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ── Local overrides (not managed by setup script) ────────────────────

[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# Allow ~/.zshrc.local to toggle auto-list mode without editing this file.
[[ -o interactive ]] && (( $+functions[_apply_autolist_mode] )) && _apply_autolist_mode

# ── Carapace completions ─────────────────────────────────────────────
# Rich flag/arg completion specs for 1000+ CLI tools (git, docker, kubectl, etc.).
# Must be sourced after compinit (done above via OMZ) so the native menu is
# populated with descriptions before the completion system is first used.
if command -v carapace &>/dev/null; then
    _carapace_cache="$HOME/.zsh/cache/carapace_init.zsh"
    if [[ ! -f "$_carapace_cache" || "$(command -v carapace)" -nt "$_carapace_cache" ]]; then
        carapace _carapace zsh >| "$_carapace_cache"
    fi
    source "$_carapace_cache"
    unset _carapace_cache
fi

# ── Load syntax-highlighting and autosuggestions (order matters) ─────
# syntax-highlighting first, then autosuggestions last so it wraps the
# final widget set. Tab is re-bound after load because autosuggestions
# rebinds widgets on startup and would otherwise steal ^I.
if [[ -r "$_zsh_defer_plugin" ]]; then
    # zsh-defer (by romkatv): source synchronously so the function is available,
    # then defer heavy plugins until after the first prompt renders (~100–150ms saved).
    source "$_zsh_defer_plugin"
    (( _zsh_autosuggest_loaded )) && zsh-defer source "$_zsh_autosuggest_plugin"
    (( _zsh_highlight_loaded )) && zsh-defer source "$_zsh_highlight_plugin"
    # Re-bind keys after deferred plugins settle (autosuggestions rebinds widgets on load).
    [[ -o interactive ]] && zsh-defer -c \
        '(( $+widgets[_tab_accept_or_complete] )) && {
            bindkey -M emacs "^I" _tab_accept_or_complete
            bindkey -M viins "^I" _tab_accept_or_complete
        }
        (( $+widgets[autosuggest-accept] )) && {
            bindkey -M emacs "^ " autosuggest-accept
            bindkey -M viins "^ " autosuggest-accept
        }
        # Re-register paste auto-fix: zsh-autosuggestions overrides bracketed-paste on load.
        (( $+functions[_bracketed_paste_with_autofix] )) && zle -N bracketed-paste _bracketed_paste_with_autofix'
else
    # zsh-defer not available — fall back to synchronous sourcing.
    if (( _zsh_autosuggest_loaded )); then
        source "$_zsh_autosuggest_plugin"
        (( $+functions[_zsh_autosuggest_bind_widgets] )) && _zsh_autosuggest_bind_widgets
    fi
    (( _zsh_highlight_loaded )) && source "$_zsh_highlight_plugin"
    if [[ -o interactive ]] && (( $+widgets[_tab_accept_or_complete] )); then
        bindkey -M emacs '^I' _tab_accept_or_complete
        bindkey -M viins '^I' _tab_accept_or_complete
    fi
    if [[ -o interactive ]] && (( $+widgets[autosuggest-accept] )); then
        bindkey -M emacs '^ ' autosuggest-accept
        bindkey -M viins '^ ' autosuggest-accept
    fi
fi
