#!/usr/bin/env bash
#
# Idempotent bootstrap for a fresh (or existing) macOS machine.
#
# Run from anywhere:
#   bash ~/.config/install.sh
#
# Safe to run any number of times; each step checks before acting.

set -euo pipefail

CONFIG_DIR="${HOME}/.config"
ZSHRC_DIR="${CONFIG_DIR}/zshrc"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
skip() { printf '\033[1;32m  ok\033[0m %s\n' "$*"; }

ensure_symlink() {
    local target="$1" link="$2"

    if [[ -L "$link" && "$(readlink "$link")" == "$target" ]]; then
        skip "symlink already in place: $link"
        return 0
    fi

    if [[ -e "$link" && ! -L "$link" ]]; then
        local backup="${link}.pre-xdg.backup.$(date +%s)"
        log "backing up existing $link -> $backup"
        mv "$link" "$backup"
    elif [[ -L "$link" ]]; then
        rm -f "$link"
    fi

    log "linking $link -> $target"
    ln -snf "$target" "$link"
}

# ---------------------------------------------------------------------------
# 1. Homebrew
# ---------------------------------------------------------------------------
if [[ ! -x /opt/homebrew/bin/brew && ! -x /usr/local/bin/brew ]]; then
    log "installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    skip "Homebrew already installed"
fi

# Make sure this script's remaining steps can see brew.
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi

# ---------------------------------------------------------------------------
# 2. brew bundle (packages declared in ./Brewfile)
# ---------------------------------------------------------------------------
if [[ -f "${CONFIG_DIR}/Brewfile" ]]; then
    log "running brew bundle"
    brew bundle --file="${CONFIG_DIR}/Brewfile"
else
    skip "no Brewfile found, skipping brew bundle"
fi

# ---------------------------------------------------------------------------
# 3. Shell rc symlinks
# ---------------------------------------------------------------------------
ensure_symlink "${ZSHRC_DIR}/.zshrc"    "${HOME}/.zshrc"
ensure_symlink "${ZSHRC_DIR}/.zshenv"   "${HOME}/.zshenv"
ensure_symlink "${ZSHRC_DIR}/.zprofile" "${HOME}/.zprofile"

# ---------------------------------------------------------------------------
# 4. Git config migration
#
# Global git config lives at ~/.config/git/config (the repo) and is selected
# via GIT_CONFIG_GLOBAL set in .zshenv. Any pre-existing ~/.gitconfig would
# silently take precedence for writes, so archive it.
# ---------------------------------------------------------------------------
if [[ -f "${HOME}/.gitconfig" && ! -L "${HOME}/.gitconfig" ]]; then
    backup="${HOME}/.gitconfig.pre-xdg.backup.$(date +%s)"
    log "archiving ${HOME}/.gitconfig -> ${backup}"
    mv "${HOME}/.gitconfig" "${backup}"
else
    skip "~/.gitconfig already clean"
fi

# Work-only git overrides (email, GHE tokens, etc.) live in an uncommitted
# file that the committed config pulls in via [include]. Scaffold a template
# so `git commit` works out of the box; user fills in real values.
work_config="${CONFIG_DIR}/git/IGNORE_work_config"
if [[ ! -f "${work_config}" ]]; then
    log "scaffolding ${work_config} (fill in your work email)"
    cat >"${work_config}" <<'EOF'
# Work-only git config. Gitignored via `*IGNORE*` in ~/.config/.gitignore.
# Safe for work email, company credential helpers, GHE settings, etc.
[user]
	email = YOUR.EMAIL@example.com
EOF
else
    skip "${work_config} already present"
fi

# ---------------------------------------------------------------------------
# 5. Bun
# ---------------------------------------------------------------------------
if [[ ! -d "${HOME}/.bun" ]]; then
    log "installing bun"
    curl -fsSL https://bun.sh/install | bash
else
    skip "bun already installed"
fi

# ---------------------------------------------------------------------------
# 6. Node via fnm
# ---------------------------------------------------------------------------
if command -v fnm >/dev/null 2>&1; then
    current_node="$(fnm current 2>/dev/null || echo none)"
    if [[ "${current_node}" == "none" || -z "${current_node}" ]]; then
        log "installing latest LTS node via fnm"
        fnm install --lts
        fnm default "$(fnm current)"
    else
        skip "fnm already has a default node (${current_node})"
    fi
fi

# ---------------------------------------------------------------------------
# 7. Zim (zsh plugin manager) — self-installs from ~/.zshrc, but bootstrap
#    the download here so the first interactive shell starts clean.
# ---------------------------------------------------------------------------
ZIM_HOME="${HOME}/.zim"
if [[ ! -e "${ZIM_HOME}/zimfw.zsh" ]]; then
    log "installing zimfw"
    mkdir -p "${ZIM_HOME}"
    curl -fsSL --create-dirs -o "${ZIM_HOME}/zimfw.zsh" \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
else
    skip "zimfw already installed"
fi

log "bootstrap complete. restart your shell."
