#!/usr/bin/env bash

# Source profile for proper PATH
[ -f /etc/profile ] && source /etc/profile
[ -f "$HOME/.profile" ] && source "$HOME/.profile"
[ -f "$HOME/.bash_profile" ] && source "$HOME/.bash_profile"

CACHE_FILE="$HOME/.cache/awww/0.12.1/LVDS-1"
LAST_PATH=""

get_wallpaper_path() {
    awk -F'\0' '{for(i=1;i<=NF;i++) p=$i} END{print p}' "$CACHE_FILE" 2>/dev/null
}

reload_apps() {
    hyprctl reload 2>/dev/null
    pkill -SIGUSR2 waybar 2>/dev/null
    pkill -SIGUSR1 kitty 2>/dev/null
    swaync-client -rs 2>/dev/null || true
}

generate() {
    local wallpaper="$1"
    [ -z "$wallpaper" ] && return
    [ ! -f "$wallpaper" ] && return
    matugen image --source-color-index 0 "$wallpaper" 2>/dev/null
    reload_apps
}

# Initial generation
if [ -f "$CACHE_FILE" ]; then
    LAST_PATH=$(get_wallpaper_path)
    generate "$LAST_PATH"
fi

while true; do
    if [ -f "$CACHE_FILE" ]; then
        CURRENT_PATH=$(get_wallpaper_path)
        if [ -n "$CURRENT_PATH" ] && [ "$CURRENT_PATH" != "$LAST_PATH" ]; then
            LAST_PATH="$CURRENT_PATH"
            generate "$CURRENT_PATH"
        fi
    fi
    sleep 2
done
