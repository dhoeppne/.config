# ~/.zshrc  (symlinked from ~/.config/zshrc/.zshrc)
#
# Strategy: get an instantly-usable prompt on screen, then load everything heavy
# in the background. The EAGER section below is all that runs before the first
# prompt paints (shell options, PATH, aliases, functions, starship). Everything
# else is queued with `zsh-defer` and runs once zle goes idle — so you can start
# typing immediately and the rest (Zim plugins, completion, fnm, fzf) streams in
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
setopt HIST_IGNORE_ALL_DUPS          # drop older dupes when a new dupe is added
bindkey -e                           # emacs keymap for line editing
WORDCHARS=${WORDCHARS//[\/]}         # treat "/" as a word boundary (Ctrl-W)
ZSH_AUTOSUGGEST_MANUAL_REBIND=1      # autosuggestions is last; skip per-precmd rebind

# Completion search path. Must be populated BEFORE the deferred compinit runs so
# these completions get picked up. `typeset -gU` keeps fpath deduped across
# `exec zsh` (the `newz` reload function).
typeset -gU fpath
[[ -d /Users/david/.zsh/completions ]] && fpath=(/Users/david/.zsh/completions $fpath)
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

export EDITOR='cursor'
export STARSHIP_CONFIG=~/.config/starship/starship.toml

# fnm eagerly (node on PATH). Interactive shells reach here but skip ~/.zprofile
# (login-only), so this covers Claude Code's Bash tool; guarded so a full login
# terminal that already ran the ~/.zprofile copy doesn't eval it twice.
if [[ -z "$FNM_MULTISHELL_PATH" ]] && command -v fnm >/dev/null; then
    eval "$(fnm env --version-file-strategy=recursive --use-on-cd --shell zsh)"
    export YARN_GLOBAL_FOLDER="$FNM_MULTISHELL_PATH/yarn-global"
    export YARN_PREFIX="$FNM_MULTISHELL_PATH"
fi

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
eval "$(starship init zsh)"

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
  MAGIC_ENTER_GIT_COMMAND='git status -u .'
  MAGIC_ENTER_OTHER_COMMAND='ls -lha .'
  zstyle ':zshzoo:magic-enter' command 'ls -lha .'
  zstyle ':zshzoo:magic-enter' git-command 'g status -u .'

  # Lazy env managers (functions provided by the Zim lazy-load modules above):
  # pyenv/rustup only initialise on first actual use.
  command -v lazyload   >/dev/null && lazyload pyenv -- 'eval "$(pyenv init -)"'
  command -v _lazy_load >/dev/null && _lazy_load rustup "rustup completions zsh > ~/.zfunc/_rustup"

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

# 4) fnm (a faster nvm): initialized eagerly in ~/.zprofile instead of here, so
#    non-interactive/agent shells (Cursor, Claude Code) get node on PATH too.
#    zsh-defer only fires on ZLE idle, which never happens for `zsh -c`.

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
