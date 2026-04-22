local wezterm = require('wezterm')

local M = {}

-- How often to run the remote check, in seconds. Stamp lives in /tmp so it
-- resets across reboots.
local CHECK_INTERVAL_SECONDS = 60 * 60 -- 1 hour
local STAMP_FILE = '/tmp/.config-last-check'

function M.setup_git_check_command()
  local check_script = string.format([[
    set -e
    STAMP=%q
    INTERVAL=%d
    if [ -f "$STAMP" ]; then
      last=$(stat -f %%m "$STAMP" 2>/dev/null || echo 0)
      now=$(date +%%s)
      if [ $((now - last)) -lt $INTERVAL ]; then
        exit 0
      fi
    fi
    cd ~/.config || exit 0
    git fetch --quiet origin main 2>/dev/null || exit 0
    touch "$STAMP"
    if [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ]; then
      exit 0
    fi
    echo ".config has updates on origin/main. Pull now? (y/n)"
    read -r answer
    [ "$answer" = "y" ] || exit 0
    git pull --ff-only origin main
    echo "Restarting WezTerm to pick up changes..."
    wezterm cli spawn --new-window -- zsh
    wezterm cli kill-pane
  ]], STAMP_FILE, CHECK_INTERVAL_SECONDS)

  return { 'zsh', '-c', check_script }
end

function M.run_update_check(window, pane)
  window:perform_action(
    wezterm.action({ SpawnCommandInNewTab = {
      args = M.setup_git_check_command(),
    } }),
    pane
  )
end

function M.setup_hooks()
  wezterm.on('gui-startup', function(cmd)
    local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
    M.run_update_check(window, pane)
  end)

  wezterm.on('window-config-reloaded', function(window, pane)
    M.run_update_check(window, pane)
  end)
end

return M
