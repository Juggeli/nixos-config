{ fontSize, ...}:
''
-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font_with_fallback({
	"Comic Code Ligatures",
	{ family = "Symbols Nerd Font Mono", scale = 0.8 },
})
config.default_prog = { "/run/current-system/sw/bin/fish" }
config.window_close_confirmation = "NeverPrompt"
-- config.window_decorations = "NONE"
-- config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.font_size = ${fontSize}

-- then finally apply the plugin
-- these are currently the defaults:
wezterm.plugin.require("https://github.com/nekowinston/wezterm-bar").apply_to_config(config, {
	position = "bottom",
	max_width = 32,
	dividers = "slant_right", -- or "slant_left", "arrows", "rounded", false
	indicator = {
		leader = {
			enabled = true,
			off = " ",
			on = " ",
		},
		mode = {
			enabled = true,
			names = {
				resize_mode = "RESIZE",
				copy_mode = "VISUAL",
				search_mode = "SEARCH",
			},
		},
	},
	tabs = {
		numerals = "arabic", -- or "roman"
		pane_count = "superscript", -- or "subscript", false
		brackets = {
			active = { "", ":" },
			inactive = { "", ":" },
		},
	},
	clock = {
		-- note that this overrides the whole set_right_status
		enabled = true,
		format = "%H:%M", -- use https://wezfurlong.org/wezterm/config/lua/wezterm.time/Time/format.html
	},
})

-- and finally, return the configuration to wezterm
return config
''
