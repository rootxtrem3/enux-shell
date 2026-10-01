import Quickshell
import QtQuick

// Full-screen launcher, one window per output. It is deliberately not part of
// the shell's `openSurface` state: that string drives bar-anchored popups, while
// this is a scrim that owns the whole screen and takes keyboard focus.
Variants {
    id: launcherRoot

    property var theme
    property var services

    model: Quickshell.screens

    delegate: PanelWindow {
        id: launcherWindow

        required property var modelData

        screen: modelData
        visible: launcherShown
        color: "transparent"
        focusable: true
        exclusiveZone: 0

        property bool launcherShown: false

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        Rectangle {
            id: backdrop

            anchors.fill: parent
            // Deliberately invisible. This is here to be clicked, not to be
            // seen: the launcher is a card floating over the desktop, and
            // anything behind it only darkened the wallpaper. matugen's scrim
            // token is a literal #000000, so even the 0.3 this used to carry
            // read as a grey veil rather than as depth. The card is 0.97-opaque
            // surface and does not need anything behind it.
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: launcherRoot.services.launcher.closeLauncher()
            }

        }

        Item {
            id: cardWrap

            anchors.top: parent.top
            anchors.topMargin: 44
            anchors.horizontalCenter: parent.horizontalCenter
            width: 640
            height: 560

            transformOrigin: Item.Top
            transform: [
                Translate {
                    id: cardShift
                    y: 0
                }
            ]

            Rectangle {
                id: card

                anchors.fill: parent
                radius: launcherRoot.theme.radiusLarge
                color: launcherRoot.theme.alpha(launcherRoot.theme.surface, 0.97)
                border.width: 1
                border.color: launcherRoot.theme.alpha(launcherRoot.theme.outline, 0.35)

                Column {
                    id: cardColumn

                    anchors.fill: parent
                    anchors.margins: launcherRoot.theme.space20
                    spacing: launcherRoot.theme.space12

                    Row {
                        width: parent.width
                        height: 26

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Launcher"
                            color: launcherRoot.theme.surfaceOn
                            font.family: launcherRoot.theme.mediumFamily
                            font.pixelSize: launcherRoot.theme.titleMedium
                            font.weight: Font.DemiBold
                        }

                        Item {
                            width: parent.width - 250
                            height: 1
                        }

                        M3Button {
                            width: 54
                            height: 26
                            anchors.verticalCenter: parent.verticalCenter
                            theme: launcherRoot.theme
                            radius: launcherRoot.theme.radiusSmall
                            containerColor: launcherRoot.services.launcher.mode === "apps" ? launcherRoot.theme.primaryContainer : "transparent"
                            stateLayerColor: launcherRoot.services.launcher.mode === "apps" ? launcherRoot.theme.primaryContainerOn : launcherRoot.theme.surfaceOn
                            onClicked: launcherRoot.services.launcher.mode = "apps"

                            Text {
                                anchors.centerIn: parent
                                text: "Apps"
                                color: launcherRoot.services.launcher.mode === "apps" ? launcherRoot.theme.primaryContainerOn : launcherRoot.theme.surfaceOn
                                font.family: launcherRoot.theme.mediumFamily
                                font.pixelSize: launcherRoot.theme.labelMedium
                            }

                        }

                        M3Button {
                            width: 48
                            height: 26
                            anchors.verticalCenter: parent.verticalCenter
                            theme: launcherRoot.theme
                            radius: launcherRoot.theme.radiusSmall
                            containerColor: launcherRoot.services.launcher.mode === "run" ? launcherRoot.theme.primaryContainer : "transparent"
                            stateLayerColor: launcherRoot.services.launcher.mode === "run" ? launcherRoot.theme.primaryContainerOn : launcherRoot.theme.surfaceOn
                            onClicked: launcherRoot.services.launcher.mode = "run"

                            Text {
                                anchors.centerIn: parent
                                text: "Run"
                                color: launcherRoot.services.launcher.mode === "run" ? launcherRoot.theme.primaryContainerOn : launcherRoot.theme.surfaceOn
                                font.family: launcherRoot.theme.mediumFamily
                                font.pixelSize: launcherRoot.theme.labelMedium
                            }

                        }

                        M3Button {
                            width: 28
                            height: 26
                            anchors.verticalCenter: parent.verticalCenter
                            theme: launcherRoot.theme
                            radius: launcherRoot.theme.radiusSmall
                            containerColor: "transparent"
                            stateLayerColor: launcherRoot.theme.surfaceOn
                            onClicked: launcherRoot.services.launcher.closeLauncher()

                            MaterialIcon {
                                anchors.centerIn: parent
                                theme: launcherRoot.theme
                                icon: "close"
                                iconColor: launcherRoot.theme.surfaceOn
                                iconSize: 16
                            }

                        }

                    }

                    Rectangle {
                        width: parent.width
                        height: 40
                        radius: launcherRoot.theme.radiusSmall
                        color: launcherRoot.theme.surfaceContainerLow
                        border.width: searchField.activeFocus ? 1 : 0
                        border.color: launcherRoot.theme.primary

                        Row {
                            anchors.fill: parent
                            anchors.margins: launcherRoot.theme.space12
                            spacing: launcherRoot.theme.space8

                            MaterialIcon {
                                width: 18
                                anchors.verticalCenter: parent.verticalCenter
                                theme: launcherRoot.theme
                                icon: "search"
                                iconColor: launcherRoot.theme.surfaceVariantOn
                                iconSize: 18
                            }

                            TextInput {
                                id: searchField

                                width: parent.width - 26
                                anchors.verticalCenter: parent.verticalCenter
                                color: launcherRoot.theme.surfaceOn
                                selectionColor: launcherRoot.theme.primary
                                selectedTextColor: launcherRoot.theme.primaryOn
                                font.family: launcherRoot.theme.mediumFamily
                                font.pixelSize: launcherRoot.theme.bodyMedium
                                clip: true

                                text: launcherRoot.services.launcher.query
                                onTextChanged: launcherRoot.services.launcher.query = text

                                Keys.onEscapePressed: {
                                    launcherRoot.services.launcher.closeLauncher();
                                    event.accepted = true;
                                }
                                Keys.onReturnPressed: {
                                    executeSelected();
                                    event.accepted = true;
                                }
                                Keys.onUpPressed: {
                                    stepSelection(0, -1);
                                    event.accepted = true;
                                }
                                Keys.onDownPressed: {
                                    stepSelection(0, 1);
                                    event.accepted = true;
                                }
                                Keys.onLeftPressed: {
                                    stepSelection(-1, 0);
                                    event.accepted = true;
                                }
                                Keys.onRightPressed: {
                                    stepSelection(1, 0);
                                    event.accepted = true;
                                }
                            }

                        }

                    }

                    Item {
                        width: parent.width
                        // 560 card, minus space20 margins top and bottom, minus the
                        // 26px header, 40px search field and three space12 gaps.
                        height: 418

                        Loader {
                            id: contentLoader

                            anchors.fill: parent
                            source: launcherRoot.services.launcher.mode === "apps" ? "AppGrid.qml" : "RunMode.qml"
                            onLoaded: {
                                if (item) {
                                    item.theme = launcherRoot.theme;
                                    item.launcherService = launcherRoot.services.launcher;
                                }
                            }
                        }

                    }

                }

            }

        }

        function focusSearch() {
            searchField.forceActiveFocus();
            searchField.selectAll();
        }

        function executeSelected() {
            if (launcherRoot.services.launcher.mode === "apps") {
                const grid = contentLoader.item;
                const entry = grid && grid.model[grid.currentIndex];
                if (entry) {
                    launcherRoot.services.launcher.launchEntry(entry);
                    launcherRoot.services.launcher.closeLauncher();
                }

            } else {
                const run = contentLoader.item;
                if (run)
                    run.run(searchField.text);

            }
        }

        function stepSelection(dx, dy) {
            if (launcherRoot.services.launcher.mode !== "apps")
                return ;

            const grid = contentLoader.item;
            if (!grid || grid.count === 0)
                return ;

            grid.stepSelection(dx, dy);
        }

        Connections {
            target: launcherRoot.services.launcher

            function onOpenChanged() {
                launcherWindow.onOpenToggled();
            }
        }

        SequentialAnimation {
            id: openAnim

            onStarted: {
                launcherShown = true;
                cardShift.y = -40;
                cardWrap.scale = 0.94;
                card.opacity = 0;
            }
            ParallelAnimation {
                NumberAnimation {
                    target: cardShift
                    property: "y"
                    to: 0
                    duration: launcherRoot.theme.motionLong
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: card
                    property: "opacity"
                    to: 1
                    duration: launcherRoot.theme.motionMedium
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: cardWrap
                    property: "scale"
                    to: 1
                    duration: launcherRoot.theme.motionLong
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.1
                }
            }
            ScriptAction {
                script: focusSearch()
            }
        }

        SequentialAnimation {
            id: closeAnim

            ParallelAnimation {
                NumberAnimation {
                    target: cardShift
                    property: "y"
                    to: -28
                    duration: launcherRoot.theme.motionShort
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: cardWrap
                    property: "scale"
                    to: 0.95
                    duration: launcherRoot.theme.motionShort
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: card
                    property: "opacity"
                    to: 0
                    duration: launcherRoot.theme.motionShort
                    easing.type: Easing.InCubic
                }
            }
            ScriptAction {
                script: launcherShown = false
            }
        }

        function onOpenToggled() {
            if (launcherRoot.services.launcher.open) {
                closeAnim.stop();
                openAnim.restart();
            } else if (launcherShown) {
                openAnim.stop();
                closeAnim.restart();
            }
        }

    }

}
