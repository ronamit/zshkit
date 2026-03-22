#!/bin/bash
# Clear Cursor editor cache on Linux/Ubuntu.
# Close Cursor before running this script.

CURSOR_DIR="$HOME/.config/Cursor"

if [ ! -d "$CURSOR_DIR" ]; then
    echo "Cursor config directory not found at $CURSOR_DIR"
    exit 1
fi

# Warn if Cursor appears to be running
if pgrep -f "[C]ursor" &>/dev/null; then
    echo "⚠ Cursor appears to be running. Close it first, then re-run this script."
    exit 1
fi

rm -rf "$CURSOR_DIR"/{Cache,CachedData,CachedExtensionVSIXs,GPUCache,Code\ Cache,Service\ Worker,DawnGraphiteCache,DawnWebGPUCache,logs,WebStorage} 2>/dev/null
rm -f "$CURSOR_DIR/User/globalStorage/state.vscdb"* 2>/dev/null
rm -rf "$CURSOR_DIR/User/workspaceStorage" 2>/dev/null
rm -rf "$CURSOR_DIR/User/History" 2>/dev/null

echo "✓ Cursor cache cleared. You can restart Cursor."
