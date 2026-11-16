# ~/.zshrc  (symlinked from ~/.config/zshrc/.zshrc)
#
# Strategy: get an instantly-usable prompt on screen, then load everything heavy
# in the background. The EAGER section below is all that runs before the first
# prompt paints (shell options, PATH, aliases, functions, starship). Everything
# else is queued with `zsh-defer` and runs once zle goes idle — so you can start
# typing immediately and the rest (Zim plugins, completion, fzf) streams in
# a few milliseconds later.

export XDG_CONFIG_HOME=$HOME/.config

# ============================================================================
# Profiling  (opt-in: `ZSH_PROFILE_STARTUP=1 zsh -i -c exit`)
# Only EAGER startup is captured here. Deferred work runs after the first prompt,
# so it does not appear in this zprof report (that's expected).
# ============================================================================
if [[ -n ${ZSH_PROFILE_STARTUP:+x} ]]; then
  zmodload zsh/zprof
fi

# ============================================================================
# EAGER · core shell behaviour
# ============================================================================
# History. Without these, macOS /etc/zshrc limits apply (2000 in memory, 1000 saved).
HISTFILE=$HOME/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS          # drop older dupes when a new dupe is added
setopt EXTENDED_HISTORY              # save start time and duration of each command
setopt SHARE_HISTORY                 # write each command at once; tabs read each other's
setopt HIST_IGNORE_SPACE             # a command with a leading space is not saved
setopt HIST_REDUCE_BLANKS            # remove extra blanks before saving
setopt HIST_VERIFY                   # `!!` and other expansions load the line, not run it
bindkey -e                          # emacs keymap for line editing
WORDCHARS=${WORDCHARS//[\/]}         # treat "/" as a word boundary (Ctrl-W)
ZSH_AUTOSUGGEST_MANUAL_REBIND=1      # autosuggestions is last; skip per-precmd rebind

# Completion search path. Must be populated BEFORE the deferred compinit runs so
# these completions get picked up. `typeset -gU` keeps fpath deduped across
# `exec zsh` (the `newz` reload function).
typeset -gU fpath
[[ -d $HOME/.zsh/completions ]]        && fpath=($HOME/.zsh/completions $fpath)
[[ -d $HOME/.docker/completions ]]     && fpath=($HOME/.docker/completions $fpath)

# ============================================================================
# EAGER · PATH & environment
# ============================================================================
export PATH="$HOME/.local/bin:$PATH"

export GOPATH=$HOME/go
export PATH="$PATH:$HOME/go/bin"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Editor: Cursor (waits until the tab closes, so `git commit` works). Falls back to
# nvim, then vi, when the Cursor CLI is missing or the session is over SSH.
# `command -v`, not $commands: after the `rehash` in `fnm env` (~/.zprofile), a
# $commands lookup rescans every PATH folder (~5 ms).
if [[ -z $SSH_CONNECTION ]] && command -v cursor >/dev/null; then
  export EDITOR='cursor --wait'
elif command -v nvim >/dev/null; then
  export EDITOR=nvim
else
  export EDITOR=vi
fi
export VISUAL=$EDITOR
export STARSHIP_CONFIG=~/.config/starship/starship.toml

# fnm eagerly (node on PATH). Interactive shells reach here but skip ~/.zprofile
# (login-only), so this covers Claude Code's Bash tool; guarded so a full login
# terminal that already ran the ~/.zprofile copy doesn't eval it twice.
if [[ -z "$_FNM_ENV_LOADED" ]] && command -v fnm >/dev/null; then
    eval "$(fnm env --version-file-strategy=recursive --use-on-cd --shell zsh)"
    # Must NOT be exported: children inherit FNM_MULTISHELL_PATH, and guarding on
    # that skipped the eval — and with it the chpwd hook — in every nested shell.
    typeset -g _FNM_ENV_LOADED=1
    export YARN_GLOBAL_FOLDER="$FNM_MULTISHELL_PATH/yarn-global"
    export YARN_PREFIX="$FNM_MULTISHELL_PATH"

    # `fnm env` only links the *default* version and registers the chpwd hook —
    # it never reads .node-version for the dir the shell STARTS in. Back when
    # this was deferred, zsh-defer's PWD restore incidentally fired chpwd, so the
    # pinned version got picked up by accident. Eager init lost that, leaving new
    # tabs on the default node instead of the project's, until you ran `fnm use`
    # or re-`cd`'d. Apply the pinned version explicitly instead.
    # (pnpm comes from Homebrew, not per-version corepack shims, so it exists
    # under every node version and self-switches to `packageManager`.)
    # Only fork `fnm use` when a version file exists here or in a parent (same
    # pure-zsh walk as in ~/.zprofile).
    () {
        local d=$PWD
        until [[ -e $d/.node-version || -e $d/.nvmrc || -e $d/package.json ]]; do
            [[ $d == /?* ]] || return 0   # stop at / (or a non-absolute PWD)
            d=${d:h}
        done
        fnm use --silent-if-unchanged 2>/dev/null || true
    }
fi

export SOPS_AGE_KEY_FILE="$HOME/Library/Application Support/sops/age/keys.txt"

# ============================================================================
# EAGER · aliases
# ============================================================================
alias z=zellij
alias p=pnpm
alias pin='pnpm install'
alias nvm='fnm'
alias ls='eza -F --colour=auto --icons=auto'
alias la='eza -F --colour=auto --icons=auto --all'
alias ll='eza -F --colour=auto --icons=auto --oneline'
alias lr='eza -F --colour=auto --oneline --icons=auto --recurse'
alias lra='eza -F --colour=auto --oneline --icons=auto --all --recurse'
alias grep='grep --color=auto'
alias ghpc='gh pr checkout -f'
alias ai='agentctl tui dev-mac'
source $HOME/.config/zshrc/git_aliases   # alias g=git

# ============================================================================
# EAGER · personal autoloaded functions  (note, editrc, c, lsf, cbn, …)
# Fork-free: basenames are globbed straight off disk (no `cd`/`echo` subshells).
# Work-specific functions live in IGNORE_functions/ and are picked up if present.
# ============================================================================
() {
  local d fns
  for d in $HOME/.config/zshrc/functions $HOME/.config/zshrc/IGNORE_functions; do
    [[ -d $d ]] || continue
    fpath=($d $fpath)
    fns=($d/*(N:t))
    (( ${#fns} )) && autoload -Uz $fns
  done
}

# ============================================================================
# EAGER · prompt, then the deferral tool
# ============================================================================
# Starship init comes from a cache file. That skips two forks per shell
# (~45 ms): `starship init` and the `starship prompt --continuation` call that
# fills PROMPT2 (its value is baked into the cache). The cache is rebuilt when:
#  - it is missing,
#  - the starship binary or starship.toml is newer than it,
#  - the starship path changed (the first line records the starship path and
#    its resolved target, which holds the version for Homebrew installs).
# The path comes from a glob over $path, not $commands[starship]: the `rehash`
# in `fnm env` empties the command table, and a $commands lookup then rescans
# every PATH folder (~5 ms). The glob gives the same first match.
# The function only refreshes the file. `source` stays at top level so the init
# runs in global scope.
_zshrc_starship_cache=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/starship-init.zsh
() {
  local -a found=( ${^path}/starship(N-*) )
  local bin=$found[1] cache=$_zshrc_starship_cache
  [[ -n $bin ]] || { unset _zshrc_starship_cache; return 0; }
  local stamp="# starship-init-cache: $bin ${bin:A}" first=
  [[ -r $cache ]] && read -r first < $cache
  [[ $first == $stamp && ! $bin -nt $cache && ! $STARSHIP_CONFIG -nt $cache ]] && return 0
  local init p2
  init=$("$bin" init zsh --print-full-init) || { unset _zshrc_starship_cache; return 0; }
  p2=$(STARSHIP_SHELL=zsh "$bin" prompt --continuation) &&
    init=${init/PROMPT2=\"\$\(*prompt --continuation\)\"/PROMPT2=\'${p2//\'/\'\\\'\'}\'}
  mkdir -p ${cache:h}
  print -r -- "$stamp"$'\n'"$init" >| $cache.$$ && mv -f $cache.$$ $cache
}
[[ -n $_zshrc_starship_cache && -r $_zshrc_starship_cache ]] && source $_zshrc_starship_cache
unset _zshrc_starship_cache

# Zim bootstrap. The checks are cheap and kept eager so `init.zsh` is guaranteed
# fresh; only the expensive `source init.zsh` itself is deferred (below).
ZIM_CONFIG_FILE=$HOME/.config/zim/.zimrc
ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
# Download zimfw if missing (first run on a new machine).
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( ${+commands[curl]} )); then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  else
    mkdir -p ${ZIM_HOME} && wget -nv -O ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  fi
fi
# Rebuild init.zsh when .zimrc changes. Compare against the real config file
# ($ZIM_CONFIG_FILE), not ~/.zimrc which doesn't exist here.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZIM_CONFIG_FILE} ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi

# Load zsh-defer itself eagerly (tiny). Everything below rides on it.
source ${ZIM_HOME}/modules/zsh-defer/zsh-defer.plugin.zsh

# ============================================================================
# DEFERRED · everything heavy, in order, after the first prompt
# ============================================================================

# 1) All Zim modules: completion/compinit, fzf-tab, fast-syntax-highlighting,
#    autosuggestions, history-substring-search, autopair, magic-enter, wd, bat…
zsh-defer source ${ZIM_HOME}/init.zsh

# 2) Config that needs those modules to already be loaded.
_zshrc_after_zim() {
  # history-substring-search: bind up/down (widgets exist only after the module).
  zmodload -F zsh/terminfo +p:terminfo
  local key
  for key ('^[[A' '^P' ${terminfo[kcuu1]}) bindkey ${key} history-substring-search-up
  for key ('^[[B' '^N' ${terminfo[kcud1]}) bindkey ${key} history-substring-search-down

  # fzf-tab / completion styling. Set after Zim's completion module so ours win.
  zstyle ':completion:*:git-checkout:*' sort false
  zstyle ':completion:*:descriptions' format '[%d]'
  zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
  zstyle ':completion:*' menu no
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
  zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
  zstyle ':fzf-tab:*' use-fzf-default-opts yes
  zstyle ':fzf-tab:*' switch-group '<' '>'

  # magic-enter: bare Enter runs git status (in a repo) or a dir listing.
  zstyle ':zshzoo:magic-enter' command 'ls -lha .'
  zstyle ':zshzoo:magic-enter' git-command 'g status -u .'

  # Lazy pyenv (`lazyload` comes from the qoomon/zsh-lazyload Zim module):
  # `pyenv init` runs only on first actual use.
  command -v lazyload >/dev/null && lazyload pyenv -- 'eval "$(pyenv init -)"'

  # bun completions, if bun is installed.
  [[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"

  unset -f _zshrc_after_zim
}
zsh-defer _zshrc_after_zim

# 3) fzf key bindings & completion (run the subprocess lazily, not at parse time).
zsh-defer -c 'source <(fzf --zsh)'

# 3b) zoxide: frecency-based `cd`. `--cmd cd` enhances `cd` itself (normal `cd path`
#     still works; frecency kicks in otherwise, `cdi` opens an fzf picker) so the
#     `z` alias stays pointed at zellij.
zsh-defer -c 'eval "$(zoxide init zsh --cmd cd)"'

# 4) fnm (a faster nvm) is NOT deferred. It runs eagerly in two places:
#    ~/.zprofile for login shells, and the EAGER PATH section above for
#    interactive non-login shells. `_FNM_ENV_LOADED` keeps it to one run per
#    shell. zsh-defer only fires on ZLE idle, which never happens for `zsh -c`.

# 5) Startup-only housekeeping.
_zshrc_housekeeping() {
  # Install zellij on a machine that doesn't have it yet.
  if ! command -v zellij >/dev/null; then
    print 'zellij is not installed. Installing…'
    brew install zellij
  fi

  # Source uncommitted local/work files last (credentials, work aliases): .IGNORE_*
  local f
  for f in $HOME/.config/zshrc/.IGNORE_*(N); do source $f; done

  # Prune fnm's stale multishell links (it never does), at most daily, detached:
  # a sweep of a large backlog takes ~1s. `(Nmh-24)` matches only if the stamp was
  # touched within 24h, so the common case costs no forks. Must stay above the
  # early return below.
  local fnm_stamp=/tmp/.fnm-prune-last-run
  local -a fnm_fresh=( $fnm_stamp(Nmh-24) )
  if (( ! $#fnm_fresh )); then
    touch "$fnm_stamp"
    ( fnm-prune -q ) &!
  fi

  # Auto-update ~/.config from origin/main, at most hourly, in the background.
  local stamp=/tmp/.config-last-check interval=3600
  if [[ -f $stamp ]]; then
    local last=$(stat -f %m "$stamp" 2>/dev/null || echo 0) now=$(date +%s)
    (( now - last < interval )) && { unset -f _zshrc_housekeeping; return; }
  fi
  (
    cd ~/.config || return
    git fetch --quiet origin main 2>/dev/null || return
    touch "$stamp"
    [[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] && return
    git pull --ff-only origin main --quiet && print '.config updated from origin/main'
  ) &!
  unset -f _zshrc_housekeeping
}
zsh-defer _zshrc_housekeeping

# ============================================================================
# Profiling output  (true end of file)
# ============================================================================
if [[ -n ${ZSH_PROFILE_STARTUP:+x} ]]; then
  zprof
fi
