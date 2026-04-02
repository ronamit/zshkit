#!/bin/bash
# zjss-wrapper.sh — SSH helper for zjss() Zellij layouts.
# Installed to ~/.local/bin/zjss-wrapper by setup_zsh.sh.
# Args: $1=host $2=remote-command
_host="$1"
_cmd="$2"
if ! ssh -o ConnectTimeout=5 -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -t "$_host" "$_cmd"; then
    # Use \r\n to ensure clean formatting even if the PTY was left in raw mode
    echo -e "\r\n\r\n--- SSH FAILED (Exit code $?) ---"
    echo -e "Command: ssh -t $_host \"$_cmd\"\r\n"
    echo -e "Holding pane open for 60 seconds so you can read the error...\r\n"
    sleep 60
fi
