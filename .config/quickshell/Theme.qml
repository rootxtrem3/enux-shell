import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: theme

    // Color values come from matugen, which regenerates ~/.config/hypr/colors.lua
    // from the current wallpaper: hypr/scripts/wallpaper-daemon.sh runs
    // `matugen image`, and [templates.hyprland-lua] in
    // ~/.config/matugen/config.toml writes the file (post_hook: hyprctl reload).
    //
    // Each token below keeps its previous hardcoded value as a `||` fallback, so
    // a missing or not-yet-generated file still yields the stock palette instead
    // of unstyled colors. This file stays the sole color source for the shell;
    // only where the values originate has changed.
    property var palette: ({})
    // Written by parse(), so it must not be readonly. Bound down to
    // WallpaperService.currentImage to mark the applied wallpaper in the picker.
    property string currentWallpaper: ""
    readonly property string colorsPath: Quickshell.env("HOME") + "/.config/hypr/colors.lua"

    // matugen emits `["role"] = "rgba(RRGGBBAA)"`. QML's rgba() is rgba(r,g,b,a)
    // with 0-255 components, so the hex is narrowed to #rrggbb before use -- the
    // alpha byte is always the trailing `ff` and carries no information.
    function parse(text) {
        const result = {};
        const re = /\["(\w+)"\]\s*=\s*"rgba\(([0-9a-fA-F]{6})[0-9a-fA-F]{2}\)"/g;
        let match = null;
        while ((match = re.exec(text)) !== null)
            result[match[1]] = "#" + match[2].toLowerCase();

        palette = result;
        const image = text.match(/image\s*=\s*"([^"]+)"/);
        currentWallpaper = image ? image[1] : "";
    }

    // Material 3 roles as consumed by the shell.
    readonly property color primary: palette.primary || "#b8c4ff"
    readonly property color primaryOn: palette.on_primary || "#202a5c"
    readonly property color primaryContainer: palette.primary_container || "#384477"
    readonly property color primaryContainerOn: palette.on_primary_container || "#dfe1ff"
    readonly property color surface: palette.surface || "#121318"
    // matugen emits this role but nothing here was reading it until the bar and
    // tray dropped their outlines and needed a fill darker than the wallpaper.
    readonly property color surfaceContainerLowest: palette.surface_container_lowest || "#0d0d0e"
    readonly property color surfaceContainerLow: palette.surface_container_low || "#1a1b20"
    readonly property color surfaceContainer: palette.surface_container || "#1e1f25"
    readonly property color surfaceContainerHigh: palette.surface_container_high || "#292a30"
    readonly property color surfaceContainerHighest: palette.surface_container_highest || "#34353b"
    readonly property color surfaceOn: palette.on_surface || "#e4e1e9"
    readonly property color surfaceVariantOn: palette.on_surface_variant || "#c7c5d0"
    readonly property color outline: palette.outline || "#918f9a"
    readonly property color outlineVariant: palette.outline_variant || "#47464f"
    readonly property color error: palette.error || "#ffb4ab"
    // QML reserves `onError` for signal handlers; this is the Material
    // on-error role under its QML-safe token name.
    readonly property color errorOn: palette.on_error || "#690005"
    readonly property color errorContainer: palette.error_container || "#93000a"
    readonly property color scrim: palette.scrim || "#000000"
    readonly property int space2: 2
    readonly property int space4: 4
    readonly property int space8: 8
    readonly property int space12: 12
    readonly property int space16: 16
    readonly property int space20: 20
    readonly property int space24: 24
    readonly property int space32: 32
    readonly property int radiusSmall: 10
    readonly property int radiusMedium: 16
    readonly property int radiusLarge: 24
    readonly property int radiusExtraLarge: 30
    // The pill's height. The tray beside it reads this same number rather than
    // deriving a second one from it, so the two pills cannot drift apart.
    //
    // Set against the tallest thing inside: the 22px status buttons, which leave
    // 2px of padding above and below them. The tray's own 20px cells sit in the
    // same 26 for 3px each side, so the pair reads as one bar and its satellite
    // rather than as a bar and a smaller bar.
    readonly property int barHeight: 26
    readonly property int panelTopMargin: 6
    readonly property int motionShort: 140
    readonly property int motionMedium: 220
    readonly property int motionLong: 360
    readonly property string fontFamily: robotoRegular.name || "Roboto"
    readonly property string mediumFamily: robotoMedium.name || fontFamily
    readonly property string iconFamily: materialSymbols.name || "Material Symbols Rounded"
    readonly property int labelLarge: 14
    readonly property int labelMedium: 12
    readonly property int bodyMedium: 14
    readonly property int bodySmall: 12
    readonly property int titleMedium: 16
    // Glyph size for app-supplied icons, which do not come with a size of their
    // own the way a Material Symbol does. Set against barHeight: an 18px icon in
    // a 26px pill leaves room for a hover highlight without crowding it.
    readonly property int iconSize: 18

    function alpha(color, opacity) {
        return Qt.rgba(color.r, color.g, color.b, opacity);
    }

    visible: false
    width: 0
    height: 0

    FontLoader {
        id: robotoRegular

        source: Qt.resolvedUrl("assets/fonts/Roboto-Regular.ttf")
    }

    FontLoader {
        id: robotoMedium

        source: Qt.resolvedUrl("assets/fonts/Roboto-Medium.ttf")
    }

    FontLoader {
        id: materialSymbols

        source: Qt.resolvedUrl("assets/fonts/MaterialSymbolsRounded.ttf")
    }

    // Watching colors.lua is what makes the shell follow the wallpaper: matugen
    // rewrites it whenever the wallpaper changes, and reload() re-parses without
    // restarting the shell.
    FileView {
        path: theme.colorsPath
        blockLoading: true
        watchChanges: true
        printErrors: false

        onLoaded: theme.parse(text())
        onFileChanged: reload()
    }

}
