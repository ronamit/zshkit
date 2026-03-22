#!/usr/bin/env bash

set -uo pipefail

VPN_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VPN_OS="$(uname -s)"

if [[ "$VPN_OS" == "Darwin" ]]; then
    VPN_MANAGED_DIR_DEFAULT="$HOME/Library/Application Support/zshkit/vpn"
    VPN_STATE_DIR_DEFAULT="$VPN_MANAGED_DIR_DEFAULT/state"
else
    VPN_MANAGED_DIR_DEFAULT="${XDG_DATA_HOME:-$HOME/.local/share}/zshkit/vpn"
    VPN_STATE_DIR_DEFAULT="${XDG_STATE_HOME:-$HOME/.local/state}/zshkit/vpn"
fi

VPN_MANAGED_DIR="${ZSHKIT_VPN_DIR:-$VPN_MANAGED_DIR_DEFAULT}"
VPN_STATE_DIR="${ZSHKIT_VPN_STATE_DIR:-$VPN_STATE_DIR_DEFAULT}"
VPN_CREDENTIALS_FILE="${ZSHKIT_VPN_CREDENTIALS_FILE:-$VPN_MANAGED_DIR/vpn-credentials.txt}"
VPN_CREDENTIALS_TEMPLATE="${VPN_MANAGED_DIR}/vpn-credentials.txt.template"
VPN_CONFIG_FILE="${ZSHKIT_VPN_CONFIG_FILE:-$HOME/client.ovpn}"
VPN_LOG_FILE="${VPN_STATE_DIR}/vpn-connection.log"
VPN_PID_FILE="${VPN_STATE_DIR}/vpn.pid"
VPN_SCREEN_NAME="${ZSHKIT_VPN_SCREEN_NAME:-zshkit-openvpn}"
VPN_TEMP_CREDS="${VPN_STATE_DIR}/.vpn-temp-creds.txt"
VPN_CONNECT_HELPER="${VPN_STATE_DIR}/.vpn-connect-helper.sh"

vpn_prepare_state_dir() {
    mkdir -p "$VPN_STATE_DIR" || {
        echo "vpn: failed to create state directory: $VPN_STATE_DIR"
        return 1
    }
    chmod 700 "$VPN_STATE_DIR" 2>/dev/null || true
}

vpn_print_setup_message() {
    local command_name="${1:-vpn}"
    echo "$command_name is not fully configured yet."
    echo "  Managed VPN directory: $VPN_MANAGED_DIR"
    echo "  Credentials file: $VPN_CREDENTIALS_FILE"
    if [[ -f "$VPN_CREDENTIALS_TEMPLATE" ]]; then
        echo "  Credentials template: $VPN_CREDENTIALS_TEMPLATE"
    fi
    echo "  OpenVPN config file: $VPN_CONFIG_FILE"
    echo ""
    echo "What to do:"
    echo "  1. Edit the credentials file and replace the placeholder username/password."
    echo "  2. Make sure your OpenVPN config exists at the path above."
    echo "  3. If your config lives elsewhere, add this to ~/.zshrc.local and reload:"
    echo "       export ZSHKIT_VPN_CONFIG_FILE=\"/path/to/client.ovpn\""
}

vpn_require_commands() {
    local missing=()
    local cmd
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if ((${#missing[@]} > 0)); then
        echo "vpn: missing required command(s): ${missing[*]}"
        echo "Re-run setup_zsh.sh to install the managed VPN dependencies."
        return 1
    fi
}

vpn_load_credentials() {
    if [[ ! -f "$VPN_CREDENTIALS_FILE" ]]; then
        vpn_print_setup_message "vpn-connect"
        return 1
    fi

    local -a entries=()
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "${line//[[:space:]]/}" ]] && continue
        [[ "$line" == \#* ]] && continue
        entries+=("$line")
    done < "$VPN_CREDENTIALS_FILE"

    if ((${#entries[@]} < 2)); then
        echo "vpn-connect: credentials file is incomplete: $VPN_CREDENTIALS_FILE"
        vpn_print_setup_message "vpn-connect"
        return 1
    fi

    VPN_USERNAME="${entries[0]}"
    VPN_PASSWORD="${entries[1]}"

    if [[ "$VPN_USERNAME" == "your_username" || "$VPN_PASSWORD" == "your_password" ]]; then
        echo "vpn-connect: credentials file still has placeholder values."
        vpn_print_setup_message "vpn-connect"
        return 1
    fi
}

vpn_cleanup_dead_screens() {
    command -v screen >/dev/null 2>&1 || return 0
    sudo screen -wipe >/dev/null 2>&1 || true
}

vpn_screen_session_exists() {
    command -v screen >/dev/null 2>&1 || return 1
    sudo screen -list 2>/dev/null | grep -q "$VPN_SCREEN_NAME"
}

vpn_pid_is_running() {
    [[ -f "$VPN_PID_FILE" ]] || return 1
    local pid
    pid="$(cat "$VPN_PID_FILE" 2>/dev/null)" || return 1
    [[ -n "$pid" ]] || return 1
    sudo kill -0 "$pid" 2>/dev/null
}

vpn_cleanup_stale_pid() {
    if [[ -f "$VPN_PID_FILE" ]] && ! vpn_pid_is_running; then
        sudo rm -f "$VPN_PID_FILE" 2>/dev/null || rm -f "$VPN_PID_FILE"
    fi
}

vpn_print_interface_info() {
    if [[ "$VPN_OS" == "Darwin" ]]; then
        if ! command -v ifconfig >/dev/null 2>&1; then
            return 0
        fi
        local found=0
        while IFS=: read -r iface ip; do
            [[ -z "$iface" || -z "$ip" ]] && continue
            if (( ! found )); then
                echo "VPN Interfaces:"
            fi
            echo "  $iface: $ip"
            found=1
        done < <(ifconfig 2>/dev/null | awk '
            /^[a-zA-Z0-9]/ {
                iface=$1
                sub(":$", "", iface)
                next
            }
            /^[[:space:]]+inet / && iface ~ /^(utun|tun)/ {
                print iface ":" $2
            }
        ')
    else
        if command -v ip >/dev/null 2>&1 && ip addr show tun0 >/dev/null 2>&1; then
            echo "VPN Interface: tun0"
            ip addr show tun0 | awk '/inet / {print "  IP: " $2}'
        fi
    fi
}
