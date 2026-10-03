#!/usr/bin/env bash
#
# enux-shell installer — Hyprland + QuickShell.
#
#   ./install.sh              install dependencies, then link the config
#   ./install.sh --dry-run    print every action, change nothing
#   ./install.sh --no-deps    skip the package step, just link the config
#   ./install.sh --uninstall  remove the symlinks this script created
#
# Config trees are symlinked from the repo into ~/.config, so edits in the repo
# take effect immediately and ~/.config never holds a stale copy.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$REPO/.config"
CONFIG_DEST="${XDG_CONFIG_HOME:-$HOME/.config}"
WALLPAPER_DIR="${WALL_ROOT:-$HOME/Pictures/Wallpapers}"

DRY_RUN=0
DO_DEPS=1
DO_UNINSTALL=0

# Every tree under .config/ is linked. Quickshell, hypr and matugen are the
# core; the rest are the terminal, cli and session-menu themes.
CONFIG_TREES=(
  alacritty btop cava ghostty hypr kitty matugen quickshell rofi wlogout
)

# Runtime dependencies. hyprlang is not optional: every module in hypr/ calls
# the hl.* Lua API, and that global is injected by hyprland from libhyprlang at
# config-parse time. Without the library present, hyprland cannot load the config.
# The awww package provides both the awww and awww-daemon binaries.
PACKAGES=(
  quickshell hyprland hyprlang matugen awww
  rofi cava btop wlogout hyprshot jq
  # fonts the config asks for by name
  ttf-jetbrains-mono-nerd
)

# Referenced by wlogout/style.css; absent systems fall back to Noto silently.
OPTIONAL_PACKAGES=(
  ttf-ms-fonts
  ttf-geist-mono-nerd-proportional
)

say()  { printf '%s\n' "$*"; }
step() { printf '\n== %s\n' "$*"; }
info() { printf '   %s\n' "$*"; }
warn() { printf '   warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '   [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

usage() {
  sed -n '3,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 0
}

# --------------------------------------------------------------- preflight

preflight() {
  step "Preflight"

  if [[ $EUID -eq 0 ]]; then
    die "run as your normal user, not root — the symlinks belong in $CONFIG_DEST"
  fi

  [[ -d $CONFIG_SRC ]] || die "no .config directory next to this script"

  local os
  os="$(. /etc/os-release 2>/dev/null && printf '%s' "${ID:-unknown}")"
  info "system: $os"

  case "$os" in
    arch|blackarch|endeavouros|cachyos|garuda) ;;
    *) warn "$os is not Arch-based; the dependency step may not work" ;;
  esac

  local desktop="${XDG_CURRENT_DESKTOP:-unknown}"
  if [[ $desktop == *Hyprland* ]]; then
    info "session: Hyprland"
  else
    info "session: $desktop"
    warn "not running Hyprland; linking is still fine, reload it later"
  fi

  if command -v quickshell >/dev/null 2>&1; then
    info "quickshell $(
      quickshell --version 2>/dev/null |
        grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
    )"
  else
    warn "quickshell not found — the dependency step should provide it"
  fi

  # hyprctl has no --version; `hyprctl version` prints the banner.
  if command -v hyprctl >/dev/null 2>&1; then
    info "hyprland $(hyprctl version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
  else
    warn "hyprctl not found — the dependency step should provide it"
  fi

  # The hl.* Lua API comes from libhyprlang, loaded by hyprland at parse time.
  # There is no `hl` binary, so check the library rather than the command.
  if command -v pacman >/dev/null 2>&1; then
    if pacman -Qq hyprlang >/dev/null 2>&1; then
      info "hyprlang $(pacman -Q hyprlang 2>/dev/null | awk '{print $2}')"
    elif [[ $DO_DEPS -eq 0 ]]; then
      warn "hyprlang missing — hypr/ will not load until it is installed"
    fi
  fi

  mkdir -p "$CONFIG_DEST"
}

# ------------------------------------------------------------ dependencies

pick_helper() {
  for helper in yay paru pikaur pacman; do
    command -v "$helper" >/dev/null 2>&1 && { printf '%s' "$helper"; return; }
  done
  return 1
}

install_deps() {
  step "Dependencies"

  local helper
  if ! helper="$(pick_helper)"; then
    warn "no pacman-based package manager found; skipping"
    warn "install manually: ${PACKAGES[*]}"
    return 0
  fi
  info "using $helper"

  local missing=() pkg
  for pkg in "${PACKAGES[@]}"; do
    pacman -Qq "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    info "all required packages present"
  else
    info "installing ${#missing[@]}: ${missing[*]}"
    if [[ $DRY_RUN -eq 1 ]]; then
      printf '   [dry-run] %s -S --needed %s\n' "$helper" "${missing[*]}"
    else
      "$helper" -S --needed --noconfirm "${missing[@]}"
    fi
  fi

  local optional=()
  for pkg in "${OPTIONAL_PACKAGES[@]}"; do
    pacman -Qq "$pkg" >/dev/null 2>&1 || optional+=("$pkg")
  done
  if [[ ${#optional[@]} -gt 0 ]]; then
    info "optional, not installed: ${optional[*]}"
    info "  wlogout falls back to a default sans font without them"
  fi
}

# ------------------------------------------------------------------ linking

link_config() {
  step "Linking config into $CONFIG_DEST"

  local tree src dest linked=0 skipped=0
  for tree in "${CONFIG_TREES[@]}"; do
    src="$CONFIG_SRC/$tree"
    dest="$CONFIG_DEST/$tree"

    [[ -d $src ]] || { warn "missing tree: $src"; continue; }

    if [[ -L $dest ]]; then
      local current
      current="$(readlink -f "$dest")"
      if [[ $current == "$(readlink -f "$src")" ]]; then
        info "$tree: already linked"
        continue
      fi
      info "$tree: replacing link -> $(basename "$current")"
      run rm -f "$dest"
    elif [[ -e $dest ]]; then
      warn "$tree: $dest exists and is a real directory — left untouched"
      info "  move it aside if you want the repo version:"
      info "    mv $dest $dest.bak && ./install.sh"
      skipped=$((skipped + 1))
      continue
    fi

    run ln -s "$src" "$dest"
    linked=$((linked + 1))
  done

  info "linked $linked, skipped $skipped"
}

# ---------------------------------------------------------------- wallpaper

setup_wallpapers() {
  step "Wallpaper directory"

  if [[ -d $WALLPAPER_DIR ]]; then
    local count
    count="$(find "$WALLPAPER_DIR" -mindepth 1 -maxdepth 1 | wc -l)"
    info "$WALLPAPER_DIR ($count entries)"
  else
    info "creating $WALLPAPER_DIR"
    info "  wallpaper-picker.sh and theme-switcher.sh read from here"
    run mkdir -p "$WALLPAPER_DIR"
  fi
}

# ----------------------------------------------------------------- uninstall

uninstall() {
  step "Unlinking"

  local tree dest
  for tree in "${CONFIG_TREES[@]}"; do
    dest="$CONFIG_DEST/$tree"
    if [[ -L $dest ]]; then
      if [[ "$(readlink -f "$dest")" == "$(readlink -f "$CONFIG_SRC/$tree")" ]]; then
        run rm -f "$dest"
        info "$tree: link removed"
      else
        warn "$tree: link points elsewhere, left alone"
      fi
    else
      info "$tree: not a link, left alone"
    fi
  done
  info "your original directories were never touched"
}

# ---------------------------------------------------------------------- main

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)   DRY_RUN=1 ;;
      --no-deps)   DO_DEPS=0 ;;
      --uninstall) DO_UNINSTALL=1 ;;
      -h|--help)   usage ;;
      *)           die "unknown option: $1 (try --help)" ;;
    esac
    shift
  done

  [[ -d $CONFIG_SRC ]] || die "no .config directory next to this script"

  preflight

  if [[ $DO_UNINSTALL -eq 1 ]]; then
    uninstall
    say ""
    say "Done."
    return 0
  fi

  [[ $DO_DEPS -eq 1 ]] && install_deps
  link_config
  setup_wallpapers

  step "Done"
  cat <<EOF
   Reload the running session with:

     hyprctl reload
     quickshell -p $CONFIG_SRC/quickshell

   If the bar does not come back, check it directly:

     quickshell -p $CONFIG_SRC/quickshell/shell.qml

   Colors come from matugen. After changing wallpaper, regenerate with:

     matugen image $WALLPAPER_DIR

   Remove the links again with: ./install.sh --uninstall
EOF
}

main "$@"