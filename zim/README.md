# zim

[Zim](https://github.com/zimfw/zimfw) is the Zsh plugin manager. Modules are declared in
`.zimrc`; Zim compiles them into `~/.zim/init.zsh`.

> **Note on load order:** `init.zsh` is **not** sourced eagerly. The `.zshrc` sources
> `zsh-defer` first and then defers `init.zsh`, so all of the modules below load right
> after the first prompt paints rather than blocking startup. See
> [the zshrc README](../zshrc/README.md).

## Modules (in `.zimrc` order)

#### `romkatv/zsh-defer`
Defers execution of a command until the line editor is idle. This is the engine behind
the "instant prompt, load the rest in the background" setup — `.zshrc` sources its plugin
file directly and uses it to defer everything else.

#### `duration-info`
Displays the duration of the last command, for use in the prompt.

#### `zsh-users/zsh-completions`
Extra completion definitions for many commands and tools (added via `--fpath src`).

#### `MichaelAquilina/zsh-you-should-use`
Reminds you when an alias exists for a command you just typed in full.

#### `fdellwing/zsh-bat`
Integrates [bat](https://github.com/sharkdp/bat) as the pager / `man` colorizer.

#### `hlissner/zsh-autopair`
Auto-closes brackets and quotes as you type.

#### `romkatv/zsh-prompt-benchmark`
Benchmarks prompt latency (`zsh-prompt-benchmark`), useful for tuning.

#### `zsh-users/zsh-history-substring-search`
Search history by substring with the up/down arrows (bindings set in `.zshrc`).

#### `Aloxaf/fzf-tab`
Replaces the tab-completion menu with an fzf fuzzy picker (with eza-powered `cd` previews;
styling configured in `.zshrc`).

#### `zdharma-continuum/fast-syntax-highlighting`
Real-time syntax highlighting of the command line.

#### `qoomon/zsh-lazyload`
Provides `lazyload`, used in `.zshrc` to defer `pyenv` init until first use.

#### `goarano/zsh-lazy-load`
Provides `_lazy_load`, used in `.zshrc` to defer `rustup` completion generation until
first use.

#### `zshzoo/magic-enter`
Runs a default command on a bare Enter at an empty prompt (`git status` in a repo,
otherwise a directory listing).

#### `mfaerevaag/wd`
"Warp directory" — bookmark directories and jump to them by name.

#### `zsh-users/zsh-autosuggestions`
Suggests commands as you type, based on history. Kept last so it can skip per-precmd
widget rebinding (`ZSH_AUTOSUGGEST_MANUAL_REBIND=1` in `.zshrc`).

#### `completion`
Zim's built-in completion module. Runs `compinit` with a cached, compiled dumpfile for a
fast, correct completion system.

## How to use
1. **Install**: Zim and the modules above install themselves on first launch when you use
   the `.zshrc` from this repo. To do it manually: `zimfw install`.
1. **After editing `.zimrc`**: `init.zsh` is rebuilt automatically on next launch (the
   `.zshrc` compares `init.zsh` against `.zimrc`). To rebuild now: `zimfw build`.
1. **Reload**: restart the terminal, or run `newz` (re-execs zsh).
