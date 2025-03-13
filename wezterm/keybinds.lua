local wezterm = require('wezterm')
local projects = require('projects')

local module = {}

local function move_pane(key, direction)
    return {
        key = key,
        mods = "LEADER",
        action = wezterm.action.ActivatePaneDirection(direction),
    }
end

local function resize_pane(key, direction)
    return {
        key = key,
        action = wezterm.action.AdjustPaneSize({ direction, 3 }),
    }
end

function module.create_keybinds()
    -- Lets set all our custom key bindings
    local key_bindings = {
        -- Make Option-Left equivalent to Alt-b which many line editors interpret as backward-word
        { key = "LeftArrow",  mods = "OPT", action = wezterm.action({ SendString = "\x1bb" }) },
        -- Make Option-Right equivalent to Alt-f; forward-word
        { key = "RightArrow", mods = "OPT", action = wezterm.action({ SendString = "\x1bf" }) },
        {
            key = "v",
            mods = "CTRL",
            action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
        },
        {
            key = "h",
            mods = "CTRL",
            action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
        },
        {
            key = "w",
            mods = "LEADER",
            action = wezterm.action.CloseCurrentPane({ confirm = false }),
        },
        {
            key = "p",
            mods = "LEADER",
            -- Present in to our project picker
            action = projects.choose_project(),
        },
        {
            key = "f",
            mods = "LEADER",
            -- Present a list of existing workspaces
            action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
        },
        -- Sends ESC + b and ESC + f sequence, which is used
        -- for telling your shell to jump back/forward.
        move_pane("j", "Down"),
        move_pane("k", "Up"),
        move_pane("l", "Left"),
        move_pane(";", "Right"),
        {
            -- When we push LEADER + R...
            key = "r",
            mods = "LEADER",
            -- Activate the `resize_panes` keytable
            action = wezterm.action.ActivateKeyTable({
                name = "resize_panes",
                -- Ensures the keytable stays active after it handles its
                -- first keypress.
                one_shot = false,
                -- Deactivate the keytable after a timeout.
                timeout_milliseconds = 1000,
            }),
        },
        {
            key = ",",
            mods = "SUPER",
            action = wezterm.action.SpawnCommandInNewTab({
                cwd = wezterm.home_dir,
                args = { "code", wezterm.config_file },
            }),
        },
        {
            mods = 'LEADER',
            key = 'm',
            action = wezterm.action.TogglePaneZoomState
        },

    }

    return key_bindings
end

function module.create_keytables()
    local key_tables = {
        resize_panes = {
            resize_pane("j", "Down"),
            resize_pane("k", "Up"),
            resize_pane("l", "Left"),
            resize_pane(";", "Right"),
        },
    }
    return key_tables
end

return module
