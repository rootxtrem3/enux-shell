import QtQuick

Item {
    id: root

    property var panelWindow: null
    // Theme.qml already watches matugen's colors.lua and parses the applied
    // wallpaper out of it, so the wallpaper service gets its "currently applied"
    // value from there instead of opening a second watcher on the same file.
    property string currentWallpaper: ""
    readonly property alias workspaces: workspaces
    readonly property alias network: network
    readonly property alias bluetooth: bluetooth
    readonly property alias audio: audio
    readonly property alias battery: battery
    readonly property alias notifications: notifications
    readonly property alias brightness: brightness
    readonly property alias stats: stats
    readonly property alias power: power
    readonly property alias launcher: launcher
    readonly property alias wallpaper: wallpaper

    visible: false
    width: 0
    height: 0

    WorkspaceService {
        id: workspaces
    }

    NetworkService {
        id: network
    }

    BluetoothService {
        id: bluetooth
    }

    AudioService {
        id: audio
    }

    BatteryService {
        id: battery
    }

    NotificationsService {
        id: notifications
    }

    BrightnessService {
        id: brightness
    }

    SystemStats {
        id: stats
    }

    PowerService {
        id: power

        panelWindow: root.panelWindow
    }

    LauncherService {
        id: launcher
    }

    WallpaperService {
        id: wallpaper

        currentImage: root.currentWallpaper
    }

}
