# Setup Details

Detailed install and maintenance guide for `setup_zsh.sh`. Most users can run the script as-is; if you want to understand exactly what changes, read this doc alongside [setup_zsh.sh](setup_zsh.sh) and [.zshrc.template.sh](.zshrc.template.sh). For day-to-day shortcuts, keybindings, and workflows, use [USAGE_GUIDE.md](USAGE_GUIDE.md).

## Quick Start

From the repo root:

```bash
bash setup_zsh.sh
```

- Linux: requires `apt-get` (Ubuntu/Debian family).
- macOS: requires [Homebrew](https://brew.sh).
- The script is safe to re-run — already-installed components are skipped automatically.
- The script prompts before each install step. Pass `--yes` / `-y` to auto-confirm all prompts (non-interactive mode).
- `bash setup_zsh.sh --yes` skips prompts, but on Linux it still needs non-interactive `sudo` for apt/terminfo. Prefer running interactively (type your password when `sudo` runs) instead of enabling blanket passwordless `sudo` for your user.

**Pinning versions:** Tool versions are resolved from GitHub at runtime. Override any of them with env vars:

```bash
ZELLIJ_VERSION=v0.44.0 CARAPACE_VERSION=v1.6.4 bash setup_zsh.sh
```

> **Local and remote:** Run the installer on every machine you work on — local and remote. Your local install gives you the shell and tools. Running it on a remote machine is what makes `zj` sessions persist there across SSH disconnects.

### Security notes

- **Release downloads:** Linux installs of Zellij, carapace-bin, `zjstatus.wasm`, and `zellij-attention.wasm` are fetched over HTTPS from the latest GitHub release. Versions are resolved at runtime via the GitHub API and can be pinned by setting `ZELLIJ_VERSION`, `ZJSTATUS_VERSION`, `ZELLIJ_ATTENTION_VERSION`, or `CARAPACE_VERSION` in your environment before running the script. There is no checksum verification; mitigate supply-chain risk by auditing versions, mirroring artifacts, or installing equivalent packages from your distro.
- **curl \| sh:** Oh My Zsh, `uv`, and `navi` still use upstream install scripts over HTTPS (standard trade-off: convenience vs. supply-chain review). Mitigate by auditing scripts before each run or installing those tools via distro packages instead.
- **Zellij plugin permissions:** The installer pre-writes `~/.cache/zellij/permissions.kdl` for bundled `zjstatus` and `zellij-attention` so the status bar works without an interactive prompt (auto-grants `RunCommands` for zjstatus). Set `ZSHKIT_SKIP_ZELLIJ_PERMISSION_SEED=1` when running `setup_zsh.sh` if you prefer to approve inside Zellij instead.
- **direnv:** The template enables `direnv` only if the binary exists; new `.envrc` files still require `direnv allow` before they run.

## What The Setup Script Does

`setup_zsh.sh` installs and configures the following:

| Category | Items |
|----------|-------|
| Core | zsh, Oh My Zsh, Powerlevel10k |
| Plugins | zsh-autosuggestions, zsh-history-substring-search, fast-syntax-highlighting |
| CLI tools | fzf, fd, bat, ripgrep (`rg`), tree, Zellij, lsd, zoxide, lazygit, fastfetch, yazi, ncdu, micro, delta, screen, OpenVPN, jq, direnv, mosh, gh, nvtop, uv, navi, sshfs |
| Font | [MesloLGS NF](https://github.com/romkatv/powerlevel10k/tree/master?tab=readme-ov-file#fonts) — recommended by Powerlevel10k (Linux: `~/.local/share/fonts`; macOS: Homebrew cask or `~/Library/Fonts`) |
| Zellij | Managed config in `~/.config/zellij/` with the built-in default preset, large scrollback, top `zjstatus` bar, and `~/.local/bin/zellij-metrics` |
| Config | Backup and replace `~/.zshrc` from `.zshrc.template.sh`, install `~/.p10k.zsh` from **`templates/p10k.zsh.template`** (tracked Powerlevel10k export, includes 24h clock + status segments), install `~/.config/ghostty/config` from **`templates/ghostty/`**, preserve/create `~/.zshrc.local`, set zsh as default shell when safe, add global git aliases `git sw` / `git swc`, configure `delta`, install terminfo entries for modern terminals (Ghostty, Kitty, WezTerm), add SSH keepalive/COLORTERM block to `~/.ssh/config`, set `skip_global_compinit` in `~/.zshenv`, and add a zsh auto-launch fallback to `~/.bashrc` |

On Linux, CLI tools are installed through apt where possible, with some optional items handled best-effort. `uv` is installed via its official curl installer on Linux (not in apt). On macOS, the same toolchain is installed through Homebrew. **Ghostty is installed via snap on Linux and `brew install --cask ghostty` on macOS.**

**sshfs on macOS:** SSHFS requires the [macFUSE](https://osxfuse.github.io/) kernel extension (`brew install --cask macfuse`) in addition to the `sshfs` formula. Because macFUSE needs user approval in System Settings → Privacy & Security → Security (allow kernel extension from Benjamin Fleischer), the installer skips the macFUSE cask automatically and prints instructions. Install manually after granting approval:

```bash
brew install --cask macfuse
# Reboot or approve the kernel extension in System Settings first, then:
brew install sshfs
``` The script also creates `fd` / `bat` compatibility symlinks on Linux when the system package names are `fdfind` / `batcat`. `direnv` is activated via a hook added to `~/.zshrc` — create a `.envrc` in any project directory to load environment variables automatically when you enter it.

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
| `~/.config/ghostty/config` | Managed Ghostty starter config |
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
| `~/.cache/zellij/permissions.kdl` | Pre-seeded by setup for bundled plugins; Zellij may extend it when you approve others. Skip pre-seed with `ZSHKIT_SKIP_ZELLIJ_PERMISSION_SEED=1` (see `setup_zsh.sh` header) |

The script preserves `~/.zshrc.local`, backs up existing managed files before overwriting them, and skips `chsh` over SSH so the default shell is only changed when it is safe to do so.

## Recommended Terminal Emulator

The setup installs **Ghostty** automatically on both Linux and macOS. Ghostty supports **OSC 52**, which is required for Zellij's mouse-drag clipboard copy to work over SSH. Without OSC 52, clipboard copy only works in local Zellij sessions.

zshkit writes a starter `~/.config/ghostty/config` with:

- MesloLGS NF font (matches zshkit's installed font)
- Catppuccin Macchiato theme
- generous scrollback (50 MB)
- no audio bell
- block cursor, no blink
- small window padding
- hide mouse pointer while typing
- shell integration for jump-to-prompt shortcuts

Edit `~/.config/ghostty/config` directly. Reload with `Ctrl+Shift+,` (Linux) or `Cmd+Shift+,` (macOS). See [GHOSTTY.md](GHOSTTY.md) for a full shortcut reference.

| Terminal | OS | OSC 52 | Notes |
|----------|----|--------|-------|
| Ghostty | Linux, macOS | Yes | Installed by setup |
| iTerm2 | macOS | Yes | Not installed by setup; worth trying as an alternative |
| GNOME Terminal | Linux | No | Use `Shift+drag` → `Ctrl+Shift+C`; SSH clipboard copy not available (no OSC 52) |
| macOS Terminal.app | macOS | No | Use `Shift+drag` to select; SSH clipboard copy not available (no OSC 52) |

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
| `~/.config/ghostty/config` | Ghostty starter config; edit directly and reload with `Ctrl+Shift+,` |

```bash
# Edit tracked defaults (from the repo root)
nano .zshrc.template.sh

# Edit personal settings
nano ~/.zshrc.local

# Edit Ghostty settings
nano ~/.config/ghostty/config

# Optional: disable live auto-list while typing (on by default)
echo 'export ZSH_AUTOLIST_ON_TYPE=0' >> ~/.zshrc.local

# Optional: open bare `cd ` list only when the directory count is small
echo 'export ZSH_AUTOLIST_CD_EMPTY_MAX=20' >> ~/.zshrc.local

# Apply shell changes
source ~/.zshrc

# Reload Ghostty config
# Ctrl+Shift+, (Linux) or Cmd+Shift+, (macOS)
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

## Zellij Design Choices

### Mouse mode — `Shift+drag` required for text selection

Zellij's `mouse_mode` is enabled (the default). This means Zellij intercepts all mouse events to provide pane focus, mouse scroll, and border drag-resize. The unavoidable side effect is that native terminal text selection requires **holding `Shift` while dragging**.

This is an architectural limitation of Zellij — there is no config flag that gives plain drag-select while keeping mouse scroll. Tmux has the same constraint. The only alternative is using a terminal's built-in splits (e.g. Ghostty splits), which sacrifices Zellij's session persistence.

**To select and copy text:**

1. Hold `Shift` and drag to select
2. Release, then press `Enter` or `y` to copy to clipboard

**Why not disable `mouse_mode`?**  
Setting `mouse_mode false` breaks mouse scroll entirely — the terminal prints raw escape codes (`^[[B`) instead of scrolling. It was tried and reverted. The Shift+drag friction is the lesser trade-off.

### Session serialization — disabled by default

Zellij's `serialize_pane_viewport` feature saves pane scrollback to disk so sessions can be visually restored after detaching. It is **disabled** in the zshkit default config.

**Why:** When enabled, reconnecting after a **remote machine reboot** shows the old session's scrollback — including any processes that were running before the reboot. This looks like a stuck process is still alive, when in reality the machine just came back up clean. The illusion is confusing and hard to diagnose.

With serialization off, a fresh attach after a reboot always shows a clean terminal, which correctly reflects the machine state.

**To opt in:** Uncomment the two lines in `~/.config/zellij/config.kdl` (or in [templates/zellij/config.kdl.template](templates/zellij/config.kdl.template) to persist across reinstalls):

```kdl
serialize_pane_viewport true
scrollback_lines_to_serialize 100000
```

## References

- [README.md](README.md)
- [USAGE_GUIDE.md](USAGE_GUIDE.md)
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh/wiki)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [gitstatus](https://github.com/romkatv/powerlevel10k/blob/master/gitstatus/README.md)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
