local colors = require("colors")

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 7,
		border_size = 0,
		col = {
			active_border = colors.secondary,
			inactive_border = colors.outline_variant,
		},
		resize_on_border = true,
		allow_tearing = false,
	},
	decoration = {
		rounding = 8,
		rounding_power = 7,
		-- Opacity is set per-window for terminals only; everything else stays opaque.
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		dim_inactive = true,
		shadow = {
			enabled = true,
			range = 4,
			render_power = 4,
			color = "rgba(1a1a1aee)",
		},
		blur = {
			enabled = true,
			size = 1,
			passes = 3,
			vibrancy = 0.1696,
			--	variant = "acrylic",
			--  acrylic = {
			--	refraction = 4.0,
			--	bulb = 8.0,
			--	clarity = 0.82,
			--	aberration = 0.025,
			--	tint = "0x14EEF5FF",
		},
	},
	layerrule = {
		"blur, waybar",
		"ignorezero, waybar",
	},
})
