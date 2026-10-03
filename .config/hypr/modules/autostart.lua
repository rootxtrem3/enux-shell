hl.on("hyprland.start", function()
	hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")
	hl.exec_cmd("/usr/bin/quickshell -d")
	hl.exec_cmd("awww-daemon")
	--hl.exec_cmd("swaync")
	hl.exec_cmd("hypridle")
	-- bluez daemon. BluetoothService.ensureDaemon() also starts this on demand,
	-- but doing it here means the adapter is already enumerated by the time the
	-- shell reads it. `systemctl start` is a no-op on machines with no radio.
	hl.exec_cmd("systemctl start bluetooth")
	hl.exec_cmd("~/.local/bin/screentime daemon")
	hl.exec_cmd("gpu-screen-recorder")
	hl.exec_cmd("~/.config/hypr/scripts/wallpaper-daemon.sh")
end)
