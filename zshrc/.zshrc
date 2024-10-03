## ENABLE PROFILING
if [ -n "${ZSH_PROFILE_STARTUP:+x}" ]
then
    zmodload zsh/zprof
fi

# Start configuration added by Zim install {{{
#
# User configuration sourced by interactive shells
#

# -----------------
# Zsh configuration
# -----------------

#
# History
#

# Remove older command from the history if a duplicate is to be added.
setopt HIST_IGNORE_ALL_DUPS

#
# Input/output
#

# Set editor default keymap to emacs (`-e`) or vi (`-v`)
bindkey -v

# Prompt for spelling correction of commands.
#setopt CORRECT

# Customize spelling correction prompt.
#SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '

# Remove path separator from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

# -----------------
# Zim configuration
# -----------------

# Use degit instead of git as the default tool to install and update modules.
#zstyle ':zim:zmodule' use 'degit'

# --------------------
# Module configuration
# --------------------

#
# zsh-autosuggestions
#

# Disable automatic widget re-binding on each precmd. This can be set when
# zsh-users/zsh-autosuggestions is the last module in your ~/.zimrc.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Customize the style that the suggestions are shown with.
# See https://github.com/zsh-users/zsh-autosuggestions/blob/master/README.md#suggestion-highlight-style
#ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'

# ------------------
# Initialize modules
# ------------------

ZIM_CONFIG_FILE=$HOME/.config/zim/.zimrc
# i don't bother creating a zdotdir as all my config is in the .zimrc in this repo
ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
# Download zimfw plugin manager if missing.
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( ${+commands[curl]} )); then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  else
    mkdir -p ${ZIM_HOME} && wget -nv -O ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  fi
fi
# Install missing modules, and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi
# Initialize modules.
source ${ZIM_HOME}/init.zsh

# ------------------------------
# Post-init module configuration
# ------------------------------

#
# zsh-history-substring-search
#

zmodload -F zsh/terminfo +p:terminfo
# Bind ^[[A/^[[B manually so up/down works both before and after zle-line-init
for key ('^[[A' '^P' ${terminfo[kcuu1]}) bindkey ${key} history-substring-search-up
for key ('^[[B' '^N' ${terminfo[kcud1]}) bindkey ${key} history-substring-search-down
for key ('k') bindkey -M vicmd ${key} history-substring-search-up
for key ('j') bindkey -M vicmd ${key} history-substring-search-down
unset key
# }}} End configuration added by Zim install

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH=/usr/local/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"

# magic-enter defaults
MAGIC_ENTER_GIT_COMMAND='git status -u .'
MAGIC_ENTER_OTHER_COMMAND='ls -lh .'

source <(fzf --zsh)

export GOPATH=$HOME/go
export PATH=$PATH:$HOME/go/bin

# load a faster nvm
alias nvm='fnm'
eval "$(fnm env --version-file-strategy=recursive --use-on-cd --shell zsh)"

# Check if zellij is installed, and if not, install it using Homebrew
if ! command -v zellij &> /dev/null; then
    echo 'zellij is not installed. Installing...'
    brew install zellij
fi

# load zellij
alias z=zellij
alias c=code
alias yin='yarn install'

# load git aliases
source $HOME/.config/zshrc/git_aliases

export EDITOR='nvim'

# lazy load near end of file
lazy_load_func() {
    unset -f lazy_load_func
    # add our local functions dir to the fpath
    local funcs=$HOME/.config/zshrc/functions
    local work_funcs=$HOME/.config/zshrc/ignore_functions

    # FPATH is already tied to fpath, but this adds
    # a uniqueness constraint to prevent duplicate entries
    typeset -TUg +x FPATH=$funcs:$FPATH fpath
    typeset -TUg +x FPATH=$work_funcs:$FPATH fpath

    # Now autoload them
    if [[ -d $funcs ]]; then
        autoload ${=$(cd "$funcs" && echo *)}
    fi
    if [[ -d $work_funcs ]]; then
        autoload ${=$(cd "$work_funcs" && echo *)}
    fi
}; lazy_load_func

# source everything we don't want to commit
# keep this near the end to make troubleshooting easier
# # ie credentials and work stuff
if [[ -d $HOME/.config/zshrc/.IGNORE_* ]] ; then
    for file in $HOME/.config/zshrc/.IGNORE_*; do
        source $file
    done
fi

# use qooman/lazy-load to load slow env managers
export SDKMAN_DIR="$HOME/.sdkman"
if [[ "$SHELL" =~ "zsh" ]] && command -v lazyload >/dev/null; then
  lazyload sdk -- 'source "$SDKMAN_DIR/bin/sdkman-init.sh"'

  if command -v pyenv 1>/dev/null 2>&1; then
    lazyload pyenv -- 'eval "$(pyenv init -)"'
  fi

  # Set PATH, MANPATH, etc., for Homebrew.
  lazyload brew -- 'eval "$(/opt/homebrew/bin/brew shellenv)"'
fi

# use goarano/zsh-lazy-load to lazy load some completions
_lazy_load kubectl "[[ $commands[kubectl] ]] && source <(kubectl completions zsh)"
_lazy_load rustup "rustup completions zsh > ~/.zfunc/_rustup"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f $HOME/.config/p10k/.p10k.zsh ]] || source $HOME/.config/p10k/.p10k.zsh

## PRINT PROFILING RESULTS
if [ -n "${ZSH_PROFILE_STARTUP:+x}" ]
then
    zprof
fi
