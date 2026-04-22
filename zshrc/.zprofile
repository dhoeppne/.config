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
