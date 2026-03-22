#!/usr/bin/env bash

set -uo pipefail

# ~/.local/bin/vpn-connect is a symlink; BASH_SOURCE would otherwise be ~/.local/bin.
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
vpn_require_commands screen openvpn sudo || exit 1
vpn_load_credentials || exit 1

if [[ ! -f "$VPN_CONFIG_FILE" ]]; then
    echo "vpn-connect: OpenVPN config not found at $VPN_CONFIG_FILE"
    vpn_print_setup_message "vpn-connect"
    exit 1
fi

bash "$SCRIPT_DIR/vpn-disconnect.sh" >/dev/null 2>&1 || true

vpn_cleanup_dead_screens
vpn_cleanup_stale_pid

if vpn_pid_is_running || vpn_screen_session_exists; then
    echo "VPN is already running."
    echo "  Status: vpn-status"
    echo "  Disconnect: vpn-disconnect"
    exit 1
fi

echo "Enter your 2FA Authenticator Code (leave blank if not required):"
read -r AUTH_CODE

cat > "$VPN_TEMP_CREDS" <<EOF
$VPN_USERNAME
$VPN_PASSWORD
EOF
chmod 600 "$VPN_TEMP_CREDS"

cat > "$VPN_CONNECT_HELPER" <<EOF
#!/usr/bin/env bash
set -uo pipefail
openvpn --config "$VPN_CONFIG_FILE" --auth-user-pass "$VPN_TEMP_CREDS" --auth-retry nointeract --log "$VPN_LOG_FILE" --writepid "$VPN_PID_FILE"
EOF
chmod 700 "$VPN_CONNECT_HELPER"

echo ""
echo "Connecting to VPN..."
echo "OpenVPN will run in a detached screen session."
echo ""
echo "To view the session: sudo screen -r $VPN_SCREEN_NAME"
echo "To detach from session: Press Ctrl+A then D"
echo ""

sudo screen -dmS "$VPN_SCREEN_NAME" bash "$VPN_CONNECT_HELPER"
sleep 3

if [[ -n "$AUTH_CODE" ]]; then
    sudo screen -S "$VPN_SCREEN_NAME" -X stuff "$AUTH_CODE\n"
fi

sleep 1
rm -f "$VPN_CONNECT_HELPER" "$VPN_TEMP_CREDS"

echo "Waiting for connection to establish..."
sleep 5

if vpn_pid_is_running; then
    VPN_PID="$(cat "$VPN_PID_FILE" 2>/dev/null)"
    echo ""
    echo "✓ VPN connected successfully!"
    echo "  PID: $VPN_PID"
    echo "  Screen session: $VPN_SCREEN_NAME"
    echo ""
    echo "Commands:"
    echo "  Status: vpn-status"
    echo "  View live: sudo screen -r $VPN_SCREEN_NAME (Ctrl+A D to detach)"
    echo "  Disconnect: vpn-disconnect"
    echo ""
    echo "✓ You can now close this terminal. VPN will keep running."
    exit 0
fi

echo ""
echo "✗ Connection may have failed. Recent log output:"
sudo tail -20 "$VPN_LOG_FILE" 2>/dev/null || echo "No log file found at $VPN_LOG_FILE"
echo ""
echo "To see live output: sudo screen -r $VPN_SCREEN_NAME"
exit 1
