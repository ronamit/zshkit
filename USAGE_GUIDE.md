# Usage Guide

Daily guide for how this shell setup behaves once installed: shortcuts, helper commands, keybindings, and common workflows. For install flow, setup script behavior, troubleshooting, and rollback, use [SETUP_DETAILS.md](SETUP_DETAILS.md).

## See What Is Active

```bash
# List aliases
alias

# List custom functions from this config
functions | rg '^(ff|ftext|ports|f|mkcd|zj|zjclean|ducks|gbr|branch_bye|pr|sshv|ssh-fix-colors|vpn-connect|vpn-disconnect|vpn-status|vm|_venv_auto_activate)\b'

# Show active key bindings
bindkey | less
```

## Command Entry and Editing

Behavior summary:

**Autosuggestions** appear as ghost text as you type. The strategy tries `match_prev_cmd` first (prefers history that followed the same previous command), then plain `history`, then falls back to the `completion` engine for files and commands not yet in history. Dangerous commands (`rm -rf *`, `sudo rm *`, fork bombs) are excluded from suggestions.

**History search:** press `↑` to find older commands that start with what you've typed so far. Keep pressing `↑` to go further back; once in history search mode, `↓` moves forward to newer matches.

**Directory completion:** in a `cd` context, press `↓` to open a browsable menu of matching subdirectories — navigate with arrow keys, `Enter` to select. `fzf-tab` powers fuzzy completion for most other commands. Completion menus are grouped by type with descriptions, and matching is case-insensitive. Auto-`cd` is enabled — type a directory name and press `Enter` to enter it.

| Key | Action |
|-----|--------|
| `Tab` | Accept the full autosuggestion if one is showing (if the accepted path is a directory, automatically appends `/` and opens its contents). Otherwise open completion. |
| `Shift+Tab` | Reverse completion / previous menu item |
| `→` (Right Arrow) | Partial-accept one character from the autosuggestion |
| `Ctrl+→` / `Alt+F` | Partial-accept one word from the autosuggestion |
| `Ctrl+Space` | Accept full autosuggestion |
| `End` | Accept full autosuggestion (move to end of line) |
| `Up` | History search: search older commands that start with what you've typed so far |
| `Down` | **In `cd` / path context:** open a browsable directory completion menu. **After pressing `Up` (history scroll active):** go to the newer history match. |
| `Ctrl+P` | Same as `Up` |
| `Ctrl+N` | Same as `Down` |
| `Ctrl+Z` | Undo last command-line edit |

### Inside The Completion Menu

| Key | Action |
|-----|--------|
| `Up` / `Down` | Move through menu items and between rows |
| `Tab` / `Shift+Tab` | Next / previous item |
| `Enter` | Accept the current selection and run |
| `Left` / `Right` | Move between columns in grid-style menus |
| `Escape` | Cancel the menu and return to editing |

## FZF Keys

| Key | Action |
|-----|--------|
| `Ctrl+R` | Fuzzy search shell history |
| `Ctrl+T` | Fuzzy insert file path |
| `Alt+C` | Fuzzy change directory |

FZF is configured to use `fd` / `fdfind`, include hidden files, and ignore `.git`.

## Shell and Navigation Shortcuts

| Shortcut | Expands to / Does |
|----------|-------------------|
| `cls` | `clear` |
| `..` / `...` / `....` | Jump up 1 / 2 / 3 directories |
| `z PATTERN` | Jump to a frequently visited directory matching the pattern (uses [zoxide](https://github.com/ajeetdsouza/zoxide) when installed, otherwise the [z plugin](https://github.com/agkozak/zsh-z)) |
| `zi` | Interactive directory picker (`zoxide` + `fzf`; requires zoxide) |
| `yazi [PATH]` | Open the `yazi` terminal file manager in the current directory or a chosen path |
| `ls` | Uses `lsd` when installed, otherwise system `ls` |
| `l` | `lsd -l` when available, otherwise `ls -lFh` |
| `la` | `lsd -la` when available, otherwise `ls -lAFh` |
| `ll` | `lsd -lah` when available, otherwise `ls -lAh` |
| `lt` | `tree -L 2` |
| `ldot` | `ls -ld .*` |
| `cat` | Uses `bat` / `batcat` plain mode when available |
| `catt` | Full `bat` / `batcat` view |
| `cp` / `mv` | Interactive copy / move (`-iv`) |
| `rm` | Safer remove (`rm -I`) |
| `mkdir` | Verbose parent-create (`mkdir -pv`) |
| `grep` | Colorized grep |
| `rg PATTERN [PATH]` | Ripgrep with Kitty hyperlinks enabled so file results are clickable in Kitty |
| `h` | `history` |
| `path` | Print one `PATH` entry per line |
| `myip` | Public IP (`curl ifconfig.me`) |
| `localip` | First local IP |
| `clipcopy` | Copy stdin to the system clipboard using Kitty's clipboard kitten |
| `clippaste` | Print current clipboard contents using Kitty's clipboard kitten |
| `hg` | Run Kitty's hyperlinked grep kitten |
| `icat [PATH]` | Preview images inline in Kitty |
| `kqa` | Launch Kitty's quick-access terminal (`kitten quick-access-terminal --detach`) |
| `sshv HOST [ARGS...]` | SSH with `ConnectTimeout=10`, terminal input reset, and a VPN hint on failure |
| `vpn-connect` | Start or reconnect the managed VPN session |
| `vpn-disconnect` | Disconnect the managed VPN session |
| `vpn-status` | Show VPN process, interface, and recent log status |
| `nvtop` | Interactive GPU process monitor (like `htop` for GPUs) |
| `jq FILTER [FILE]` | Process and pretty-print JSON (`jq .` to pretty-print, `jq '.key'` to extract) |
| `gh` | GitHub CLI — create PRs, view issues, watch CI runs (`gh pr create`, `gh run view`) |
| `reload` | Reload `~/.zshrc` |
| `f` | Open current directory in the system file manager |
| `mkcd NAME` | Create a directory and enter it |
| `ff PATTERN` | Find files by name |
| `ftext PATTERN` | Search text (`rg` preferred) |
| `ports` | Show listening ports and processes |
| `ducks` | Show top-level sizes for entries in the current directory |
| `ncdu [PATH]` | Open the interactive `ncdu` directory-size browser for a path |
| `micro [FILE]` | Open the `micro` terminal editor for quick edits |
| `c` | Open `cursor` or `code` if installed |

Practical notes:

- `z` and `zi` are best when you already know roughly where you want to go and want to jump there quickly.
- `yazi` is the better fit when you want to browse files and directories interactively inside the terminal instead of jumping straight to a known location.
- `ducks` gives a fast top-level size summary for the current directory; `ncdu` is the better choice when you want to drill down through a directory tree and find what is using space.
- `micro` is configured as the Zellij scrollback editor (the editor that opens when you press `e` in scroll mode). To also use it as your shell `$EDITOR`, add `export EDITOR=micro` to `~/.zshrc.local`.

## Kitty

zshkit treats Kitty as the default terminal and installs a few managed files under `~/.config/kitty/`:

- `kitty.conf` for the main terminal behavior and keybindings
- `open-actions.conf` so clickable file hyperlinks open in `micro` instead of a generic file browser
- `quick-access-terminal.conf` for a Quake-style drop-down terminal starter config

Inside Kitty:

| Key | Action |
|-----|--------|
| `Ctrl+Shift+F2` | Open `kitty.conf` in your editor |
| `Ctrl+Shift+F5` | Reload Kitty config |
| `Ctrl+Shift+F3` | Open Kitty's command palette |
| `Ctrl+Shift+T` / `Cmd+Shift+T` | Open a new tab in the current working directory |
| `Ctrl+Shift+O` | Open Kitty's fast file picker |
| `Ctrl+Shift+Alt+O` | Open Kitty's fast directory picker |
| `Ctrl+Shift+Z` | Scroll back to the previous shell prompt |
| `Ctrl+Shift+X` | Scroll forward to the next shell prompt |
| `Ctrl+Shift+G` | Show the output of the last command in a scrollable overlay |
| `Alt+1` – `Alt+9` | Jump directly to tab 1–9 |
| `Ctrl+Shift+P`, then `f` | Hint-select a visible path and paste it into the prompt |
| `Ctrl+Shift+P`, then `n` | Hint-select a visible `file:line` reference and open it |
| `Ctrl+Shift+P`, then `h` | Hint-select a visible hash and paste it into the prompt |
| `Ctrl+Shift+P`, then `l` | Hint-select a visible line and paste it into the prompt |
| `Ctrl+Shift+P`, then `u` | Hint-select a visible URL and open it in the browser |

### Opening URLs inside Zellij

Zellij captures all mouse events, so Kitty's normal `Ctrl+click` on a URL does not reach Kitty when a Zellij session is running. Three ways to open links:

| Method | How |
|--------|-----|
| Hint picker | `Ctrl+Shift+P`, then `u` — overlays letter hints on every URL in the visible screen; press the hint letters to open |
| Bypass Zellij | `Ctrl+Shift+click` — forces Kitty to handle the click directly, bypassing Zellij's mouse capture |
| Outside Zellij | `Ctrl+click` works normally when Zellij is not running |

### Session restore

Kitty saves the current tab layout and working directories on exit and restores them on next launch (`restore_session after_restart` in `kitty.conf`). Tab titles and CWDs are preserved; scrollback content is not.

Shell helpers that pair well with Kitty:

- `rg` emits Kitty hyperlinks, so file results from ripgrep are clickable
- `hg` runs Kitty's hyperlinked grep kitten for richer interactive grep output
- `clipcopy` / `clippaste` use Kitty's clipboard kitten, which is handy over SSH
- `icat image.png` previews an image inline in the terminal
- `kqa` launches Kitty's quick-access terminal using the managed starter config

### Kitty session files — fixed daily layout

To open a fixed set of tabs automatically (e.g. your daily SSH layout), create `~/.config/kitty/sessions/work.conf`:

```conf
new_tab work
launch ssh myserver -t "zellij attach -c -s work"

new_tab infra
launch ssh myserver -t "zellij attach -c -s infra"
```

Open it with `kitty --session ~/.config/kitty/sessions/work.conf`, or add an alias in `~/.zshrc.local`:

```bash
alias work='kitty --session ~/.config/kitty/sessions/work.conf'
```

Quick-access terminal notes:

- `kqa` is the easiest way to try it immediately
- on Linux, bind your desktop/window-manager shortcut to `kitten quick-access-terminal --detach`
- on macOS, first run `kqa` once, then assign the built-in Kitty Quick access service a shortcut in System Settings
- tweak `~/.config/kitty/quick-access-terminal.conf` if you want a different height, edge, or opacity

## Disk Usage

```bash
ducks           # top-level sizes in the current directory (fast overview)
ncdu            # interactive drill-down browser for the current directory
ncdu /          # drill down from root to find what's using space
ncdu ~/         # same, starting from home
```

`ducks` is a quick `du` one-liner — good for a fast answer. `ncdu` lets you navigate into subdirectories interactively and delete entries in place.

## Git Shortcuts

Oh My Zsh `git` plugin is enabled, along with the helpers below.

### Custom helpers

| Shortcut | Does |
|----------|------|
| `glog` | `git log --oneline --decorate --graph` |
| `glp` | Pretty graph log with relative date and author |
| `cdg` | `cd` to repo root (or stay if not in a repo) |
| `lg` | Open `lazygit` TUI when installed |
| `gbr` | Fuzzy branch switcher |
| `branch_bye` | Switch to main/default branch and delete the current branch |
| `pr` | Open GitHub PR or GitLab MR page for the current branch |

### Common git aliases

| Shortcut | Expands to |
|----------|------------|
| `g` | `git` |
| `gst` | `git status` |
| `ga` / `gaa` | `git add` / `git add --all` |
| `gcmsg "msg"` | `git commit --message "msg"` |
| `gco` / `gcb` | `git checkout` / `git checkout -b` |
| `gsw` / `gswc` | `git switch` / `git switch --create` |
| `gcm` | `git checkout $(git_main_branch)` |
| `gd` / `gds` | `git diff` / `git diff --staged` |
| `gb` / `gba` / `gbd` | Local branches / all branches / delete branch |
| `glo` / `gloga` | One-line log / graph one-line log (all branches) |
| `gl` / `gpr` | `git pull` / `git pull --rebase` |
| `gp` / `gpf` | `git push` / force-with-lease push |
| `gsta` / `gsts` | Stash push / show stash patch |
| `grh` / `grhh` | `git reset` / `git reset --hard` |
| `grs` / `grst` | `git restore` / `git restore --staged` |
| `gsh` | `git show` |
| `git sw` / `git swc` | Global aliases for `switch` / `switch --create` |

## Python and Virtualenv

| Shortcut | Does |
|----------|------|
| `v` | Activate `.venv` or `venv` |
| `pyrun MOD` | `python -m MOD` |
| `pyserver` | `python -m http.server` |

Behavior:

- Entering a directory with `.venv` or `venv` auto-activates it.
- Leaving that project tree auto-deactivates it.

## direnv — Per-Project Environment Variables

`direnv` loads a `.envrc` file when you enter a directory and unloads it when you leave. The hook is already wired into the shell by this setup.

```bash
# In any project directory:
echo 'export MY_API_KEY="..."' > .envrc
direnv allow          # approve the file once (re-run after each edit)
```

Practical uses:

- Load project-specific API keys without putting them in `~/.zshrc.local`
- Set `PYTHONPATH`, `CUDA_VISIBLE_DEVICES`, or other per-project variables
- Auto-activate a virtualenv for projects that don't use `.venv`/`venv` naming

```bash
# .envrc example for an ML project
export HF_TOKEN="hf_..."
export CUDA_VISIBLE_DEVICES="0"
layout python3          # direnv stdlib: creates and activates a venv
```

`direnv allow` must be re-run after each edit to the `.envrc` file (intentional security check).

## VPN-Aware SSH Helper

Normal `ssh` is left untouched. Use `sshv` when you want the optional VPN-aware behavior from this setup.

In interactive shells, `sshv`:

- adds `ConnectTimeout=10` unless you set one explicitly (override with `-o ConnectTimeout=…`)
- resets terminal input modes before and after — prevents raw mouse and Kitty keyboard escape codes leaking when tmux, Zellij, vim, or similar apps were running remotely
- if the connection fails, prints a hint to run `vpn-connect` and retry manually

The VPN helper commands are installed by `setup_zsh.sh`. They use managed per-user locations instead of `~/vpn/`, and they print setup instructions if your credentials or `.ovpn` config are still missing. For the exact paths and setup steps, see [SETUP_DETAILS.md](SETUP_DETAILS.md).

`ssh-fix-colors user@host` installs your local `$TERM` terminfo on the remote so colors and cursor keys work correctly. This is only needed for remotes where `setup_zsh.sh` hasn't been run — the setup script installs terminfo for common modern terminals (Ghostty, Kitty, WezTerm) automatically.

If SSH still misbehaves, run [`diagnose_ssh.sh`](diagnose_ssh.sh) from the repo root:

```bash
bash diagnose_ssh.sh
```

## AWS: EC2 VM Helper (`vm`)

Useful for connecting to a cloud GPU instance for training jobs or experiments. Configure in `~/.zshrc.local`. For setup steps, see [SETUP_DETAILS.md](SETUP_DETAILS.md).

`vm` knows which machine to connect to via env vars in `~/.zshrc.local`:

- **Direct SSH mode** — set `EC2_SSH_HOST` to a hostname or IP. `vm connect` SSHes straight in, no AWS involved.
- **Full AWS mode** — set `EC2_INSTANCE_ID` (+ `EC2_REGION`, `EC2_AWS_PROFILE`). `vm connect` looks up the IP via AWS and can auto-start a stopped instance.

Both modes require `EC2_SSH_USER` and `EC2_SSH_KEY`. If nothing is configured, `vm` prints the setup steps.

| Command | Action | Requires |
|---------|--------|----------|
| `vm` | SSH in (direct or via AWS) | either mode |
| `vm connect` | Same as plain `vm` | either mode |
| `vm status` | Show instance state and IP | AWS |
| `vm start` | Start the instance | AWS |
| `vm stop` | Stop the instance | AWS |
| `vm ip` | Print public IP | AWS |

`ssh` itself does not route through `vm`; the helper is separate and only for this explicit workflow.

## Zellij Usage and Shortcuts

> **Key notation:** `Alt` on Linux = `Option` on macOS.

Managed defaults:

- built-in default preset
- mouse enabled
- `100000` lines of scrollback
- top `zjstatus` bar showing session + host on the left and metrics on the right
- managed layout with a top metrics bar and one main shell pane below it

Main session command:

- `zj` picks an active session with `fzf` when available; if no sessions exist, it starts one named after the current directory
- Outside Zellij, `zj work` attaches to or creates `work`
- Inside Zellij, `zj work` creates `work` in the background if needed, then opens the session manager plugin so you can switch to it; if the plugin fails to launch, it prints the manual shortcut (`Ctrl+o, w`)

| Command | Does |
|---------|------|
| `zj [name]` | Outside Zellij: pick, attach to, or create a session. Inside Zellij: ensure the session exists and open the session manager to switch to it. When starting fresh with no name, defaults to current directory name. |
| `zjs host [session]` | SSH into a remote host and attach to (or create) a named Zellij session — requires zshkit installed on the remote. Sets the terminal tab title immediately to `session @ host`. |
| `zjss host [s1 s2 ...]` | Open a split Zellij layout locally, each pane SSHing into the remote and attaching to a named session. 2 names = side-by-side, 4 names = 2x2. Defaults to sessions `0 1 2 3` in a 2x2 layout. |
| `zjclean` | Delete all sessions and their scrollback/resurrection history — lists each session with its age before confirming |
| `zellij list-sessions` | List active Zellij sessions |
| `zellij delete-session <name> --force` | Delete a specific Zellij session by name, killing it first if needed |
| `zellij delete-all-sessions -f` | Delete every Zellij session, killing running ones first |

### Default Preset

| Key | Action |
|-----|--------|
| `Ctrl+p` | Enter Pane mode |
| `Ctrl+t` | Enter Tab mode |
| `Ctrl+n` | Enter Resize mode |
| `Ctrl+s` | Enter Scroll mode |
| `Ctrl+o` | Enter Session mode |
| `Ctrl+q` | Quit Zellij |

### Fast Actions

| Key | Action |
|-----|--------|
| `Alt+n` | New pane (smart placement) |
| `Alt+h` / `Alt+j` / `Alt+k` / `Alt+l` | Move between panes |
| `Alt+←` / `Alt+↓` / `Alt+↑` / `Alt+→` | Move between panes (arrow variant) |
| `Alt+[` / `Alt+]` | Previous / next tab |
| `Alt+f` | Show / hide floating panes |
| `Alt+p` | Multiple pane select mode |

### Mode Highlights

| Mode | Useful keys |
|------|-------------|
| Pane | `n` new pane, `d` split down, `r` split right, `s` stack panes, `f` new floating pane, `i` pin floating, `x` close, `z` fullscreen, `c` rename |
| Tab | `n` new tab, `x` close tab, `r` rename, `h` / `l` move tabs |
| Resize | `h` / `j` / `k` / `l` resize, `+` / `-` grow or shrink |
| Scroll | `j` / `k` scroll, `Ctrl+d` / `Ctrl+u` page, `s` search, `e` open scrollback in micro, `q` / `Escape` exit |
| Session | `d` detach, `w` session manager, `l` layout manager, `c` config screen, `p` plugin manager, `a` about |

### Scrollback, Search, and Open in Editor

Enter Scroll mode with `Ctrl+s` (must be inside a Zellij session — run `zj` if not), then:

| Key | Action |
|-----|--------|
| `j` / `k` | Scroll one line down / up |
| `Ctrl+d` / `Ctrl+u` | Page down / up |
| `s` | Search — type a query, `n` / `N` to jump to next / previous match |
| `e` | Open the full scrollback buffer in micro |
| `q` / `Escape` | Exit scroll mode |

**Open in editor** (`e`) dumps the entire pane scrollback to a temp file and opens it in `micro`. To copy output that already ran:

1. Press `e` to open the scrollback in micro
2. `Ctrl+A` to select all — or click and drag to select a specific section
3. `Ctrl+C` to copy to your system clipboard
4. `Ctrl+Q` to quit

> `Shift+arrows` for selection may be intercepted by Zellij — use `Ctrl+A` or mouse instead.

To use a different editor for Zellij's scrollback, change the `scrollback_editor` line in `~/.config/zellij/config.kdl`. To set your shell's `$EDITOR`, add to `~/.zshrc.local` and reload:

```bash
export EDITOR=vim    # or micro, nvim, hx, etc.
```

### Floating and Stacked Panes

**Floating panes** keep running in the background when hidden — toggle them back any time.

| Key | Action |
|-----|--------|
| `Alt+f` | Show / hide all floating panes |
| Pane mode → `f` | Open a new floating pane |
| Pane mode → `i` | Pin the focused floating pane — stays on top of tiled panes permanently |
| Mouse drag | Reposition a floating pane |

Practical use: open a floating pane for a quick reference (`man curl`, a Python REPL, a second shell), hide it with `Alt+f`, and it keeps running in the background.

**Stacked panes** sit on top of each other in a tile slot. In Pane mode, press `s` to stack the focused pane. Cycle through a stack with `Tab`. Good for keeping reference content (docs, logs) accessible without consuming horizontal space.

### Multiple Pane Select

`Alt+p` enters multiple-pane selection. Select panes with arrow keys or by clicking, then batch-operate:

- Close all selected panes at once
- Break selected panes into a new tab
- Stack selected panes together

### Mouse and Clipboard

| Behavior | Notes |
|----------|-------|
| Mouse mode | Enabled |
| Drag to select text | Copies to clipboard on release — no modifier key needed for regular shell output |
| Drag pane border | Resize the pane (enabled via `advanced_mouse_actions`) |
| `Ctrl+ScrollWheel` | Resize the focused pane (enabled via `advanced_mouse_actions`) |
| Hold `Shift` + mouse | Bypass Zellij — use native terminal selection, scroll, and link clicking. Mainly needed inside apps that have their own mouse handling (vim, htop, lazygit, etc.) |
| Clipboard — macOS | `pbcopy` (built-in, no setup needed) |
| Clipboard — Linux Wayland | `wl-copy` (`wl-clipboard` package, installed by setup) |
| Clipboard — Linux X11 | `xclip` (installed by setup) |

> **OSC 52 requirement:** Mouse-drag clipboard copy (both locally and over SSH) requires a terminal that supports OSC 52 — Kitty, iTerm2, Ghostty, WezTerm, or Alacritty. The setup installs Kitty automatically on both Linux and macOS. Ghostty and iTerm2 are still good alternatives to try. See [SETUP_DETAILS.md](SETUP_DETAILS.md#recommended-terminal-emulator) for the full comparison table.
>
> **GNOME Terminal / terminals without OSC 52:** Use `Shift+drag` to select, then `Ctrl+Shift+C` to copy. This bypasses Zellij and uses the terminal's native selection — works locally and over SSH.

### Status and Restore

| Setting | Value |
|---------|-------|
| Status bar | Top `zjstatus` plugin fed by `~/.local/bin/zellij-metrics` |
| Left side | Session name and machine name |
| Right side | CPU, RAM, GPU when available, and time |
| Permission handling | Installer pre-seeds `zjstatus` permissions cache; if a prompt still appears, focus the bar and press `y` |
| Session restore | Enabled via Zellij serialization settings |
| Scrollback | `100000` lines |

### Claude Code Integration

zshkit installs [zellij-attention](https://github.com/KiryuuLight/zellij-attention), a background plugin that adds status icons to Zellij tab names when Claude Code is running:

| Icon | Meaning |
|------|---------|
| ⏳ | Claude is waiting for your input |
| ✅ | Claude finished its task |

The icon clears automatically when you focus the pane. This works alongside the existing `zjstatus` bar — no tab bar changes needed.

Claude Code hooks in `~/.claude/settings.json` wire up the notifications automatically. When Claude finishes, the terminal tab title also updates to show `✅ claude done`.

### Terminal Tab Titles

zshkit sets terminal tab titles via OSC 2 escape sequences, supported by Kitty, Ghostty, WezTerm, iTerm2, and most modern terminals.

Format: `● session @ host` (icon on left)

| State | Title |
|-------|-------|
| Command running | `◌ main @ myserver` |
| Command succeeded | `● main @ myserver` |
| Command failed | `⚠ main @ myserver` |
| Outside Zellij | `● hostname` |

When using `zjs` to SSH into a remote, the tab title updates immediately to `session @ host` before the remote prompt appears.

Kitty's own automatic tab title updates are disabled (`shell_integration enabled no-title`) since zshkit manages titles directly. To restore Kitty's default behaviour, change this line in `~/.config/kitty/kitty.conf`.

## References

- [README.md](README.md)
- [SETUP_DETAILS.md](SETUP_DETAILS.md)
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh/wiki)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [gitstatus](https://github.com/romkatv/powerlevel10k/blob/master/gitstatus/README.md)
- [Git status symbols explained](https://github.com/romkatv/powerlevel10k/tree/master?tab=readme-ov-file#what-do-different-symbols-in-git-status-mean)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [fzf-tab](https://github.com/Aloxaf/fzf-tab)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [Zellij screencasts](https://zellij.dev/screencasts/)
- [Zellij cheat sheet](https://zellijcheatsheet.dev/)
