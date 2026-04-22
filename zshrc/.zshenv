# Runs for *every* zsh (login, interactive, script). Keep it minimal and fast.

# Point git at the XDG-style config that lives in this repo, so `git pull` is
# the only thing needed to update global git config on any machine.
export GIT_CONFIG_GLOBAL="${HOME}/.config/git/config"

# Rust toolchain (adds ~/.cargo/bin to PATH)
[ -f "${HOME}/.cargo/env" ] && . "${HOME}/.cargo/env"
