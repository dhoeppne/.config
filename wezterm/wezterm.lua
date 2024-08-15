-- Pull in the wezterm API
local wezterm = require("wezterm")
local appearance = require("appearance")
local projects = require("projects")

-- This will hold the configuration.
local config = wezterm.config_builder()

config.set_environment_variables = {
	PATH = "/opt/homebrew/bin:" .. os.getenv("PATH"),
}
config.leader = { key = "F", mods = "CMD|SHIFT", timeout_milliseconds = 1000 }

-- This is where you actually apply your config choices
if appearance.is_dark() then
	config.color_scheme = "Tokyo Night"
else
	config.color_scheme = "Tokyo Night Day"
end

config.font = wezterm.font({ family = "Fira Code" })
config.font_size = 13.0

-- Slightly transparent and blurred background
config.window_background_opacity = 0.9
config.macos_window_background_blur = 30
config.window_decorations = "RESIZE"
-- Sets the font for the window frame (tab bar)
config.window_frame = {
	font = wezterm.font({ family = "Fira Code", weight = "Bold" }),
	font_size = 10,
}

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

-- Set a p10k style status in the menu bar
local function segments_for_right_status(window, pane)
	return {
		window:active_workspace(),
		wezterm.strftime("%a %b %-d %H:%M|%W"),
		wezterm.hostname(),
	}
end

wezterm.on("update-status", function(window, pane)
	local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
	local segments = segments_for_right_status(window, pane)

	local color_scheme = window:effective_config().resolved_palette
	-- Note the use of wezterm.color.parse here, this returns
	-- a Color object, which comes with functionality for lightening
	-- or darkening the colour (amongst other things).
	local bg = wezterm.color.parse(color_scheme.background)
	local fg = color_scheme.foreground

	-- Each powerline segment is going to be coloured progressively
	-- darker/lighter depending on whether we're on a dark/light colour
	-- scheme. Let's establish the "from" and "to" bounds of our gradient.
	local gradient_to, gradient_from = bg
	if appearance.is_dark() then
		gradient_from = gradient_to:lighten(0.2)
	else
		gradient_from = gradient_to:darken(0.2)
	end

	-- Yes, WezTerm supports creating gradients, because why not?! Although
	-- they'd usually be used for setting high fidelity gradients on your terminal's
	-- background, we'll use them here to give us a sample of the powerline segment
	-- colours we need.
	local gradient = wezterm.color.gradient(
		{
			orientation = "Horizontal",
			colors = { gradient_from, gradient_to },
		},
		#segments -- only gives us as many colours as we have segments.
	)

	-- We'll build up the elements to send to wezterm.format in this table.
	local elements = {}

	for i, seg in ipairs(segments) do
		local is_first = i == 1

		if is_first then
			table.insert(elements, { Background = { Color = "none" } })
		end
		table.insert(elements, { Foreground = { Color = gradient[i] } })
		table.insert(elements, { Text = SOLID_LEFT_ARROW })

		table.insert(elements, { Foreground = { Color = fg } })
		table.insert(elements, { Background = { Color = gradient[i] } })
		table.insert(elements, { Text = " " .. seg .. " " })
	end

	window:set_right_status(wezterm.format(elements))
end)

-- Lets set all our custom key bindings
config.keys = {
	{
		key = "v",
		mods = "LEADER",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "h",
		mods = "LEADER",
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
	move_pane("h", "Right"),
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
			args = { "nvim", wezterm.config_file },
		}),
	},
}

config.key_tables = {
	resize_panes = {
		resize_pane("j", "Down"),
		resize_pane("k", "Up"),
		resize_pane("l", "Left"),
		resize_pane("h", "Right"),
	},
}

-- and finally, return the configuration to wezterm
return config
