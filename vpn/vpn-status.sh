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

echo "=== VPN Status ==="
echo ""

vpn_cleanup_dead_screens
vpn_cleanup_stale_pid

if vpn_pid_is_running; then
    VPN_PID="$(cat "$VPN_PID_FILE" 2>/dev/null)"
    echo "Status: ✓ CONNECTED"
    echo "PID: $VPN_PID"

    if vpn_screen_session_exists; then
        echo "Screen: $VPN_SCREEN_NAME (view with: sudo screen -r $VPN_SCREEN_NAME)"
    fi

    echo ""
    vpn_print_interface_info
    echo ""
    echo "Last 10 log lines:"
    echo "-------------------"
    if [[ -f "$VPN_LOG_FILE" ]]; then
        sudo tail -n 10 "$VPN_LOG_FILE"
    else
        echo "Log file not found at $VPN_LOG_FILE"
    fi
else
    echo "Status: ✗ DISCONNECTED"
fi
