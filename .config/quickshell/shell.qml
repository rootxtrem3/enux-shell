//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import "components"
import "services"

ShellRoot {
    id: shell

    property string openSurface: ""
    readonly property var palette: theme

    function toggleSurface(surface) {
        openSurface = openSurface === surface ? "" : surface;
    }

    // Hand the keyboard to whichever menu is opening. A layer-shell surface
    // does not take focus on its own, and neither does the bar button that
    // opened it -- that window is not focusable, so the focused application
    // keeps the keyboard and the menu never sees a key. Nothing in here asked
    // for focus before, so the Escape shortcut and the wifi password field's
    // cursor both depended on the user happening to click the surface.
    //
    // Focus goes to an *item*, not to the window. PanelWindow has no
    // forceActiveFocus() of its own -- calling it throws "not a function" and
    // leaves the callLater below rejected, so the window silently keeps its old
    // focus and the shortcut never fires. Item.forceActiveFocus() does work on a
    // layer surface, and is already what the password field relies on. Nothing
    // is drawn for the focus to show on: Items have no focus ring.
    //
    // Deferred by a callLater because the surface is only made visible by this
    // same state change, and an item cannot be given focus before its window is
    // on screen. When the menu closes its window goes away with it and the
    // compositor gives the keyboard back.
    onOpenSurfaceChanged: if (openSurface !== "")
        Qt.callLater(function() {
            if (openSurface === "network")
                networkMenu.forceActiveFocus();
            else if (openSurface === "dashboard")
                dashboardMenu.forceActiveFocus();
        })

    Theme {
        id: theme
    }

    Services {
        id: services

        panelWindow: panel
        currentWallpaper: theme.currentWallpaper
    }

    Launcher {
        theme: theme
        services: services
    }

    WallpaperPicker {
        theme: theme
        services: services
    }

    // Everything below is the shell's external IPC surface, reached with
    // `quickshell ipc call --any-display shell <function>`. hypr/modules/binds.lua
    // and hypr/scripts/{volume,brightness}.sh already call these names.
    IpcHandler {
        target: "shell"

        function ping() {}


        function toggleLauncher() {
            services.launcher.toggleLauncher();
        }

        function showLauncher() {
            services.launcher.openLauncher("apps");
        }

        function hideLauncher() {
            services.launcher.closeLauncher();
        }

        function toggleWallpaperPicker() {
            if (services.wallpaper.open)
                services.wallpaper.hide();
            else
                services.wallpaper.show();

        }

        function openWallpaperPicker() {
            services.wallpaper.show();
        }

        // The scripts have already applied these values with pamixer and
        // brightnessctl, so adopt rather than set: no second write, and the OSD
        // lands without waiting on a read-back.
        function setVolume(percent: int) {
            services.audio.adoptVolume(percent / 100);
        }

        function osdMuted() {
            island.showOsd("volume_off", "Volume", "Muted", services.audio.volume);
        }

        function setBrightness(percent: int) {
            services.brightness.adoptBrightness(percent / 100);
        }

        function osd(icon: string, label: string, percent: int) {
            island.showOsd(icon, label, Math.round(percent) + "%", percent / 100);
        }

        // Backs SUPER+SHIFT+I. The bind has always called this, but the handler
        // never defined it, so the keypress failed silently and the dashboard's
        // Idle button stayed the only (also broken) way in.
        function toggleIdle() {
            services.power.setIdleInhibited(!services.power.idleInhibited);
        }

        // Escape's path out, for a keybind. The menus also close on Escape
        // themselves; this exists so a bind can reach the same state without
        // depending on the menu layer holding keyboard focus.
        function closeSurface() {
            shell.openSurface = "";
        }

    }

    PanelWindow {
        id: panel

        // The bar is drawn at y = panelTopMargin with height barHeight, so the
        // panel only needs to span that much. Reserving panelTopMargin * 2 left
        // an empty band under the bar that pushed windows down for nothing.
        implicitHeight: theme.barHeight + theme.panelTopMargin
        color: "transparent"
        exclusiveZone: theme.barHeight + theme.panelTopMargin
        aboveWindows: true

        anchors {
            top: true
            left: true
            right: true
        }

        // Under the bar, so its own scene graph lives and dies with the panel.
        // Nothing is drawn: see components/DynamicIsland.qml.
        DynamicIsland {
            id: island

            theme: theme
        }

        // A sibling of the island rather than a part of it, flush against the
        // bar's right edge. It stays out of the bar's contents so that a tray
        // icon appearing cannot resize the island -- see components/Tray.qml.
        //
        // Declared before the bar, so the bar paints over it. That is harmless
        // rather than a bug: the tray's x is derived from the bar's right edge
        // plus a gap, so the two cannot overlap and the paint order is never
        // exercised. It is only worth knowing if that gap is ever removed.
        //
        // barItem is declared below this, which is fine -- a QML id is resolved
        // for the whole component, not in declaration order.
        Tray {
            id: tray

            theme: theme
            parentWindow: panel
            barItem: bar
        }

        Rectangle {
            id: bar

            y: theme.panelTopMargin
            anchors.horizontalCenter: parent.horizontalCenter

            // Two layouts share this pill. At rest it holds the workspace pills,
            // the clock and the status row, sized to their real widths plus a
            // fixed gap on each side of the clock. The old formula multiplied
            // max(workspaces, status) by two to keep the clock centred, which
            // reserved ~55px of nothing to the right of three workspace pills.
            readonly property real restingWidth: theme.space16 + workspaceRow.implicitWidth + theme.space20
                                                + clock.implicitWidth + theme.space20
                                                + statusRow.implicitWidth + theme.space12

            // Whichever presenter currently owns the pill decides how wide it
            // gets. Both presenters are permanent children of the bar, so their
            // implicitWidths are always live and reading one that is not
            // showing is harmless.
            //
            // width itself must never get a Behavior: it is derived from morph,
            // so animating it would make the width chase the cross-fade and
            // arrive late. activeWidth, the target it is heading for, is a
            // different matter and does need one. morph deliberately holds at 1
            // when the channel changes under a pill that is already taken -- an
            // OSD arriving over a notification, or the queue stepping to its next
            // item -- and since width reads morph as a factor, a target that
            // jumped would snap the pill sideways mid-morph. Gliding the target
            // instead means those handovers resize the pill rather than teleport
            // it, while an arrival is still purely morph's business.
            //
            // Not declared readonly, because QML refuses to attach a Behavior to
            // a readonly property. Nothing assigns to it; the binding below is
            // the only writer, and the Behavior sits in front of that binding.
            property real activeWidth: island.presentingOsd ? osd.implicitWidth
                                       : island.presentingNotif ? notif.implicitWidth
                                       : restingWidth

            Behavior on activeWidth {
                NumberAnimation {
                    // Same length and easing as island's own morph Behavior, so
                    // on an arrival the two run in step and the width stays a
                    // smooth function of time rather than the product of two
                    // mismatched curves.
                    duration: theme.motionLong
                    easing.type: Easing.InOutCubic
                }
            }

            width: restingWidth + (activeWidth - restingWidth) * island.morph
            height: theme.barHeight
            radius: theme.radiusExtraLarge
            // surfaceContainerLowest rather than surfaceContainer, because the
            // pill has no outline to define it any more. surfaceContainer is
            // #201f21, which is *lighter* than most of this wallpaper set, so
            // the pill and the wallpaper behind it sat within a few luminance
            // levels of each other and the edge vanished. Going to the lowest
            // surface puts the pill darker than the wallpaper instead of
            // marginally lighter, which is the direction that contrasts on a
            // dark image; on a light one it is further away, not closer.
            //
            // The contents are on_surface (#e5e2e3) and primary, both of which
            // are far lighter than either fill, so legibility is unaffected.
            color: theme.surfaceContainerLowest
            // No border. The 1px outlineVariant hairline this replaced was not
            // white -- it resolved to #46464c -- but it was 45 levels brighter
            // than the wallpaper behind the bar, which is why it read as one.
            //
            // It was also the only thing drawing the pill's edge on a dark
            // wallpaper: the fill is #201f21 and most of this wallpaper set is
            // darker than that, so the pill's outline is now just whatever the
            // fill contrasts against. Fine on a light wallpaper, not on a dark
            // one. A drop shadow is no answer to that -- a black one is
            // invisible against a dark wallpaper by definition.

            // Half of the morph each: the bar's own contents are fully gone by
            // the time a presenter becomes visible, so there is never a moment
            // where both are legible at once.
            readonly property real ownOpacity: Math.max(0, 1 - island.morph * 2)

            Row {
                id: workspaceRow

                visible: opacity > 0.01
                opacity: bar.ownOpacity
                anchors.left: parent.left
                anchors.leftMargin: theme.space16
                anchors.verticalCenter: parent.verticalCenter
                spacing: theme.space4

                Repeater {
                    model: services.workspaces.slotCount

                    delegate: WorkspacePill {
                        required property int index

                        theme: shell.palette
                        workspaceService: services.workspaces
                        workspaceIndex: index + 1
                        active: services.workspaces.isActive(index + 1)
                        occupied: services.workspaces.isOccupied(index + 1)
                    }

                }

            }

            Clock {
                id: clock

                visible: opacity > 0.01
                opacity: bar.ownOpacity
                // Sits just past the pills rather than centred in the pill, so
                // the space on each side is the space it actually needs.
                anchors.left: workspaceRow.right
                anchors.leftMargin: theme.space20
                anchors.verticalCenter: parent.verticalCenter
                theme: theme
            }

            Row {
                id: statusRow

                visible: opacity > 0.01
                opacity: bar.ownOpacity
                anchors.right: parent.right
                anchors.rightMargin: theme.space12
                anchors.verticalCenter: parent.verticalCenter
                spacing: theme.space4

                NetworkIndicator {
                    id: networkTrigger

                    // Sized by the component, like the other two cells in this
                    // row, so the height is stated once rather than overridden
                    // here and left to drift against the pill.
                    theme: theme
                    networkService: services.network
                    expanded: shell.openSurface === "network"
                    onClicked: shell.toggleSurface("network")
                }

                BatteryIndicator {
                    theme: theme
                    batteryService: services.battery
                }

                M3Button {
                    id: dashboardTrigger

                    // M3Button's own 40x40 is for a dialog button. The use site
                    // sizes it to the row, which is 22 to match the indicators.
                    width: 22
                    height: 22
                    theme: theme
                    radius: 11
                    containerColor: shell.openSurface === "dashboard" ? theme.primaryContainer : "transparent"
                    stateLayerColor: shell.openSurface === "dashboard" ? theme.primaryContainerOn : theme.surfaceOn
                    onClicked: shell.toggleSurface("dashboard")

                    MaterialIcon {
                        anchors.centerIn: parent
                        theme: theme
                        icon: "dashboard_customize"
                        iconColor: shell.openSurface === "dashboard" ? theme.primaryContainerOn : theme.surfaceOn
                        iconSize: 16
                    }

                }

            }

            // Both presenters are siblings of the bar's own contents, not
            // popups: while either is visible the rows above are at opacity 0,
            // so the pill shows nothing but the readout. That is the whole
            // reason the OSD was moved in here, and it is now equally true of
            // notifications.
            // Second half of the morph, which is what brings a presenter in.
            //
            // osdReveal lives on the island, which owns the OSD channel and can
            // therefore tell an OSD on its way off from a notification that has
            // just finished. It used to be computed here from island.morph
            // alone, which could not: morph is 1 for either channel, so the
            // moment a notification closed this read 1 and the OSD flashed in at
            // full opacity with osdData already null, drawing its default volume
            // icon and an empty track.
            Osd {
                id: osd

                anchors.fill: parent
                visible: opacity > 0.01
                opacity: island.osdReveal
                theme: theme
                osdData: island.osdData

                // Same second half of the morph, so the row slides in exactly
                // as it brightens rather than arriving already in place.
                reveal: island.osdReveal
            }

            // Only the OSD runs off morph, so a notification arriving while an
            // OSD is up would have nowhere to put itself. This one is driven by
            // the island's own reveal value instead, which lets it fade out
            // under a preempting OSD and fade back in when that OSD expires,
            // even though morph never moves across the handover.
            NotificationBar {
                id: notif

                anchors.fill: parent
                visible: opacity > 0.01
                opacity: island.notifReveal
                theme: theme
                eventData: island.eventData
                reveal: island.notifReveal
            }

        }


        // The surface's input region, and the reason the tray's clicks used to
        // do nothing at all.
        //
        // A Region here is not a clip: it is the wl_surface input region, so
        // anything outside it never receives pointer events from the compositor
        // -- not hover, not press, nothing. It was set to the bar alone, and the
        // tray is a *sibling* of the bar rather than a child of it, so the
        // whole tray sat outside the region. That is why the tray's own MouseArea
        // never fired even a hover handler, while the bar's buttons highlighted
        // and worked perfectly: they were inside the region and it was not.
        //
        // Hence the list. Both pills have to be named, and the default property
        // is `regions`, so each is declared as a Region of its own. The
        // intersection is left at its default, Identity, which unions them --
        // Structure would intersect them to nothing, since the two rects do not
        // overlap.
        //
        // The tray's own `visible: reveal > 0.01` means a retracted tray
        // contributes no region, so the input area shrinks with the pill.
        mask: Region {
            regions: [
                Region { item: bar },
                Region { item: tray }
            ]
        }

    }

    // Click-away surface for the two bar-anchored menus, using the same trick
    // as the launcher: a surface covering the screen whose only job is to catch
    // the clicks that miss the menu. Nothing grabs here -- it is a layer-shell
    // surface sitting above the windows, so ordinary hit-testing is enough, and
    // the scrim is fully transparent so it darkens nothing.
    //
    // Anchored to all four edges, but it does *not* begin at y = 0. The bar
    // holds an exclusive zone of barHeight + panelTopMargin, which pushes this
    // surface clear of it, so it lands flush under the bar and the bar stays
    // live while a menu is open: the button that opened the menu can still
    // close it, and the other one can still switch straight to it. A scrim
    // that covered the bar would have swallowed both of those clicks. Verified
    // with `hyprctl layers`, which reports this surface at y = 40.
    //
    // This is what the two PopupWindows could not do. A popup only covers its
    // own rect, so a scrim inside one can never see a click outside the menu --
    // which is why those two had no click-away at all. Widening them to the
    // screen was not an option either: a *grabbing* popup over a layer-shell
    // parent is refused by the compositor outright, and these are the surfaces
    // that were already forced to stay non-grabbing.
    PanelWindow {
        id: menuLayer

        // Stays up while a menu is still sliding back up. Tying this to
        // openSurface alone took the whole window away the instant a menu was
        // dismissed, which is the same as having no closing animation at all:
        // the surface was unmapped mid-slide. Each menu's own `reveal` outlives
        // the state change by the length of its animation, so the window waits
        // for both to reach zero.
        visible: shell.openSurface !== "" || networkMenu.reveal > 0.01 || dashboardMenu.reveal > 0.01
        color: "transparent"
        // The bar already owns the exclusive zone that keeps this surface
        // underneath it; claiming one here too would reserve the same strip
        // twice.
        exclusiveZone: 0
        // Focusable so the wifi password field can actually receive keys: the
        // window has to hold keyboard focus, not just the TextInput's own item
        // focus. Focus is taken when a surface opens, via onOpenSurfaceChanged
        // above, and returned to the user's window when the menu closes. Set
        // false before, the field was a dead cursor.
        focusable: true

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        // Escape closes, from anywhere in the layer, not just wherever the focus
        // happens to be sitting.
        //
        // A Shortcut rather than a Keys handler because it is the one that does
        // not need an item to hold focus first, but it still needs this window
        // to own the keyboard -- hence the forceActiveFocus on open.
        Shortcut {
            sequence: "Escape"
            // While the password prompt is up it owns Escape: one press should
            // dismiss the prompt and leave the menu standing, rather than
            // throwing away the whole thing along with the half-typed
            // passphrase. The field's own Keys.onEscapePressed does the
            // cancelling, so this stands aside and lets it. A shortcut is
            // matched ahead of item key handling, so both would otherwise run
            // on the same press.
            enabled: networkMenu.passwordTarget === null
            onActivated: shell.openSurface = ""
        }

        // The click-away. Declared first so both cards sit above it and get
        // first refusal on every click.
        //
        // Disabled the moment a menu stops being the open one, so a surface
        // that is on its way back up does not go on swallowing clicks meant for
        // whatever is underneath it.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            enabled: shell.openSurface !== ""
            onClicked: shell.openSurface = ""
        }

        // x is the screen centre rather than the old
        // `bar.x + bar.width / 2 - width / 2`. The bar is itself centred, so
        // the two agree exactly, and this stays correct if the bar ever moves.
        // y = 0 is the bar's bottom edge, for the same reason the surface
        // starts there -- which makes y = 0 the rest position of the slide
        // below, and y = -height the retracted one.
        //
        // Each menu sits in a full-surface wrapper that does the clipping,
        // because the menus retract to a negative y and this surface's top edge
        // is the bar's bottom edge. A PanelWindow is a Window and has no `clip`
        // of its own, and a bare window relies on the compositor trimming to
        // the surface bounds -- which is very likely doing that already, but
        // this way the menu is guaranteed to come out from under the bar rather
        // than over it. The wrapper never moves, so the clip line stays put
        // while the menu slides through it.
        Item {
            anchors.fill: parent
            clip: true
            visible: networkMenu.reveal > 0.01

            NetworkDropdown {
                id: networkMenu

                x: (menuLayer.width - width) / 2
                y: -height * (1 - reveal)
                width: implicitWidth
                height: implicitHeight
                opacity: reveal
                // Driven off reveal rather than off openSurface, so the menu
                // keeps existing for the length of its slide instead of
                // vanishing on the frame the state changes.
                reveal: shell.openSurface === "network" ? 1 : 0
                theme: theme
                networkService: services.network
            }

        }

        Item {
            anchors.fill: parent
            clip: true
            visible: dashboardMenu.reveal > 0.01

            Dashboard {
                id: dashboardMenu

                x: (menuLayer.width - width) / 2
                y: -height * (1 - reveal)
                width: implicitWidth
                height: implicitHeight
                opacity: reveal
                reveal: shell.openSurface === "dashboard" ? 1 : 0
                theme: theme
                services: services
            }

        }

    }

    // Volume and brightness OSDs. These arrive either from the IPC push above or
    // from the services' 150ms delta watchers, and land on the island's OSD
    // channel, which replaces in place rather than queueing.
    Connections {
        function onOsdRequested(icon, title, progress) {
            island.showOsd(icon, "Volume", title, progress);
        }

        target: services.audio
    }

    Connections {
        function onOsdRequested(icon, title, progress) {
            island.showOsd(icon, "Brightness", title, progress);
        }

        target: services.brightness
    }

    Connections {
        function onNotificationReceived(notification) {
            island.enqueueNotification(notification);
        }

        target: services.notifications
    }

    Connections {
        function onChargerEvent(charging, percentage) {
            island.enqueue(charging ? "power" : "battery_horiz_075", charging ? "Charging started" : "On battery", percentage + "%", -1);
        }

        target: services.battery
    }

    Connections {
        function onConnectionEvent(connected, name) {
            island.enqueue(connected ? "wifi" : "wifi_off", connected ? "Network connected" : "Network disconnected", name, -1);
        }

        target: services.network
    }

}
