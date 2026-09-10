#!/bin/bash

# Super + K: rofi overlay listing all keybinds, generated from binds.lua
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

list="$(lua "$SCRIPT_DIR/keybinds-cheatsheet.lua")"

[ -n "$list" ] || exit 0

printf '%s\n' "$list" | rofi -dmenu -i -p "Keybinds " \
    -theme ~/.config/rofi/launchers/type-1/style-9.rasi \
    -theme-str 'window { width: 800px; } listview { lines: 10; }'