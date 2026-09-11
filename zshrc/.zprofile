# Runs for login shells. macOS treats every GUI-launched shell (Cursor,
# Terminal.app, WezTerm, VSCode, etc.) as a login shell, so this is the
# earliest reliable point to populate PATH for everything that follows.
#
# `brew shellenv` sets PATH, MANPATH, INFOPATH, HOMEBREW_PREFIX, etc. Doing
# this here (instead of from ~/.zshrc) ensures `fzf`, `fnm`, `brew`, and
# other Homebrew tools resolve before ~/.zshrc tries to use them.
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

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
fi
