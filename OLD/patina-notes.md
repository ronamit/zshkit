# zsh-patina — notes for future reference

Tried and shelved in favour of fast-syntax-highlighting due to reliability issues.

## What it is
A Rust-based zsh syntax highlighter that runs as a background daemon and
communicates via Unix socket. Uses Sublime Text grammar files (via syntect).

- Repo: https://github.com/michel-kraemer/zsh-patina
- Install: `cargo install zsh-patina`
- Activation: `eval "$(zsh-patina activate)"` + `zsh-patina start`

## Config location
`~/.config/zsh-patina/`
- `config.toml` — points at the theme
- `theme.toml` — customisations (extends a base theme)
- `classic.toml` — classic/ANSI base theme (not a built-in in the binary enum,
  must be shipped as a file and referenced via `extends = "file:…"`)

## Theme we built
See `patina/theme.toml` and `patina/classic.toml` in this repo.
Extends classic with:
- `meta.function-call.arguments` = white
- bold yellow `keyword.control` (if/while/for)
- bold blue `&&`/`||`, bold magenta `|`, flat blue `;`
- magenta `=` in --flag=value and redirections
- bold yellow `\` continuation
- underlined green for external commands, cyan for builtins,
  bold green for functions, italic green for aliases
- cyan `[[`/`]]`

## Gotchas
- The daemon must be started separately (`zsh-patina start`) — `activate`
  alone silently does nothing if the socket is absent.
- `extends = "classic"` does NOT work — classic is not in the ThemeSource enum.
  Must use `extends = "file:/abs/path/classic.toml"`.
- `~/.cargo/bin` must be in PATH before the `_patina_installed` check runs.
- Built-in themes for extends: patina, nord, tokyonight, lavender, simple.

## Why shelved
Too many reliability issues on fresh VMs and edge cases with the daemon.
fast-syntax-highlighting is simpler and battle-tested.
