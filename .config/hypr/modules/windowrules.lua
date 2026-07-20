hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

hl.window_rule({
	name = "terminal-opacity",
	match = { class = "^(kitty|Alacritty)$" },
	opacity = 0.9,
})

hl.window_rule({
	name = "nautilus-opacity",
	match = { class = "org.gnome.Nautilus", "protonvpn_app" },
	opacity = 0.9,
	float = true,
	size = { 1200, 700 },
})

hl.window_rule({
	name = "waypaper-float",
	match = { class = "^waypaper$" },
	float = true,
	size = { 800, 600 },
})

hl.window_rule({
	name = "suppress-fullscreen-events",
	match = { class = ".*" },
	suppress_event = "fullscreen",
})

hl.window_rule({
	name = "scratchpad-terminal",
	match = { class = "^scratchpad$" },
	workspace = "special:scratchpad",
	float = true,
	center = true,
	size = { 800, 600 },
})
