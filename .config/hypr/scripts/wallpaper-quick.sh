#!/usr/bin/env bash
# Launches the Quickshell dock-style wallpaper picker (hyprquickpicker).
# Kills any existing instance first so the keybind is single-instance.

set -e

SCRIPT_DIR="${HYPRQUICKPICKER:-$HOME/Projects/hyprquickpicker}"

pkill -f 'quickshell -p .*hyprquickpicker' 2>/dev/null || true

exec quickshell -p "$SCRIPT_DIR/shell.qml"
