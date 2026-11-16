# Runs for *every* zsh (login, interactive, script). Keep it minimal and fast.

# Keep PATH free of duplicates in every shell. With -U, prepending an entry that
# is already present moves it to the front (zsh keeps the first occurrence).
typeset -U path PATH

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
# The shims move to the front when they are missing or when /usr/bin or a
# Homebrew bin folder comes before them (a PATH inherited from an older login
# shell or a GUI app can have that order). Otherwise the inherited order stays,
# so fnm's node and ~/.local/bin keep their place ahead of the shims.
# Login shells repeat this in ~/.zprofile: /etc/zprofile (path_helper) and the
# Homebrew block run after this file and push the shims back behind /usr/bin.
export PYENV_ROOT="${HOME}/.pyenv"
() {
  local s=$PYENV_ROOT/shims d
  [[ -d $s ]] || return 0
  for d in /usr/bin /usr/local/bin /opt/homebrew/bin; do
    # (ie) = index of the exact entry, or $#path+1 when it is missing.
    (( ${path[(ie)$d]} < ${path[(ie)$s]} )) && { path=($s $path); return 0; }
  done
  (( ${path[(ie)$s]} <= $#path )) || path=($s $path)
}

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
