--hl.plugin.load("/var/cache/hyprpm/rootx/HyprGlass/hyprglass.so")

require("colors")
require("modules.monitors")
require("modules.env")
require("modules.decorations")
require("modules.layout")
require("modules.misc")
require("modules.input")
require("modules.autostart")
require("modules.binds")
require("modules.windowrules")
require("modules.animations")
if hl.plugin.hyprglass then
	local hg = hl.plugin.hyprglass

	hg.config({
		enabled = true,
		manage_window_blur = true,
		default_theme = "dark",
		default_preset = "glass",
		tint_color = 0x8899aa12,

		brightness = 0.9,
		dark = { brightness = 0.82 },
		light = { adaptive_boost = 0.5 },

		layers = { enabled = 1 },
	})

	-- Layer surfaces: each call whitelists the namespace and configures it
	--hg.layer("waybar", { preset = "subtle", mask_threshold = 0.05 })
	hg.layer("swaync")
	hg.layer("quickshell:bezel", { preset = "ui", mask_threshold = 0.3 })
	hg.layer("debug-panel", { exclude = true })

	-- Presets
	hg.preset("glass", {
		-- High-visibility profile: keep wallpaper detail sharp enough for
		-- the displacement, spectral edges, and center lens to be obvious.
		glass_opacity = 0.9,
		blur_strength = 0.35,
		blur_iterations = 3,
		refraction_strength = 1.0,
		chromatic_aberration = 1.0,
		lens_distortion = 1.0,
		fresnel_strength = 1.0,
		specular_strength = 1.0,
		edge_thickness = 0.2,
	})

	hg.preset("clear", {
		glass_opacity = 0.8,
		blur_strength = 1.5,
		dark = { brightness = 0.7 },
		light = { brightness = 1.2 },
	})

	hg.preset("contrasted", {
		inherits = "high_contrast",
		contrast = 1.2,
		adaptive_dim = 1.5,
		dark = { tint_color = 0x02142aa9 },
	})
end

-- HyprMod managed settings
require("hyprland-gui")
