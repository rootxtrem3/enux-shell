#!/usr/bin/env bash
#
# Rofi theme switcher — pick a theme folder, apply a random wallpaper from it.
#
# Requires: rofi (>=1.7, for the icon rofi-script protocol), awww, awww-daemon running.

set -euo pipefail

WALL_ROOT="${WALL_ROOT:-$HOME/Pictures/Wallpapers}"
TRANSITION="${1:-random}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME="$SCRIPT_DIR/wallpaper-picker-folders.rasi"

if [ ! -d "$WALL_ROOT" ]; then
    notify-send "Theme switcher" "Directory not found: $WALL_ROOT" 2>/dev/null || true
    echo "Directory not found: $WALL_ROOT" >&2
    exit 1
fi

if ! pgrep -x awww-daemon >/dev/null 2>&1; then
    awww-daemon &
    sleep 0.3
fi

folders() {
    find "$WALL_ROOT" -maxdepth 1 -mindepth 1 -type d | sort | while IFS= read -r dir; do
        printf '%s\n' "$dir"
    done
}

build_list() {
    printf '🎲 Random Theme\0icon\x1fcolor-wheel\n'
    while IFS= read -r dir; do
        name="$(basename "$dir")"
        count=$(find "$dir" -maxdepth 1 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \) 2>/dev/null | wc -l)
        printf '%s (%d)\0icon\x1ffolder\n' "$name" "$count"
    done < <(folders)
}

selected_name="$(build_list | rofi -dmenu \
    -theme "$THEME" \
    -p "Theme" \
    -display-columns 1 \
    -no-custom \
    -format i)"

[ -z "$selected_name" ] && exit 0

mapfile -t entries < <(
    printf '%s\n' "🎲 Random Theme"
    while IFS= read -r dir; do
        basename "$dir"
    done < <(folders)
)

chosen="${entries[$selected_name]}"
[ -z "${chosen:-}" ] && exit 0

if [ "$chosen" = "🎲 Random Theme" ]; then
    theme_dir="$(folders | shuf -n 1)"
    theme_name="$(basename "$theme_dir")"
else
    theme_dir="$WALL_ROOT/$chosen"
    theme_name="$chosen"
fi

if [ ! -d "$theme_dir" ]; then
    notify-send "Theme switcher" "Theme folder not found: $theme_dir" 2>/dev/null || true
    echo "Theme folder not found: $theme_dir" >&2
    exit 1
fi

wallpaper="$(find "$theme_dir" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \) 2>/dev/null | shuf -n 1)"

if [ -z "$wallpaper" ]; then
    notify-send "Theme switcher" "No wallpapers in theme: $theme_name" 2>/dev/null || true
    echo "No wallpapers in theme: $theme_name" >&2
    exit 1
fi

awww img "$wallpaper" \
    --transition-type "$TRANSITION" \
    --transition-step 90 \
    --transition-fps 60

notify-send "Theme: $theme_name" "$(basename "$wallpaper")" 2>/dev/null || true
echo "Theme: $theme_name, wallpaper: $wallpaper"