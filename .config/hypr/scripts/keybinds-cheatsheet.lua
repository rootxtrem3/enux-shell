-- Generates a keybind cheatsheet by executing the real binds.lua
-- against a stub `hl` API. Every hl.bind() call is captured (nothing
-- is actually dispatched), then humanized into display rows.
--
-- Usage: lua keybinds-cheatsheet.lua

local HOME = os.getenv("HOME")
local BINDS_FILE = HOME .. "/.config/hypr/modules/binds.lua"

-- Bindings land here: { k = "Super + K", d = "description" }
local rows = {}

-- Friendly labels for exec() commands
local function desc(cmd)
	local c = cmd:gsub("^pkill rofi || ", ""):gsub("%s+$", "")

	if cmd:match("^pkill rofi") then
		if cmd:match("walset") then
			return "Theme switcher (matugen)"
		end
		if cmd:match("drun") then
			return "App launcher (rofi)"
		end
		return "Random wallpaper launcher"
	end

	local script = c:match("([%w_%-]+%.sh)")
	if script == "volume.sh" then
		if c:match("toggle") then
			return "Mute volume"
		end
		if c:match("dec") then
			return "Volume down"
		end
		return "Volume up"
	elseif script == "brightness.sh" then
		if c:match("dec") then
			return "Brightness down"
		end
		return "Brightness up"
	elseif script == "wallpaper-picker.sh" then
		return "Wallpaper picker"
	elseif script == "wallpaper-quick.sh" then
		return "Wallpaper (quick)"
	elseif script == "night-mode.sh" then
		return "Toggle night mode"
	elseif script == "scratchpad.sh" then
		return "Toggle terminal scratchpad"
	elseif script == "game-mode.sh" then
		return "Toggle game mode"
	elseif script == "launch.sh" then
		return "Launch Waybar"
	elseif script == "keybinds-cheatsheet.sh" then
		return "Keybind cheatsheet"
	end

	if c:match("^hyprpicker") then
		return "Color picker (hyprpicker)"
	end

	if c:match("^kill%s+-9") then
		return "Force close window"
	end

	local hyprshot = c:match("hyprshot.-%-m (%w+)")
	if hyprshot then
		return "Screenshot (" .. hyprshot .. ")"
	end

	local flatpak = c:match("flatpak run (%S+)")
	if flatpak then
		local apps = {
			["app.zen_browser.zen"] = "Browser (Zen)",
			["org.telegram.desktop"] = "Telegram",
			["org.localsend.localsend_app"] = "LocalSend",
		}
		return apps[flatpak] or flatpak
	end

	local pc = c:match("^playerctl (%S+)")
	if pc then
		local acts =
			{ next = "Next track", previous = "Previous track", ["play-pause"] = "Play / pause", stop = "Stop" }
		return acts[pc] or ("Media: " .. pc)
	end

	if c:match("^wlogout") then
		return "Logout menu"
	end
	if c == "swaync-client -t" then
		return "Toggle action center"
	end

	local singles = {
		kitty = "Terminal (kitty)",
		nautilus = "File manager (nautilus)",
		lutris = "Lutris",
		steam = "Steam",
		unityhub = "Unity Hub",
		grim = "Screenshot (grim)",
		hyprlock = "Lock screen",
		reboot = "Reboot",
		poweroff = "Power off",
		hyprpicker = "Color picker (hyprpicker)",
	}
	if singles[c] then
		return singles[c]
	end

	-- Trim a common scripts/ prefix, keep the rest raw
	return (c:gsub("^~?/.+%f[%w]scripts/", ""))
end

-- Stub for hl.dsp.*: every method returns a printable description
local dsp = {}
dsp.exec_cmd = function(cmd)
	return { kind = "exec", cmd = tostring(cmd) }
end
dsp.window = {}
dsp.window.close = function()
	return { kind = "desc", text = "Close window" }
end
dsp.window.float = function()
	return { kind = "desc", text = "Toggle floating" }
end
dsp.window.pseudo = function()
	return { kind = "desc", text = "Toggle pseudo-tiling" }
end
dsp.window.fullscreen = function()
	return { kind = "desc", text = "Toggle fullscreen" }
end
dsp.window.swap = function()
	return { kind = "desc", text = "Swap windows" }
end
dsp.window.drag = function()
	return { kind = "desc", text = "Drag window (mouse)" }
end
dsp.window.resize = function()
	return { kind = "desc", text = "Resize window (mouse)" }
end
dsp.window.move = function(o)
	o = o or {}
	if o.direction then
		return { kind = "desc", text = "Move window " .. o.direction }
	end
	if o.workspace then
		if tostring(o.workspace):match("^special") then
			return { kind = "desc", text = "Move window to scratchpad" }
		end
		return { kind = "desc", text = "Move window to workspace " .. tostring(o.workspace) }
	end
	return { kind = "desc", text = "Move window" }
end
dsp.focus = function(o)
	o = o or {}
	if o.direction then
		return { kind = "desc", text = "Focus " .. o.direction }
	end
	if o.workspace then
		if o.workspace == "e+1" then
			return { kind = "desc", text = "Next workspace" }
		end
		if o.workspace == "e-1" then
			return { kind = "desc", text = "Previous workspace" }
		end
		return { kind = "desc", text = "Go to workspace " .. tostring(o.workspace) }
	end
	return { kind = "desc", text = "Focus" }
end
dsp.workspace = {}
dsp.workspace.toggle_special = function(name)
	return { kind = "desc", text = "Toggle scratchpad (" .. tostring(name or "special") .. ")" }
end
dsp.layout = function(action)
	if action == "togglesplit" then
		return { kind = "desc", text = "Toggle split layout" }
	end
	return { kind = "desc", text = "Layout: " .. tostring(action) }
end

-- Humanize modifier/key names for display
local function human_key(k)
	local names = {
		SUPER = "Super",
		SHIFT = "Shift",
		CONTROL = "Ctrl",
		ALT = "Alt",
		SPACE = "Space",
		Return = "Enter",
		PRINT = "Print",
		["mouse:272"] = "LMB (drag)",
		["mouse:273"] = "RMB (resize)",
		mouse_down = "Mouse wheel down",
		mouse_up = "Mouse wheel up",
	}
	return (k:gsub("(%S+)", function(w)
		return names[w] or w
	end))
end

-- Stub hl global (must be global: binds.lua references it directly)
hl = {}
hl.dsp = dsp
hl.get_active_window = function()
	return nil
end
hl.bind = function(mods, action, opts)
	local d
	if type(action) == "table" then
		if action.kind == "exec" then
			d = desc(action.cmd)
		else
			d = action.text
		end
	elseif type(action) == "string" then
		d = action
	else
		d = "Custom action"
	end
	table.insert(rows, { k = human_key(mods), d = d })
end

-- Resolve ~/.config/hypr/modules/programs.lua the same way binds.lua expects
package.preload["modules.programs"] = function()
	return { terminal = "kitty", fileManager = "nautilus" }
end

dofile(BINDS_FILE)

local WIDTH = 26
local out = {}
for _, r in ipairs(rows) do
	table.insert(out, string.format("%-" .. WIDTH .. "s%s", r.k, r.d))
end
print(table.concat(out, "\n"))
