# Cursor slow? Clear the cache

When Cursor feels slow, clear its cache. **Close Cursor completely before running these commands.**

## Ubuntu / Linux

One-liner:

```bash
rm -rf ~/.config/Cursor/{Cache,CachedData,CachedExtensionVSIXs,GPUCache,Code\ Cache,Service\ Worker,DawnGraphiteCache,DawnWebGPUCache,logs,WebStorage} && \
rm -f ~/.config/Cursor/User/globalStorage/state.vscdb* && \
rm -rf ~/.config/Cursor/User/workspaceStorage && \
rm -rf ~/.config/Cursor/User/History
```

Or run the script in this folder:

```bash
./clear-cursor-cache.sh
```

## What gets removed

| Path | What it is |
|------|------------|
| Cache, CachedData, etc. | App and GPU caches, logs |
| `User/globalStorage/state.vscdb*` | Global state DB |
| `User/workspaceStorage` | Per-workspace state (some workspace settings may reset) |
| `User/History` | Local file edit history (your files are untouched) |

## After clearing

Restart Cursor. It will recreate caches as needed. Your projects and settings (except per-workspace and local history) stay intact.

## macOS (for reference)

```bash
rm -rf ~/Library/Application\ Support/Cursor/{Cache,CachedData,CachedExtensionVSIXs,GPUCache,Code\ Cache,Service\ Worker,DawnGraphiteCache,DawnWebGPUCache,logs,WebStorage} && \
rm -f ~/Library/Application\ Support/Cursor/User/globalStorage/state.vscdb* && \
rm -rf ~/Library/Application\ Support/Cursor/User/workspaceStorage && \
rm -rf ~/Library/Application\ Support/Cursor/User/History
```
