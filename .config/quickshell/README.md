# Material 3 QuickShell bar

Run it with `qs -p ~/.config/quickshell` (or simply `qs`, because this is the
standard default configuration path). The visual bar is one centered,
content-hugging pill; the transparent panel window only supplies a precise
input region around that pill.

## Design and behavior

- `Theme.qml` is the only palette/type/shape/motion token source. Components
  receive its object instead of defining their own colors.
- The bundled `assets/fonts/` files are loaded by `Theme.qml`: Roboto Regular,
  Roboto Medium, and Material Symbols Rounded. No system font is required.
- Network, Bluetooth, audio, battery, Hyprland workspaces, and notifications
  are native QuickShell services. The system-resource wrapper uses one combined
  `/proc` sample every 5 seconds; it does not run a sub-second polling loop.
- Dashboard and network popups use QuickShell `PopupWindow.grabFocus`, which
  performs native click-away dismissal. Opening one replaces the other.
- The dynamic island queues notifications and transient system events one at a
  time. Each entry is shown for 3.6 seconds, then the island advances or fully
  collapses.
- The brightness OSD uses QuickShell `FileView` with file-change watching after
  a one-time backlight discovery, avoiding a brightness polling loop.

The Restart and Power off buttons require a second press within 2.5 seconds;
all other power actions use their respective session/system commands only when
clicked.
