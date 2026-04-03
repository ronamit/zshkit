# Kitty Terminal Guide

zshkit treats Kitty as the default terminal and installs a few managed files under `~/.config/kitty/`:

- `kitty.conf` — main terminal behavior and keybindings
- `open-actions.conf` — clickable file hyperlinks open in `micro` instead of a generic file browser
- `quick-access-terminal.conf` — Quake-style drop-down terminal starter config

## General Shortcuts

| Linux | macOS | Action |
|-------|-------|--------|
| `Ctrl+Shift+F2` | `Cmd+,` | Open `kitty.conf` in your editor |
| `Ctrl+Shift+F5` | `Ctrl+Cmd+,` | Reload Kitty config |
| `Ctrl+Shift+F3` | `Ctrl+Shift+F3` | Open Kitty's command palette |
| `Ctrl+Shift+O` | `Ctrl+Shift+O` | Open Kitty's fast file picker |
| `Ctrl+Shift+Alt+O` | `Ctrl+Shift+Alt+O` | Open Kitty's fast directory picker |
| `Ctrl+Shift+Z` | `Ctrl+Shift+Z` | Scroll back to the previous shell prompt |
| `Ctrl+Shift+X` | `Ctrl+Shift+X` | Scroll forward to the next shell prompt |
| `Ctrl+Shift+G` | `Ctrl+Shift+G` | Show the output of the last command in a scrollable overlay |

## Tabs

| Linux | macOS | Action |
|-------|-------|--------|
| `Ctrl+Shift+T` | `Cmd+Shift+T` | New tab in the current working directory |
| `Ctrl+Shift+Q` | `Cmd+W` | Close current tab |
| `Ctrl+Shift+Right` or `Ctrl+Tab` | `Shift+Cmd+]` or `Ctrl+Tab` | Next tab |
| `Ctrl+Shift+Left` or `Ctrl+Shift+Tab` | `Shift+Cmd+[` or `Ctrl+Shift+Tab` | Previous tab |
| `Alt+1` – `Alt+9` | `Alt+1` – `Alt+9` | Jump directly to tab 1–9 |
| `Ctrl+Shift+Alt+T` | `Shift+Cmd+I` | Rename current tab |

On macOS, Kitty's default `Cmd+T` still opens a new tab. zshkit adds `Cmd+Shift+T` specifically for `new_tab_with_cwd`, so the new tab starts in the current working directory.

## Split Screen (Windows)

Kitty calls splits "windows". They live inside a tab and are arranged by the active layout.

| Linux | macOS | Action |
|-------|-------|--------|
| `Ctrl+Shift+Enter` | `Cmd+Enter` | New window (split) using the current layout |
| `Ctrl+Shift+W` | `Shift+Cmd+D` | Close the focused window |
| `Ctrl+Shift+]` | `Ctrl+Shift+]` | Next window |
| `Ctrl+Shift+[` | `Ctrl+Shift+[` | Previous window |
| `Ctrl+Shift+F7` | `Ctrl+Shift+F7` | Show window overlays and focus a pane visually |
| `Ctrl+Shift+F8` | `Ctrl+Shift+F8` | Swap the current pane with another pane visually |
| `Ctrl+Shift+R` | `Cmd+R` | Start resizing the focused window with arrow keys |
| `Ctrl+Shift+L` | `Ctrl+Shift+L` | Cycle through layouts |

The visual window actions are keyboard-driven overlays, not drag-and-drop. Use `F7` to jump to a pane and `F8` to swap the current pane with another one.

### Layouts

Press `Ctrl+Shift+L` to cycle through:

| Layout | Description |
|--------|-------------|
| `tall` | One wide pane on the left, stack of narrow panes on the right |
| `fat` | One tall pane on top, row of short panes below |
| `grid` | Evenly spaced grid |
| `splits` | Free-form split tree where you place panes with `launch --location=...` |
| `horizontal` | Side-by-side panes |
| `vertical` | Stacked panes |
| `stack` | One maximized pane at a time (switch with `]` / `[`) |

For exact left/right/top/bottom placement instead of cycling preset layouts, use the `splits` layout in a session file and place windows with `launch --location=...`.

To jump directly to a layout add to `kitty.conf`:

```conf
map ctrl+shift+alt+t goto_layout tall
map ctrl+shift+alt+g goto_layout grid
map ctrl+shift+alt+s goto_layout stack
```

### Practical split workflow

| Step | Linux | macOS | What it does |
|------|-------|-------|--------------|
| 1 | `Ctrl+Shift+Enter` | `Cmd+Enter` | Split the current tab and create a second pane |
| 2 | `Ctrl+Shift+Enter` | `Cmd+Enter` | Split again so you have three panes to arrange |
| 3 | `Ctrl+Shift+L` | `Ctrl+Shift+L` | Cycle layouts until the overall arrangement looks right |
| 4 | `Ctrl+Shift+R` | `Cmd+R` | Enter resize mode, then use arrow keys and press `Enter` to confirm |
| 5 | `Ctrl+Shift+F7` | `Ctrl+Shift+F7` | Jump directly to the pane you want to focus |
| 6 | `Ctrl+Shift+F8` | `Ctrl+Shift+F8` | Swap the current pane with another pane |
| 7 | `Ctrl+Shift+]` / `Ctrl+Shift+[` | `Ctrl+Shift+]` / `Ctrl+Shift+[` | Step forward or backward between panes |

## Hints (Path / URL selection)

| Linux | macOS | Action |
|-------|-------|--------|
| `Ctrl+Shift+P`, then `f` | `Ctrl+Shift+P`, then `f` | Hint-select a visible path and paste it into the prompt |
| `Ctrl+Shift+P`, then `n` | `Ctrl+Shift+P`, then `n` | Hint-select a visible `file:line` reference and open it |
| `Ctrl+Shift+P`, then `h` | `Ctrl+Shift+P`, then `h` | Hint-select a visible hash and paste it into the prompt |
| `Ctrl+Shift+P`, then `l` | `Ctrl+Shift+P`, then `l` | Hint-select a visible line and paste it into the prompt |
| `Ctrl+Shift+P`, then `u` | `Ctrl+Shift+P`, then `u` | Hint-select a visible URL and open it in the browser |

### Opening URLs inside Zellij

Zellij captures all mouse events, so Kitty's normal `Ctrl+click` on a URL does not reach Kitty when a Zellij session is running. Two ways to open links:

| Method | How |
|--------|-----|
| Hint picker | `Ctrl+Shift+P`, then `u` — overlays letter hints on every URL; press the hint letters to open |
| Bypass Zellij | `Ctrl+Shift+click` — forces Kitty to handle the click, bypassing Zellij's mouse capture |

## Session Files — Fixed Daily Layout

To open a fixed set of tabs automatically (e.g. your daily SSH layout), create `~/.config/kitty/sessions/work.conf`:

```conf
new_tab work
launch ssh myserver -t "zellij attach -c -s work"

new_tab infra
launch ssh myserver -t "zellij attach -c -s infra"
```

To open a split-aware layout inside a session file, use Kitty's session directives such as `layout`, `cd`, and `launch`:

```conf
new_tab dev
cd /my/project
layout tall
launch --title "Editor" vim src/main.py
launch --title "Shell"
launch --title "Docs" less README.md
```

For explicit pane placement, use the `splits` layout and `launch --location=...`:

```conf
new_tab triage
cd /my/project
layout splits
launch --title "Main shell"
launch --location=vsplit --title "Editor" vim src/main.py
launch --location=hsplit --bias=40 --title "Docs" less README.md
launch --location=hsplit --title "Scratch shell"
```

Replace the sample commands with the editor, test runner, or SSH command you actually use.

Open it with `kitty --session ~/.config/kitty/sessions/work.conf`, or add an alias in `~/.zshrc.local`:

```bash
alias work='kitty --session ~/.config/kitty/sessions/work.conf'
```

Kitty session files let you reopen a known workspace on demand. They are different from automatic crash/restart restore: they recreate the tabs, layouts, and launch commands you define in the session file.

## Quick-Access Terminal (Quake-style drop-down)

- `kqa` — launch from the shell; quickest way to try it
- On Linux: bind your desktop/WM shortcut to `kitten quick-access-terminal --detach`
- On macOS: run `kqa` once, then assign the built-in Kitty Quick Access service a shortcut in System Settings
- Tweak `~/.config/kitty/quick-access-terminal.conf` to change height, edge, or opacity

## Shell Helpers That Pair Well with Kitty

- `rg` emits Kitty hyperlinks, so file results from ripgrep are clickable
- `hg` runs Kitty's hyperlinked grep kitten for richer interactive grep output
- `clipcopy` / `clippaste` use Kitty's clipboard kitten, which is handy over SSH
- `icat image.png` previews an image inline in the terminal
- `kqa` launches Kitty's quick-access terminal using the managed starter config
