# Ghostty Terminal Guide

zshkit treats Ghostty as the default terminal and installs a starter config at `~/.config/ghostty/config`.

## Installation

**macOS:**

```bash
brew install --cask ghostty
```

**Ubuntu / Linux:**

```bash
snap install ghostty --classic
```

Alternative (community `.deb` for Ubuntu): `bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"`

## Config

Config file: `~/.config/ghostty/config`

Reload at runtime with `Ctrl+Shift+,` (Linux) or `Cmd+Shift+,` (macOS). Some options only take effect for new windows.

zshkit's starter config unbinds `Ctrl+Enter` from Ghostty's default fullscreen toggle to avoid accidental fullscreen switches while working in shells, editors, or TUIs.

```bash
ghostty +list-themes               # browse all built-in themes (100+)
ghostty +list-fonts                # list available fonts
ghostty +list-keybinds --default   # show all default shortcuts
ghostty +validate-config           # check config for errors
```

### Changing the theme

Set `theme = <name>` in your config using the exact name from `ghostty +list-themes`. Some popular ones:

| Theme | Style |
|-------|-------|
| `Catppuccin Mocha` | Dark, muted purple (default) |
| `Catppuccin Macchiato` | Dark, slightly warmer |
| `Catppuccin Latte` | Light |
| `Tokyo Night` | Dark blue |
| `Dracula` | Dark purple |
| `nord` | Dark arctic blue |
| `Gruvbox dark` | Dark warm |
| `One Dark` | Dark |

You can also set separate light/dark themes: `theme = light:GitHub Light,dark:Catppuccin Mocha`

## Tabs

| Linux | macOS | Action |
|-------|-------|--------|
| `Ctrl+Shift+T` | `Cmd+T` | New tab |
| `Ctrl+Shift+W` | `Cmd+W` | Close tab (or split) |
| `Ctrl+Tab` | `Ctrl+Tab` | Next tab |
| `Ctrl+Shift+Tab` | `Ctrl+Shift+Tab` | Previous tab |
| `Alt+1` – `Alt+8` | `Cmd+1` – `Cmd+8` | Jump to tab 1–8 |

## Splits

Ghostty calls splits "surfaces". They live inside a tab.

| Linux | macOS | Action |
|-------|-------|--------|
| `Ctrl+Shift+O` | `Cmd+D` | New split — right |
| `Ctrl+Shift+E` | `Cmd+Shift+D` | New split — down |
| `Ctrl+Alt+Arrow` | `Cmd+Alt+Arrow` | Move focus to adjacent split |
| `Ctrl+Shift+W` | `Cmd+W` | Close focused split |

## Search

| Linux | macOS | Action |
|-------|-------|--------|
| `Ctrl+Shift+F` | `Cmd+F` | Start search |
| `Enter` | `Enter` | Next match |
| `Shift+Enter` | `Shift+Enter` | Previous match |
| `Escape` | `Escape` | Close search |

## Copy & Paste

| Linux | macOS | Action |
|-------|-------|--------|
| `Ctrl+Shift+C` | `Cmd+C` | Copy |
| `Ctrl+Shift+V` | `Cmd+V` | Paste |
| `Shift+Insert` | — | Paste from selection |

> **Inside a Zellij session:** `Ctrl+Shift+C` is intercepted by Zellij in some modes. To copy:
>
> - **Mouse selection** — zshkit uses `copy_on_select true` by default, so selecting text copies it automatically.
> Or open the scrollback in text editor and copy from there - see [USAGE_GUIDE.md](USAGE_GUIDE.md#scrollback-in-editor) for more details.
>
> `Ctrl+Shift+V` (paste) passes through to the terminal and works normally.

## Scrolling

| Linux | macOS | Action |
|-------|-------|--------|
| `Shift+Page Up` | `Shift+Page Up` | Scroll page up |
| `Shift+Page Down` | `Shift+Page Down` | Scroll page down |
| `Shift+Home` | `Shift+Home` | Scroll to top |
| `Shift+End` | `Shift+End` | Scroll to bottom |
| `Ctrl+Shift+Page Up` | `Ctrl+Shift+Page Up` | Jump to previous shell prompt |
| `Ctrl+Shift+Page Down` | `Ctrl+Shift+Page Down` | Jump to next shell prompt |

Jump-to-prompt requires `shell-integration = detect` in your config (set by zshkit).

## Font Size

| Linux | macOS | Action |
|-------|-------|--------|
| `Ctrl+=` | `Cmd+=` | Increase font size |
| `Ctrl+-` | `Cmd+-` | Decrease font size |
| `Ctrl+0` | `Cmd+0` | Reset font size |

## Window & Config

| Linux | macOS | Action |
|-------|-------|--------|
| `Ctrl+Shift+N` | `Cmd+N` | New window |
| `Ctrl+,` | `Cmd+,` | Open config file |
| `Ctrl+Shift+,` | `Cmd+Shift+,` | Reload config |

`Ctrl+Enter` is intentionally unbound by zshkit's starter config. Remove `keybind = ctrl+enter=unbind` from `~/.config/ghostty/config` if you want Ghostty's default fullscreen shortcut back.
