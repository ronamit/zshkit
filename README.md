# zshkit

[Setup details](SETUP_DETAILS.md) · [Usage guide](USAGE_GUIDE.md)

A single install script that sets up a fast, opinionated shell environment on any Linux or macOS machine. Bundles Zellij, fzf, zoxide, Powerlevel10k, and custom helpers so you're productive immediately.

| To do this... | Run this | Powered by |
| :--- | :--- | :--- |
| Keep a remote session alive across disconnects | `zj` | [Zellij](https://zellij.dev/) |
| SSH into a remote host and attach to a Zellij session | `zjs host [session]` | [Zellij](https://zellij.dev/) |
| Jump instantly to a frequent directory | `z <name>` | [zoxide](https://github.com/ajeetdsouza/zoxide) |
| Fuzzy-search history or insert a file path | `Ctrl+R` / `Ctrl+T` | [fzf](https://github.com/junegunn/fzf) |
| Interactively browse disk usage | `ncdu` | [ncdu](https://dev.yorhel.nl/ncdu) |
| Syntax-highlighted prompt with git status | _(always on)_ | [Powerlevel10k](https://github.com/romkatv/powerlevel10k) |
| History suggestions as you type | _(always on)_ | [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) |

## Quick Start

```bash
git clone https://github.com/ronamit/zshkit && cd zshkit
bash setup_zsh.sh        # interactive
bash setup_zsh.sh --yes  # non-interactive
```

**Requirements:** Linux (Ubuntu/Debian) or macOS with [Homebrew](https://brew.sh).

After it finishes:

1. Set your terminal font to [MesloLGS NF](https://github.com/romkatv/powerlevel10k/tree/master?tab=readme-ov-file#fonts) so prompt icons render correctly.
2. Open a new terminal and run `p10k configure` to pick your prompt style.
3. The setup installs [Kitty](https://sw.kovidgoyal.net/kitty/) as the default terminal with a starter config. Press `Ctrl+Shift+F2` to edit it. Ghostty and iTerm2 are good alternatives.

The installer backs up your existing config. To roll back: `bash rollback.sh`

See [SETUP_DETAILS.md](SETUP_DETAILS.md) for full install details and customization.

## Prompt

Git-aware prompt: branch, dirty status, and command duration at a glance.

![Prompt with git status](assets/prompt.gif)

## Suggestions

Gray suggestion appears as you type — `→` to accept, `↓` to cycle through older matches.

![Autosuggestions and history cycling](assets/autosuggest.gif)

## History search

`Ctrl+R` opens a fuzzy search over your full command history.

![Fuzzy history search with fzf](assets/history-search.gif)

| Key | Action |
|-----|--------|
| `Ctrl+R` | Fuzzy search history |
| `Ctrl+T` | Insert a file path at the cursor |
| `Alt+C` | Fuzzy change directory |

## Directory jumping

`z` jumps to a recently visited directory by partial keyword — no full path needed.

![Directory jumping with zoxide](assets/zoxide.gif)

```bash
z proj       # jump to the most frequent match for "proj"
z ml exp     # narrow by multiple terms
zi           # interactive picker
```

## Disk usage

`ducks` shows top-level sizes sorted by largest first.

![Disk usage with ducks](assets/ducks.gif)

```bash
ducks        # quick summary of current directory
ncdu         # interactive drill-down
```

## Persistent sessions with Zellij

Sessions survive disconnects — close your laptop mid-run and reconnect later.

![Zellij session commands](assets/zj-session.gif)

```bash
zj                  # pick from active sessions (or start one named after current dir)
zj my-session       # attach to or create a named session
zjs myserver        # SSH into a host and attach to a Zellij session in one step
zjs myserver work   # specify the session name
```

> **Remote sessions:** run `bash setup_zsh.sh` on the remote machine too — Zellij needs to be installed there for sessions to live on the remote side.

## SSH

`sshv` wraps `ssh` with a 10-second connection timeout and terminal mode reset.

```bash
sshv user@host
```

## Docs

- [SETUP_DETAILS.md](SETUP_DETAILS.md) — install details, customization, rollback
- [USAGE_GUIDE.md](USAGE_GUIDE.md) — all aliases, keybindings, Zellij, fzf, VPN, EC2
- [AGENTS.md](AGENTS.md) — notes for AI coding agents

## Updating

```bash
git pull && bash setup_zsh.sh
```

Re-running `setup_zsh.sh` also updates Kitty to the latest upstream release.
