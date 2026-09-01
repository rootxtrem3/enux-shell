#!/usr/bin/env bash
#
# Standalone rofi wallpaper picker — 3x3 thumbnail grid with folder navigation.
#
# Usage:
#   ./wallpaper-picker.sh [wallpaper_dir] [transition]
#
# Requires: rofi (>=1.7, for the icon rofi-script protocol), awww, awww-daemon running.

set -euo pipefail

WALL_ROOT="${WALL_ROOT:-$HOME/Pictures/Wallpapers}"
WALL_CURRENT="${WALL_CURRENT:-$WALL_ROOT}"
TRANSITION="${1:-random}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_FOLDERS="$SCRIPT_DIR/wallpaper-picker-folders.rasi"
THEME_IMAGES="$SCRIPT_DIR/wallpaper-picker.rasi"

if [ ! -d "$WALL_CURRENT" ]; then
    notify-send "Wallpaper picker" "Directory not found: $WALL_CURRENT" 2>/dev/null || true
    echo "Directory not found: $WALL_CURRENT" >&2
    exit 1
fi

if ! pgrep -x awww-daemon >/dev/null 2>&1; then
    awww-daemon &
    sleep 0.3
fi

is_at_root() {
    [ "$WALL_CURRENT" = "$WALL_ROOT" ]
}

build_list() {
    if ! is_at_root; then
        printf '↩ Back\0icon\x1fback\n'
    fi

    find "$WALL_CURRENT" -maxdepth 1 -type d ! -path "$WALL_CURRENT" | sort | while IFS= read -r dir; do
        name="$(basename "$dir")"
        count=$(find "$dir" -maxdepth 1 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \) 2>/dev/null | wc -l)
        printf '%s (%d)\0icon\x1ffolder\n' "$name" "$count"
    done

    if ! is_at_root; then
        find "$WALL_CURRENT" -maxdepth 1 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \) \
            | sort | while IFS= read -r img; do
                printf '\0icon\x1f%s\n' "$img"
            done
    fi
}

if is_at_root; then
    THEME="$THEME_FOLDERS"
    PROMPT="Themes"
else
    THEME="$THEME_IMAGES"
    PROMPT="$(basename "$WALL_CURRENT")"
fi

selected_name="$(build_list | rofi -dmenu \
    -theme "$THEME" \
    -p "$PROMPT" \
    -display-columns 1 \
    -no-custom \
    -format i)"

[ -z "$selected_name" ] && exit 0

mapfile -t entries < <(
    if ! is_at_root; then
        echo "↩ Back"
    fi
    find "$WALL_CURRENT" -maxdepth 1 -type d ! -path "$WALL_CURRENT" | sort | while IFS= read -r dir; do
        basename "$dir"
    done
    find "$WALL_CURRENT" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \) \
        | sort | while IFS= read -r img; do
            basename "$img"
        done
)

chosen="${entries[$selected_name]}"
[ -z "${chosen:-}" ] && exit 0

if [ "$chosen" = "↩ Back" ]; then
    parent="$(dirname "$WALL_CURRENT")"
    if [ ${#parent} -ge ${#WALL_ROOT} ]; then
        WALL_CURRENT="$parent" exec bash "$0" "$TRANSITION"
    else
        WALL_CURRENT="$WALL_ROOT" exec bash "$0" "$TRANSITION"
    fi
    exit 0
fi

if [ -d "$WALL_CURRENT/$chosen" ]; then
    WALL_CURRENT="$WALL_CURRENT/$chosen" exec bash "$0" "$TRANSITION"
    exit 0
fi

awww img "$WALL_CURRENT/$chosen" \
    --transition-type "$TRANSITION" \
    --transition-step 90 \
    --transition-fps 60

echo "Set wallpaper: $WALL_CURRENT/$chosen"
