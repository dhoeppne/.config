# zshrc

Configuration for the Zsh shell. The main file is `.zshrc` (symlinked from `~/.zshrc`).

## Design: instant prompt, deferred everything-else

The `.zshrc` is split into two phases so a new terminal window/tab is usable almost
immediately:

- **Eager** — the only work done before the first prompt paints: shell options,
  `PATH`/environment, aliases, autoloaded functions, and the **starship** prompt. This
  is a few milliseconds, so the shell is interactive right away and you can start typing.
- **Deferred** — everything heavy is queued with [`zsh-defer`](https://github.com/romkatv/zsh-defer)
  and runs once the line editor goes idle (right after the first prompt). This includes
  the whole Zim module set (completion/`compinit`, fzf-tab, syntax highlighting,
  autosuggestions, history-substring-search, autopair, magic-enter, wd, bat), plus the
  `fzf` key bindings, `zoxide`, lazy `pyenv`, the zellij check, and the hourly
  `~/.config` auto-pull. `fnm` is not deferred (see below).

Trade-off: for the brief moment the deferred queue is draining, tab-completion / syntax
highlighting / autosuggestions aren't active yet. In practice the queue drains faster than you can type a full command. To profile only the
eager path: `ZSH_PROFILE_STARTUP=1 zsh -i -c exit` (deferred work runs after the prompt,
so it won't show up in that zprof report).

## Files in this directory

1. **`.zshrc`** — the main configuration (eager + deferred sections described above).
1. **`.zshenv` / `.zprofile`** — environment for all shells / login shells. Homebrew
   (a static copy of `brew shellenv`) is initialized in `.zprofile`, so it's on `PATH`
   before `.zshrc` runs. `.zshenv` keeps `PATH` free of duplicates (`typeset -U`) and puts
   the pyenv shims first. `.zprofile` moves the shims to the front again after
   `path_helper` and Homebrew, so `python3` respects `.python-version`. fnm's node still
   comes before the shims.
1. **`git_aliases`** — Git command aliases (currently `g=git`), sourced eagerly.
1. **`functions/`** — custom functions (`note`, `editrc`, `c`, `lsf`, `cbn`,
   `compare2main`, `newz`), autoloaded eagerly so they're available immediately.
1. **`IGNORE_functions/`** — work-specific functions, autoloaded the same way if present.
1. **`.IGNORE_*`** — uncommitted local/work files (credentials, work aliases). Sourced in
   the deferred phase. Git-ignored; never committed.

## What the `.zshrc` sets up

#### Environment
* **PATH**: `~/.local/bin`, Go (`$GOPATH/bin`), Bun (`$BUN_INSTALL/bin`), pnpm
  (`$PNPM_HOME`). All paths are `$HOME`-relative so they work on any machine.
* **Editor**: `EDITOR` and `VISUAL` are `cursor --wait`. Fallback: `nvim`, then `vi`,
  when the Cursor CLI is missing or the session is over SSH.
* **History**: `~/.zsh_history`, 50,000 entries in memory and on disk. Options:
  `HIST_IGNORE_ALL_DUPS`, `EXTENDED_HISTORY` (timestamps), `SHARE_HISTORY` (tabs share
  history), `HIST_IGNORE_SPACE` (a leading space skips saving), `HIST_REDUCE_BLANKS`,
  `HIST_VERIFY` (`!!` loads the line for review instead of running it).
* **Prompt**: `starship` (`STARSHIP_CONFIG=~/.config/starship/starship.toml`).

#### Aliases
* General: `z=zellij`, `y=yarn`, `yin='yarn install'`, `nvm=fnm`, `ls`/`la`/`ll`/`lr`/`lra`
  → [eza](https://github.com/eza-community/eza), `grep --color`, `ghpc='gh pr checkout -f'`.
* Git: sourced from `git_aliases`.

#### Functions
* Custom functions from `functions/` and `IGNORE_functions/` are added to `fpath` and
  autoloaded eagerly (fork-free glob — no subshells).

#### Lazy / deferred loading
* **Zim modules**: all loaded in the deferred phase (see [the zim README](../zim/README.md)).
* **fnm**: node version manager, initialized **eagerly** with `--use-on-cd`
  (auto-switches node on `cd`): in `.zprofile` for login shells, and in `.zshrc` for
  interactive non-login shells. It is not deferred, because agent shells (`zsh -c`)
  never reach the deferred phase.
* **[zoxide](https://github.com/ajeetdsouza/zoxide)**: frecency-based directory jumping,
  initialized deferred with `--cmd cd`. `cd path` still behaves normally; `cd <partial>`
  jumps to the best-matching visited dir, and `cdi` opens an fzf picker. (`z` stays
  aliased to zellij.)
* **pyenv**: registered with `lazyload` — only initializes on first `pyenv` use. The
  shims are on `PATH` from `.zshenv`, so `python3` follows `.python-version` before that.

## How to use
1. **Clone**: `git clone https://github.com/dhoeppne/.config.git ~/.config`
1. **Default shell**: ensure Zsh is installed and set as your shell.
1. **Dependencies**: install [Homebrew](https://brew.sh/), then the tools used here —
   `brew install starship eza bat fzf fnm zoxide zellij` (zellij self-installs on first
   run if missing). Zim and its modules install themselves on first launch.
1. **Symlink**: `ln -s ~/.config/zshrc/.zshrc ~/.zshrc`
1. **Local/work config**: add `.IGNORE_*` files for anything sensitive, e.g.
   `.IGNORE_credentials`, `.IGNORE_work_zshrc`, and work functions under `IGNORE_functions/`.

Reload the shell after changes with `newz` (re-execs zsh).
