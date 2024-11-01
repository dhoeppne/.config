local wezterm = require('wezterm')

local M = {}

function M.setup_git_check_command()
    local check_script = [[
        cd ~/.config
        git remote update &>/dev/null
        UPSTREAM=${1:-'@{u}'}
        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse "$UPSTREAM")
        BASE=$(git merge-base @ "$UPSTREAM")

        if [ "$LOCAL" = "$REMOTE" ]; then
            # Up-to-date, do nothing
            exit 0
        elif [ "$LOCAL" = "$BASE" ]; then
            # Need to pull
            echo "Updates found in ~/.config, pulling changes..."
            git pull
            # Restart zsh to apply changes
            exec zsh
        fi
    ]]

    return {'zsh', '-c', check_script}
end

function M.setup_startup_hook()
    wezterm.on('gui-startup', function(cmd)
        local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
        pane:spawn(M.setup_git_check_command())
    end)
end

return M