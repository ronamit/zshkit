#!/usr/bin/env bash

set -uo pipefail

_script="${BASH_SOURCE[0]}"
while [[ -L "$_script" || -h "$_script" ]]; do
    _dir="$(cd -P "$(dirname -- "$_script")" && pwd)"
    _link="$(readlink "$_script")"
    if [[ "$_link" != /* ]]; then
        _script="$_dir/$_link"
    else
        _script="$_link"
    fi
done
SCRIPT_DIR="$(cd -P "$(dirname -- "$_script")" && pwd)"
unset -v _script _dir _link
# shellcheck disable=SC1091
source "$SCRIPT_DIR/vpn-common.sh"

vpn_prepare_state_dir || exit 1

echo "Disconnecting from VPN..."

vpn_cleanup_dead_screens

if vpn_screen_session_exists; then
    sudo screen -S "$VPN_SCREEN_NAME" -X quit 2>/dev/null
    echo "  Closed screen session"
fi

vpn_cleanup_dead_screens

if [[ -f "$VPN_PID_FILE" ]]; then
    VPN_PID="$(cat "$VPN_PID_FILE" 2>/dev/null)"
    if [[ -n "${VPN_PID:-}" ]] && sudo kill "$VPN_PID" 2>/dev/null; then
        sleep 1
        if sudo kill -0 "$VPN_PID" 2>/dev/null; then
            sudo kill -9 "$VPN_PID" 2>/dev/null
        fi
    fi
    sudo rm -f "$VPN_PID_FILE" 2>/dev/null || rm -f "$VPN_PID_FILE"
fi

rm -f "$VPN_TEMP_CREDS" "$VPN_CONNECT_HELPER"

echo "✓ VPN disconnected"
