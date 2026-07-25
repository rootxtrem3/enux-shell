local programs = require("modules.programs")

local mainMod = "SUPER"
--hl.bind("Home", hl.dsp.focus({ workspace = 1 }))
--hl.bind("ALT + SUPER + ALT_SUPER_V", hl.dsp.resize({ direction = "center", factor = 0.5  }))
--Screenshot
hl.bind("PRINT", hl.dsp.exec_cmd("grim"))
--share
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("flatpak run org.localsend.localsend_app"))
-- Terminal
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(programs.terminal))
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("alacritty"))

-- File manager
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(programs.fileManager))

-- Browser (Zen through Flatpak)
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("flatpak run app.zen_browser.zen"))

-- Wallpaper manager
hl.bind(
	mainMod .. " + W",
	hl.dsp.exec_cmd("/usr/bin/quickshell ipc --any-display -p /home/rootx/.config/quickshell/shell.qml call shell toggleWallpaperPicker")
)
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpaper-quick.sh"))

-- Screenshots
hl.bind(mainMod .. " + F12", hl.dsp.exec_cmd("hyprshot -o Pictures/Screenshots/ -m output"))
hl.bind(mainMod .. " + SHIFT + F12", hl.dsp.exec_cmd("hyprshot -o Pictures/Screenshots/ -m region"))
hl.bind(mainMod .. " + CONTROL + F12", hl.dsp.exec_cmd("hyprshot -o Pictures/Screenshots/ -m window"))

-- App menu (Quickshell)
hl.bind(
	mainMod .. " + Space",
	hl.dsp.exec_cmd("/usr/bin/quickshell ipc --any-display -p /home/rootx/.config/quickshell/shell.qml call shell toggleLauncher")
)
hl.bind(
	mainMod .. " + C",
	hl.dsp.exec_cmd("pkill rofi || rofi -modi calc -show calc -theme ~/.config/rofi/launchers/type-1/calc.rasi")
)

-- Waybar
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("~/.config/waybar/scripts/launch.sh"))

-- Quickshell (top bar/shell): kill + restart, same spawn as autostart.lua
-- Command runs through Hyprland's dispatch, so DISPLAY/WAYLAND_DISPLAY are
-- inherited exactly like the boot-time launch -- no half-alive phantom state.
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("bash -c 'pkill -x quickshell; sleep 0.5; nohup /usr/bin/quickshell -d >/tmp/qshell-restart.log 2>&1 &'"))

-- Steam
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("lutris"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("steam"))

-- Unity
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd("unityhub"))

-- Theme switcher
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("pkill rofi || ~/.config/hypr/scripts/theme-switcher.sh"))

-- Telegram (Flatpak)
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("flatpak run org.telegram.desktop"))

-- Action center
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("swaync-client -t"))

-- Rofi drun launcher
hl.bind(
	mainMod .. " + D",
	hl.dsp.exec_cmd("pkill rofi || rofi -show drun -theme ~/.config/rofi/launchers/type-1/style-9.rasi")
)

-- Color picker
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("hyprpicker -af hex -n"))

-- Keybind cheatsheet
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("~/.config/hypr/scripts/keybinds-cheatsheet.sh"))

-- Power
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("reboot"))
hl.bind(mainMod .. " + SHIFT + Escape", hl.dsp.exec_cmd("poweroff"))

-- Night mode
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("~/.config/hypr/scripts/night-mode.sh"))

-- hyprsunset / hypridle toggles (via quickshell for state sync)
hl.bind(
	mainMod .. " + SHIFT + N",
	hl.dsp.exec_cmd("/usr/bin/quickshell ipc --any-display -p /home/rootx/.config/quickshell/shell.qml call shell toggleSunset")
)
hl.bind(
	mainMod .. " + SHIFT + I",
	hl.dsp.exec_cmd("/usr/bin/quickshell ipc --any-display -p /home/rootx/.config/quickshell/shell.qml call shell toggleIdle")
)

-- Lock
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

-- Wlogout
hl.bind(
	"CTRL + ALT + DELETE",
	hl.dsp.exec_cmd(
		'wlogout -C "$HOME/.config/wlogout/style.css" -l "$HOME/.config/wlogout/layout" --protocol layer-shell -b 5 -T 400 -B 400'
	)
)

-- Close / kill windows
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(
	mainMod .. " + SHIFT + Q",
	hl.dsp.exec_cmd(
		"kill -9 $(hyprctl activewindow -j | python3 -c \"import sys,json;print(json.load(sys.stdin)['pid'])\")"
	)
)

-- Wlogout
hl.bind(
	mainMod .. " + M",
	hl.dsp.exec_cmd(
		'wlogout -C "$HOME/.config/wlogout/style.css" -l "$HOME/.config/wlogout/layout" --protocol layer-shell -b 5 -T 400 -B 400'
	)
)
hl.bind(mainMod .. " + V", function()
	local win = hl.get_active_window()
	local wasFloating = win ~= nil and win.floating
	hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
	if not wasFloating then
		hl.dispatch(hl.dsp.window.resize({ x = 800, y = 600 }))
	end
end)
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Move window with mainMod + SHIFT + arrows
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

-- Swap/exchange windows (with only two open, this swaps their places)
hl.bind(mainMod .. " + SHIFT + Space", hl.dsp.window.swap({ next = true }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + X", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.window.move({ workspace = "special:magic" }))

-- Terminal scratchpad toggle
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("~/.config/hypr/scripts/scratchpad.sh"))

-- Scroll through workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume (function keys + media keys)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh --toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh --dec"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh --inc"),
	{ locked = true, repeating = true }
)
hl.bind("F6", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh --toggle"), { locked = true, repeating = true })
hl.bind("F7", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh --dec"), { locked = true, repeating = true })
hl.bind("F8", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh --inc"), { locked = true, repeating = true })

-- Brightness (function keys + media keys)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh --dec"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh --inc"),
	{ locked = true, repeating = true }
)
hl.bind("F3", hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh --inc"), { locked = true, repeating = true })
hl.bind("F2", hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh --dec"), { locked = true, repeating = true })

-- Media keys (locked)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })

hl.bind("F9", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("F10", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("F11", hl.dsp.exec_cmd("playerctl next"), { locked = true })
