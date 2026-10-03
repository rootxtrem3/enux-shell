# enux-shell

My Enux desktop shell: Hyprland + QuickShell.

Hyprland is driven by a Lua config (via `hyprlang`, the `hl.*` API) and the shell
is a QuickShell/QML bar I wrote. Colors come from `matugen`, which reads the
current wallpaper and regenerates the palette for both.

## Layout

```
.config/
  hypr/         Hyprland: hyprland.lua + modules/, scripts/
  quickshell/   the QML shell: shell.qml, Theme.qml, components/, services/
  matugen/      wallpaper color generation: config.toml + templates/
  kitty/  alacritty/  ghostty/     terminals
  cava/   btop/                     cli tools
  wlogout/ rofi/                    session menu + launcher
install.sh      dependency setup + symlinks
```

A flat `.config/` tree, so GNU Stow works too:

```bash
stow --dir=.config
```

## Install

```bash
./install.sh              # deps, then symlink the config
./install.sh --dry-run    # show everything, change nothing
./install.sh --no-deps    # link only, skip pacman
./install.sh --uninstall  # remove the symlinks
```

The config trees are symlinked into `~/.config`, so edits in the repo apply
immediately and `~/.config` never holds a stale copy. **An existing real
directory is never clobbered** — the installer skips it and tells you to move it
aside first.

### Dependencies

Installed from pacman/yay/paru: `quickshell` `hyprland` `hyprlang` `matugen`
`awww` `rofi` `cava` `btop` `wlogout` `hyprshot` `jq`
`ttf-jetbrains-mono-nerd`.

`hyprlang` is required, not optional: every module in `hypr/` calls `hl.*`, and
that global is injected by hyprland from `libhyprlang` at parse time. There is no
`hl` binary to look for.

Optional: `ttf-ms-fonts` and `ttf-geist-mono-nerd-proportional`. Both are named in
`wlogout/style.css`; without them the menu silently falls back to Noto.

Also expected at runtime but not managed by the installer:

| Path | What |
|---|---|
| `~/Pictures/Wallpapers` | wallpaper root; the picker and theme switcher read it. Created if missing. |
| `/var/cache/hyprpm/rootx/HyprGlass/hyprglass.so` | HyprGlass plugin, loaded by `hyprland.lua` |

## After installing

```bash
hyprctl reload
quickshell -p .config/quickshell
```

To regenerate the palette by hand:

```bash
matugen image ~/Pictures/Wallpapers
```

## How the pieces fit

`Theme.qml` parses `~/.config/hypr/colors.lua` with a regex and exposes Material 3
roles as QML properties, each keeping its old hardcoded value as a `||` fallback so
a missing or not-yet-generated file still yields a usable palette. Every component
reads its colors from `Theme.qml` — that file is the only color source.

The loop that ties it together:

```
wallpaper changes
  └─ hypr/scripts/wallpaper-daemon.sh
       └─ matugen image
            ├─ templates/hyprland-colors.lua → hypr/colors.lua   (post_hook: hyprctl reload)
            ├─ templates/hyprland-colors.conf → hypr/colors.conf
            ├─ templates/kitty-colors.conf   → kitty/colors.conf
            ├─ templates/colors.css          → wlogout/styles/colors.css
            ├─ templates/rofi-colors.rasi    → rofi/colors/colors.rasi
            └─ templates/btop-colors.theme   → btop/themes/current.theme
```

`binds.lua` and the shell talk over `quickshell ipc call shell <function>`;
`hypr/scripts/volume.sh` and `brightness.sh` call the same functions.

## Notes

- **`wlogout/layout` had a stray comma** in the `shutdown` entry that made the
  file unparseable after the second button. Fixed here, so all five actions load.
  The icons still ship under their original names (`hibernate`, `power`,
  `restart`, `sleep`) while the layout asks for `reboot`, `shutdown` and `suspend`,
  so those three render without an icon. Rename them to match if you want them
  drawn.
- **`matugen/config.toml` points at things this repo does not carry** — `waybar`,
  `swaync`, `wayle` and `ohmyposh` templates write to paths outside `.config/`.
  Harmless on a machine that has them, a no-op elsewhere. The `[templates.neovim]`
  entry also writes to `~/.config/matugen/colors.json`, which looks like it was
  meant for neovim.
- **`hypr/colors.conf` is never read.** Only `colors.lua` is loaded; `colors.conf`
  is kept because matugen regenerates it.
- **rofi is trimmed.** Only `colors/colors.rasi`, `launchers/type-1/calc.rasi` and
  `launchers/type-1/style-9.rasi` are referenced. The `type-2/`, `type-6/` and
  `images/` directories are gitignored.
- **`Super+Shift+N` is bound to a function that does not exist.** `binds.lua` calls
  `quickshell ipc ... call shell toggleSunset`, but no `toggleSunset` is defined in
  `shell.qml`, so the key does nothing. Left as-is; add the handler to `shell.qml`
  or point the bind at `hyprsunset` directly. (`Super+Shift+I` → `toggleIdle` is
  fine.)
- **`binds.lua` hardcodes `/home/rootx/`** in two `quickshell ipc` calls. Change it
  to `$HOME` if you install under a different username.
- Wallpapers, `*.bak`, `__pycache__` and `hypr/backups/` are not tracked.