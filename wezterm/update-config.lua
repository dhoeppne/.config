local wezterm = require('wezterm')

local M = {}

function M.setup_git_check_command()
  local check_script = [[
      cd ~/.config
      git fetch origin main
      if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ]; then
            echo "Changes found in remote config repo. Would you like to update now? (y/n)"
            read answer
            if [ "$answer" = "y" ]; then
                echo "Updating..."
          git pull origin main
          echo "Restarting WezTerm..."
          wezterm cli spawn --new-window wezterm
          wezterm cli quit --all
          exit 0
            else
                echo "Update skipped."
      fi
        else
            echo "No updates found."
        fi
  ]]

  return {'zsh', '-c', check_script}
end

function M.run_update_check(window, pane)
  window:perform_action(
      wezterm.action{SpawnCommandInNewTab = {
          args = M.setup_git_check_command(),
      }},
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