# Runs for login shells. macOS treats every GUI-launched shell (Cursor,
# Terminal.app, WezTerm, VSCode, etc.) as a login shell, so this is the
# earliest reliable point to populate PATH for everything that follows.
#
# Homebrew env: a static copy of `brew shellenv zsh` (PATH, FPATH, MANPATH,
# INFOPATH, HOMEBREW_*). Doing this here (instead of from ~/.zshrc) ensures
# `fzf`, `fnm`, `brew`, and other Homebrew tools resolve before ~/.zshrc tries
# to use them. Static because `eval "$(brew shellenv)"` costs 60-120 ms (brew is
# a bash script). Apple Silicon prefix first, then Intel. Unlike brew's output,
# the bin/sbin entries are moved to the front instead of added again, so nested
# login shells do not grow PATH. If `brew shellenv` ever adds a variable, copy
# it here.
() {
  local p
  if [[ -x /opt/homebrew/bin/brew ]]; then p=/opt/homebrew
  elif [[ -x /usr/local/bin/brew ]]; then p=/usr/local
  else return
  fi
  export HOMEBREW_PREFIX=$p
  export HOMEBREW_CELLAR=$p/Cellar
  if [[ $p == /usr/local ]]; then export HOMEBREW_REPOSITORY=$p/Homebrew
  else export HOMEBREW_REPOSITORY=$p
  fi
  fpath=($p/share/zsh/site-functions ${fpath:#$p/share/zsh/site-functions})
  export FPATH
  path=($p/bin $p/sbin ${path:#$p/(bin|sbin)})
  [[ -z ${MANPATH-} ]] || { export MANPATH="${MANPATH%"${MANPATH##*[!:]}"}"; export MANPATH=":${MANPATH#"${MANPATH%%[!:]*}"}"; }
  [[ :${INFOPATH-}: == *:$p/share/info:* ]] || export INFOPATH="$p/share/info:${INFOPATH:-}"
}

# pyenv shims back to the front. ~/.zshenv put them first, but /etc/zprofile
# (path_helper) and the Homebrew block above both run later and push them behind
# /usr/bin and Homebrew, so `python3` ignored .python-version in login shells.
# fnm runs next and prepends node, so node still comes first. `typeset -U` in
# ~/.zshenv removes the old entry.
[[ -d ${PYENV_ROOT:=$HOME/.pyenv}/shims ]] && path=($PYENV_ROOT/shims $path)

# fnm: put node on PATH eagerly here (login shells) so non-interactive/agent
# shells spawned by IDEs (Cursor, Claude Code) get node too — not just
# interactive terminals. This must NOT be deferred: zsh-defer only fires on
# ZLE idle, which never happens for one-off `zsh -c` command execution.
if [[ -z "$_FNM_ENV_LOADED" ]] && command -v fnm >/dev/null; then
    eval "$(fnm env --version-file-strategy=recursive --use-on-cd --shell zsh)"
    # Must NOT be exported: children inherit FNM_MULTISHELL_PATH, and guarding on
    # that skipped the eval — and with it the chpwd hook — in every nested shell.
    typeset -g _FNM_ENV_LOADED=1
    export YARN_GLOBAL_FOLDER="$FNM_MULTISHELL_PATH/yarn-global"
    export YARN_PREFIX="$FNM_MULTISHELL_PATH"

    # Start-folder version: fnm 1.39 (tested 2026-11-16) already switches to the
    # version pinned for $PWD inside `fnm env --use-on-cd`, and prints
    # "Using Node vX" to stderr. Older fnm only linked the default version (its
    # chpwd hook fires on cd, not at init), so a shell opened in a project stayed
    # on default. The `fnm use` below is the fallback for older fnm. On fnm 1.39
    # it changes nothing (--silent-if-unchanged). Delete this block once every
    # machine runs fnm 1.39 or newer.
    # Only fork `fnm use` when a version file exists here or in a parent
    # (fnm's recursive strategy + resolve-engines read these three files).
    # Pure-zsh walk, no forks: saves ~10 ms everywhere else (e.g. ~).
    () {
        local d=$PWD
        until [[ -e $d/.node-version || -e $d/.nvmrc || -e $d/package.json ]]; do
            [[ $d == /?* ]] || return 0   # stop at / (or a non-absolute PWD)
            d=${d:h}
        done
        fnm use --silent-if-unchanged 2>/dev/null || true
    }
fi
