# Runs for *every* zsh (login, interactive, script). Keep it minimal and fast.

# Point git at the XDG-style config that lives in this repo, so `git pull` is
# the only thing needed to update global git config on any machine.
export GIT_CONFIG_GLOBAL="${HOME}/.config/git/config"

# Rust toolchain (adds ~/.cargo/bin to PATH)
[ -f "${HOME}/.cargo/env" ] && . "${HOME}/.cargo/env"

# pyenv shims on PATH so *every* shell — including non-interactive/agent shells
# (Cursor, Claude Code) — resolves the pyenv-managed python/pip and respects
# .python-version, instead of falling back to Homebrew's python. This is just a
# cheap PATH export; the full `pyenv init` shell function stays lazy in ~/.zshrc
# for interactive use (pyenv shell / rehash). Deferring pyenv there meant agents
# silently got the wrong python — the same bug class as fnm/node.
export PYENV_ROOT="${HOME}/.pyenv"
if [ -d "${PYENV_ROOT}/shims" ]; then
  case ":${PATH}:" in
    *":${PYENV_ROOT}/shims:"*) ;;
    *) export PATH="${PYENV_ROOT}/shims:${PATH}" ;;
  esac
fi

# Stable node fallback for shells that inherit PATH from a GUI app (Cursor,
# Claude desktop). Those apps capture PATH once at launch, including the launch
# shell's fnm multishell link. fnm-prune later deletes that link, and a plain
# `zsh -c` never re-runs `fnm env` (only this file runs), so node vanished.
# Appended last: a live fnm link earlier on PATH still wins.
_fnm_default="${HOME}/.local/share/fnm/aliases/default/bin"
if [ -d "${_fnm_default}" ]; then
  case ":${PATH}:" in
    *":${_fnm_default}:"*) ;;
    *) export PATH="${PATH}:${_fnm_default}" ;;
  esac
fi
unset _fnm_default
