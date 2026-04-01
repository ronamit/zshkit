# Setup Details

Detailed install and maintenance guide for `setup_zsh.sh`. Most users can run the script as-is; if you want to understand exactly what changes, read this doc alongside [setup_zsh.sh](setup_zsh.sh) and [.zshrc.template.sh](.zshrc.template.sh). For day-to-day shortcuts, keybindings, and workflows, use [USAGE_GUIDE.md](USAGE_GUIDE.md).

## Quick Start

From the repo root:

```bash
bash setup_zsh.sh
```

- Linux: requires `apt-get` (Ubuntu/Debian family).
- macOS: requires [Homebrew](https://brew.sh).
- The script is safe to re-run.

> **Local and remote:** Run the installer on every machine you work on — local and remote. Your local install gives you the shell and tools. Running it on a remote machine is what makes `zj` sessions persist there across SSH disconnects.

## What The Setup Script Does

`setup_zsh.sh` installs and configures the following:

| Category | Items |
|----------|-------|
| Core | zsh, Oh My Zsh, Powerlevel10k |
| Plugins | zsh-autosuggestions, zsh-history-substring-search, zsh-syntax-highlighting, fzf-tab |
| CLI tools | fzf, fd, bat, ripgrep (`rg`), tree, Zellij, lsd, zoxide, lazygit, fastfetch, yazi, ncdu, micro, delta, screen, OpenVPN, jq, direnv, mosh, gh, nvtop, uv |
| Font | [MesloLGS NF](https://github.com/romkatv/powerlevel10k/tree/master?tab=readme-ov-file#fonts) — recommended by Powerlevel10k (Linux: `~/.local/share/fonts`; macOS: Homebrew cask or `~/Library/Fonts`) |
| Zellij | Managed config in `~/.config/zellij/` with the built-in default preset, large scrollback, top `zjstatus` bar, and `~/.local/bin/zellij-metrics` |
| Config | Backup and replace `~/.zshrc` from `.zshrc.template.sh`, install `~/.p10k.zsh` from **`templates/p10k.zsh.template`** (tracked Powerlevel10k export, includes 24h clock + status segments), install `~/.config/kitty/kitty.conf`, `open-actions.conf`, and `quick-access-terminal.conf` from **`templates/kitty/`** on local Kitty installs, preserve/create `~/.zshrc.local`, set zsh as default shell when safe, add global git aliases `git sw` / `git swc`, configure `delta`, install terminfo entries for modern terminals (Ghostty, Kitty, WezTerm), add SSH keepalive/COLORTERM block to `~/.ssh/config`, set `skip_global_compinit` in `~/.zshenv`, and add a zsh auto-launch fallback to `~/.bashrc` |

On Linux, CLI tools are installed through apt where possible, with some optional items handled best-effort. `uv` is installed via its official curl installer on Linux (not in apt). On macOS, the same toolchain is installed through Homebrew. **Kitty is installed on both Linux and macOS using Kitty's official upstream installer**, then symlinked into `~/.local/bin` so you get current releases even when distro/Homebrew packages lag behind. The script also creates `fd` / `bat` compatibility symlinks on Linux when the system package names are `fdfind` / `batcat`. `direnv` is activated via a hook added to `~/.zshrc` — create a `.envrc` in any project directory to load environment variables automatically when you enter it.

## Files, Paths, and Backups

The setup writes or manages these locations:

| Path | Purpose |
|------|---------|
| `~/zshkit/setup_zsh.sh` | Installer and updater entrypoint |
| `~/zshkit/.zshrc.template.sh` | Tracked shell defaults |
| `~/.zshrc` | Active shell config copied from the template |
| `~/.p10k.zsh` | Powerlevel10k theme config (installed from **`templates/p10k.zsh.template`**; previous file backed up when replaced) |
| `~/.zshrc.local` | Personal tokens, exports, and local overrides |
| `~/.zsh_backups/` | Timestamped backups of replaced shell config |
| `~/.config/kitty/kitty.conf` | Managed Kitty starter config (installed when Kitty is available locally) |
| `~/.config/kitty/open-actions.conf` | Managed Kitty open-actions config for editor-friendly file hyperlinks |
| `~/.config/kitty/quick-access-terminal.conf` | Managed Kitty quick-access-terminal starter config |
| `~/.config/zellij/config.kdl` | Managed Zellij config |
| `~/.config/zellij/layouts/default.kdl` | Managed default Zellij layout |
| `~/.local/bin/zellij-metrics` | Status helper used by the Zellij top bar |
| `~/.local/bin/vpn-connect` / `vpn-disconnect` / `vpn-status` | Managed VPN helper commands |
| Linux: `~/.local/share/zshkit/vpn/` | Managed VPN scripts and credentials file |
| Linux: `~/.local/state/zshkit/vpn/` | VPN runtime state, temp files, and logs |
| macOS: `~/Library/Application Support/zshkit/vpn/` | Managed VPN scripts and credentials file |
| macOS: `~/Library/Application Support/zshkit/vpn/state/` | VPN runtime state, temp files, and logs |
| `~/.ssh/config` | Managed SSH keepalive + `COLORTERM` forwarding block (bracketed with markers so re-runs update in place) |
| `~/.zshenv` | `skip_global_compinit=1` added to avoid completion conflicts |
| `~/.bashrc` | Zsh auto-launch fallback block appended (only if not already present) |
| `~/.terminfo/` | User-local terminfo entries for Ghostty, Kitty, and WezTerm |
| `~/.cache/zellij/permissions.kdl` | zjstatus permissions pre-seeded to skip the interactive `y` prompt |

The script preserves `~/.zshrc.local`, backs up existing managed files before overwriting them, and skips `chsh` over SSH so the default shell is only changed when it is safe to do so.

## Recommended Terminal Emulator

The setup installs **Kitty** automatically on both Linux and macOS using Kitty's official upstream installer. Kitty supports **OSC 52**, which is required for Zellij's mouse-drag clipboard copy to work over SSH. Without OSC 52, clipboard copy only works in local Zellij sessions.

On local installs where Kitty is available, zshkit also writes a starter `~/.config/kitty/kitty.conf` with:

- top tab bar (`tab_bar_edge top`)
- powerline tab styling
- draggable tabs
- a slightly larger default font size
- a subtle hover-only scrollbar
- no audio bell
- larger scrollback
- new tabs and windows open in the current working directory
- keyboard shortcuts for Kitty's fast file, directory, and hints pickers
- right-click clipboard paste and middle-click selection paste
- a small amount of padding
- background-window command-finish notifications
- editor-friendly file hyperlink handling via `open-actions.conf`
- a quick-access-terminal starter config

Inside Kitty, press `Ctrl+Shift+F2` to open `kitty.conf` and `Ctrl+Shift+F5` to reload it after edits.

If you want to try other terminals, **Ghostty** and **iTerm2** are still both solid options and also support OSC 52.

| Terminal | OS | OSC 52 | Notes |
|----------|----|--------|-------|
| Kitty | Linux, macOS | Yes | Installed by setup from upstream releases |
| Ghostty | Both | Yes | Not installed by setup; worth trying as an alternative |
| iTerm2 | macOS | Yes | Not installed by setup; worth trying as an alternative |
| GNOME Terminal | Linux | No | Use `Shift+drag` → `Ctrl+Shift+C` instead |
| macOS Terminal.app | macOS | No | Use `Shift+drag` to select instead |

See [USAGE_GUIDE.md](USAGE_GUIDE.md) for the full clipboard behavior details.

## After Install

1. Set your terminal font to [MesloLGS NF](https://github.com/romkatv/powerlevel10k/tree/master?tab=readme-ov-file#fonts) (recommended by Powerlevel10k) so prompt icons render correctly before you see the new shell for the first time.
2. Open a new terminal.
3. Review `~/.zshrc.local` and add any missing exports, tokens, or personal overrides.
4. **Powerlevel10k — run the setup wizard:** in zsh, run **`p10k configure`**. That starts Powerlevel10k’s **interactive** configuration flow: you pick the overall style (lean, classic, rainbow, pure-like, …), spacing, icons, and which segments appear ([git](https://github.com/romkatv/powerlevel10k/tree/master?tab=readme-ov-file#what-do-different-symbols-in-git-status-mean), exit status, command duration, clock, etc.). Everything is written to **`~/.p10k.zsh`**. The installer copies the tracked **`templates/p10k.zsh.template`** (maintainer default, including **24-hour time** on the right prompt and status/exit-code segments). Use **`p10k configure`** whenever you want to change the prompt. To change what *future* installs get, update **`templates/p10k.zsh.template`** in the repo (or paste your new **`~/.p10k.zsh`** there).
5. If setup replaced an existing **`~/.p10k.zsh`**, your previous copy is under **`~/.zsh_backups/<timestamp>/`** (the installer prints the exact path). Restore from there if needed.

### `p10k configure` (quick reference)

| | |
|--|--|
| **When** | After install, in a zsh session (`exec zsh` or a new terminal). |
| **Command** | `p10k configure` |
| **What it does** | Full-screen Q&A wizard; updates **`~/.p10k.zsh`**. |
| **Re-run** | Safe to run again any time your tastes change. |

## Where To Customize

`~/.zshrc` is a **managed file** — `setup_zsh.sh` overwrites it on every run. Do not edit it directly; your changes will be lost on the next update.

Put personal settings in **`~/.zshrc.local`** instead. This file is sourced at the end of `~/.zshrc` and is never touched by the installer. It is the right place for:

- API keys and tokens (`GITHUB_TOKEN`, `OPENAI_API_KEY`, etc.)
- VM / cloud configuration (`EC2_SSH_HOST`, `EC2_INSTANCE_ID`, etc.)
- VPN path overrides (`ZSHKIT_VPN_CONFIG_FILE`, etc.)
- Behaviour tweaks (`ZSH_AUTOLIST_ON_TYPE`, `EDITOR`, etc.)
- Anything machine-specific that should not be committed to the repo

The installer creates `~/.zshrc.local` with a commented template on first run, so the file and its available options will already be there after `setup_zsh.sh` completes.

| File | Purpose |
|------|---------|
| `.zshrc.template.sh` (repo root) | Tracked project defaults — edit to change shared behaviour |
| `~/.zshrc.local` | **Your** personal settings — never overwritten by the installer |
| `~/.p10k.zsh` | Powerlevel10k theme; reinstalled from **`templates/p10k.zsh.template`** on each `setup_zsh.sh` run (previous file backed up). Run `p10k configure` or edit the template to customize defaults. |
| `~/.config/kitty/kitty.conf` | Kitty starter config; edit directly or open it from Kitty with `Ctrl+Shift+F2` |
| `~/.config/kitty/open-actions.conf` | Kitty file-opening rules; used for clickable rg/file hyperlinks |
| `~/.config/kitty/quick-access-terminal.conf` | Kitty quick-access-terminal settings |

```bash
# Edit tracked defaults (from the repo root)
nano .zshrc.template.sh

# Edit personal settings
nano ~/.zshrc.local

# Edit Kitty settings
nano ~/.config/kitty/kitty.conf

# Edit Kitty hyperlink actions
nano ~/.config/kitty/open-actions.conf

# Edit Kitty quick-access terminal settings
nano ~/.config/kitty/quick-access-terminal.conf

# Optional: disable live auto-list while typing (on by default)
echo 'export ZSH_AUTOLIST_ON_TYPE=0' >> ~/.zshrc.local

# Optional: open bare `cd ` list only when the directory count is small
echo 'export ZSH_AUTOLIST_CD_EMPTY_MAX=20' >> ~/.zshrc.local

# Apply shell changes
source ~/.zshrc

# Reload Kitty config from inside Kitty
# Ctrl+Shift+F5
```

## Read The Setup In Detail

If you want to inspect exactly what the project does:

- Read [setup_zsh.sh](setup_zsh.sh) for package install flow, backups, shell switching, and generated files.
- Read [.zshrc.template.sh](.zshrc.template.sh) for aliases, widgets, keybindings, autosuggest behavior, helper functions, and interactive shell logic.
- Read [templates/zellij/config.kdl.template](templates/zellij/config.kdl.template) and [templates/zellij/layouts/default.kdl](templates/zellij/layouts/default.kdl) for the managed Zellij config written by the installer.

For actual day-to-day command usage after install, use [USAGE_GUIDE.md](USAGE_GUIDE.md).

## Optional EC2 VM Setup

The `vm` helper gives one-command SSH access to a dev VM. It has two modes:

**Direct SSH mode** — no AWS required. Just set a host:

```bash
export EC2_SSH_HOST="myserver"         # hostname or IP
export EC2_SSH_USER="ubuntu"
export EC2_SSH_KEY="$HOME/.ssh/my-key.pem"
```

**Full AWS mode** — also manages instance state (start/stop/status/auto-IP lookup). Additional requirements: AWS CLI installed, `aws configure sso` completed if your org uses SSO.

```bash
export EC2_SSH_HOST="myserver"         # optional but recommended — skips AWS for plain connect
export EC2_INSTANCE_ID="i-0abc123..."
export EC2_REGION="us-east-2"
export EC2_SSH_USER="ubuntu"
export EC2_SSH_KEY="$HOME/.ssh/my-key.pem"
export EC2_AWS_PROFILE="my-profile"   # optional
```

Then reload and test:

```bash
source ~/.zshrc
vm           # connect
vm status    # requires AWS mode
```

If `vm` is used without configuration, it prints the setup steps. For the command table and daily usage, see [USAGE_GUIDE.md](USAGE_GUIDE.md).

## Optional VPN-Aware SSH Setup

This setup installs `vpn-connect`, `vpn-disconnect`, `vpn-status`, and the `sshv` helper for VPN-dependent hosts. Normal `ssh` is not replaced.

What setup installs for you:

- the managed VPN helper scripts
- the `screen` and `openvpn` runtime dependencies
- a placeholder credentials file you can edit

What you still need to provide:

- your VPN username/password in the managed credentials file
- your `.ovpn` config file

Managed paths:

- Linux credentials file: `~/.local/share/zshkit/vpn/vpn-credentials.txt`
- Linux runtime logs/state: `~/.local/state/zshkit/vpn/`
- macOS credentials file: `~/Library/Application Support/zshkit/vpn/vpn-credentials.txt`
- macOS runtime logs/state: `~/Library/Application Support/zshkit/vpn/state/`
- default OpenVPN config path: `~/client.ovpn`

If your `.ovpn` file lives somewhere else, add this to `~/.zshrc.local` and reload:

```bash
export ZSHKIT_VPN_CONFIG_FILE="/path/to/client.ovpn"
source ~/.zshrc
```

Optional overrides (defaults match the managed paths above):

- `ZSHKIT_VPN_DIR` — managed bundle directory (scripts + default credentials path)
- `ZSHKIT_VPN_CREDENTIALS_FILE` — explicit credentials file path
- `ZSHKIT_VPN_STATE_DIR` — logs, PID file, and temp helper files (Linux default: `~/.local/state/zshkit/vpn`; macOS default: `~/Library/Application Support/zshkit/vpn/state`)

Then use the helpers like this:

```bash
vpn-status
vpn-connect
vpn-disconnect
sshv user@host
```

If the credentials file still contains placeholders, or the `.ovpn` config is missing, the commands print an informative setup message with the exact path to fix.

## Updating

From the repo root:

```bash
git pull
bash setup_zsh.sh
```

## Troubleshooting

### Terminal still starts in bash

Close all terminals and reopen. Check the current default shell:

```bash
# Linux
getent passwd "$USER" | cut -d: -f7

# macOS
dscl . -read "/Users/$USER" UserShell | awk '{print $2}'
```

If needed:

```bash
chsh -s "$(command -v zsh)"
```

Over SSH, the installer skips `chsh` and prints the manual command instead. A full logout/login may still be required.

### Prompt icons look wrong

Set the terminal font to [MesloLGS NF](https://github.com/romkatv/powerlevel10k/tree/master?tab=readme-ov-file#fonts) (recommended by Powerlevel10k) and restart the terminal.

### Completions behave oddly

```bash
rm -f ~/.zcompdump && autoload -Uz compinit && compinit
```

### Completion feels slow in a large repo

Temporarily disable `fzf-tab` to compare behavior:

```bash
mv ~/.oh-my-zsh/custom/plugins/fzf-tab ~/.oh-my-zsh/custom/plugins/fzf-tab.disabled
exec zsh
```

### Key bindings differ from your terminal

Check what your terminal sends:

```bash
cat -v
```

Then adjust bindings in `.zshrc.template.sh` if needed.

## Roll Back

Each `setup_zsh.sh` run creates a timestamped backup under `~/.zsh_backups/<YYYYMMDD_HHMMSS>/` and writes a `manifest.txt` listing what was saved. Use `rollback.sh` to restore one interactively:

```bash
bash rollback.sh
```

The script lists available backups newest-first (with fzf preview when available), shows the manifest, asks for confirmation, then restores `~/.zshrc`, `~/.p10k.zsh`, `~/.ssh/config`, and `~/.config/zellij/` as present in the backup.

To browse or restore manually:

```bash
ls -1td ~/.zsh_backups/*/
cat ~/.zsh_backups/<YYYYMMDD_HHMMSS>/manifest.txt
cp ~/.zsh_backups/<YYYYMMDD_HHMMSS>/.zshrc ~/.zshrc
```

To switch the default shell back to bash:

```bash
chsh -s "$(command -v bash)"
```

Then remove the zsh auto-launch block from `~/.bashrc` if you do not want bash to start zsh:

```bash
# Auto-launch zsh if available (added by zshkit setup)
if [ -t 1 ] && [ -z "$ZSH_VERSION" ] && command -v zsh >/dev/null 2>&1; then
    export SHELL=$(command -v zsh)
    exec zsh
fi
```

## References

- [README.md](README.md)
- [USAGE_GUIDE.md](USAGE_GUIDE.md)
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh/wiki)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [gitstatus](https://github.com/romkatv/powerlevel10k/blob/master/gitstatus/README.md)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [fzf-tab](https://github.com/Aloxaf/fzf-tab)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
