import Quickshell
import QtQuick

// Full-screen wallpaper browser, one window per output. Like the launcher this
// is a full-screen scrim rather than one of the shell's bar-anchored popups.
Variants {
    id: pickerRoot

    property var theme
    property var services

    model: Quickshell.screens

    delegate: PanelWindow {
        id: pickerWindow

        required property var modelData

        screen: modelData
        visible: pickerShown
        color: "transparent"
        focusable: true
        exclusiveZone: 0

        property bool pickerShown: false

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        Rectangle {
            id: backdrop

            anchors.fill: parent
            // Deliberately invisible. This is here to be clicked, not to be
            // seen: the picker is a card floating over the desktop, and
            // matugen's scrim token is a literal #000000, so the 0.3 this used
            // to carry darkened the wallpaper it was meant to be showing off.
            // The card is opaque enough on its own.
            color: "transparent"

            Keys.onEscapePressed: pickerRoot.services.wallpaper.hide()

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: pickerRoot.services.wallpaper.hide()
            }

        }

        Item {
            id: cardWrap

            anchors.top: parent.top
            anchors.topMargin: 44
            anchors.horizontalCenter: parent.horizontalCenter
            width: 820
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
                radius: pickerRoot.theme.radiusLarge
                color: pickerRoot.theme.alpha(pickerRoot.theme.surface, 0.97)
                border.width: 1
                border.color: pickerRoot.theme.alpha(pickerRoot.theme.outline, 0.35)

                Column {
                    anchors.fill: parent
                    anchors.margins: pickerRoot.theme.space20
                    spacing: pickerRoot.theme.space12

                    Row {
                        width: parent.width
                        height: 26

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Wallpapers"
                            color: pickerRoot.theme.surfaceOn
                            font.family: pickerRoot.theme.mediumFamily
                            font.pixelSize: pickerRoot.theme.titleMedium
                            font.weight: Font.DemiBold
                        }

                        Item {
                            width: parent.width - 180
                            height: 1
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: pickerRoot.services.wallpaper.status || pickerRoot.services.wallpaper.folderName()
                            color: pickerRoot.theme.surfaceOn
                            font.family: pickerRoot.theme.mediumFamily
                            font.pixelSize: pickerRoot.theme.bodyMedium
                        }

                    }

                    Row {
                        width: parent.width
                        height: 26
                        // Row owns the x of every child, so the gap after the
                        // Back button comes from spacing rather than anchors.
                        spacing: 16

                        M3Button {
                            width: 60
                            height: 24
                            anchors.verticalCenter: parent.verticalCenter
                            theme: pickerRoot.theme
                            radius: pickerRoot.theme.radiusSmall
                            enabled: !pickerRoot.services.wallpaper.isAtRoot()
                            containerColor: "transparent"
                            stateLayerColor: pickerRoot.theme.surfaceOn
                            onClicked: pickerRoot.services.wallpaper.goBack()

                            Text {
                                anchors.centerIn: parent
                                text: "← Back"
                                color: pickerRoot.theme.surfaceOn
                                font.family: pickerRoot.theme.mediumFamily
                                font.pixelSize: pickerRoot.theme.labelMedium
                            }

                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 76
                            text: pickerRoot.services.wallpaper.isAtRoot() ? "~/Pictures/Wallpapers" : pickerRoot.services.wallpaper.currentDir.replace(/\/$/, "")
                            color: pickerRoot.theme.surfaceOn
                            font.family: pickerRoot.theme.mediumFamily
                            font.pixelSize: pickerRoot.theme.bodyMedium
                            elide: Text.ElideLeft
                        }

                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: pickerRoot.theme.alpha(pickerRoot.theme.outline, 0.35)
                    }

                    GridView {
                        id: grid

                        width: parent.width
                        height: 426
                        cellWidth: 128
                        cellHeight: 128
                        // Keep a band of off-screen tiles alive so async decodes
                        // finish and get reused instead of being abandoned.
                        cacheBuffer: cellHeight * 6
                        clip: true
                        focus: true
                        activeFocusOnTab: true
                        keyNavigationEnabled: false
                        highlightFollowsCurrentItem: true

                        highlight: Rectangle {
                            radius: pickerRoot.theme.radiusMedium
                            color: pickerRoot.theme.alpha(pickerRoot.theme.primary, 0.16)
                            border.width: 1
                            border.color: pickerRoot.theme.alpha(pickerRoot.theme.primary, 0.5)
                        }
                        highlightMoveDuration: 120

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_PageDown || event.key === Qt.Key_Backspace) {
                                pickerRoot.services.wallpaper.goBack();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                stepSelection(0, -1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down) {
                                stepSelection(0, 1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Left) {
                                stepSelection(-1, 0);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Right) {
                                stepSelection(1, 0);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                activateCurrent();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                pickerRoot.services.wallpaper.hide();
                                event.accepted = true;
                            }
                        }

                        function stepSelection(dx, dy) {
                            const count = grid.count;
                            if (!count)
                                return ;

                            const columns = Math.max(1, Math.floor(grid.width / grid.cellWidth));
                            const rows = Math.ceil(count / columns);
                            let row = Math.floor(grid.currentIndex / columns);
                            let column = grid.currentIndex % columns;
                            let nextRow = row + dy;
                            let nextColumn = column + dx;
                            if (nextColumn < 0) {
                                nextColumn = columns - 1;
                                nextRow--;
                            }
                            if (nextColumn >= columns) {
                                nextColumn = 0;
                                nextRow++;
                            }
                            if (nextRow < 0)
                                nextRow = rows - 1;

                            if (nextRow >= rows)
                                nextRow = 0;

                            grid.currentIndex = Math.max(0, Math.min(count - 1, nextRow * columns + nextColumn));
                        }

                        function activateCurrent() {
                            const item = grid.model[grid.currentIndex];
                            if (!item)
                                return ;

                            if (item.type === "folder")
                                pickerRoot.services.wallpaper.navigateTo(item.path);
                            else
                                pickerRoot.services.wallpaper.choose(item.path);
                        }

                        function indexOfCurrent() {
                            const current = pickerRoot.services.wallpaper.currentImage;
                            for (let i = 0; i < grid.count; i++) {
                                const entry = grid.model[i];
                                if (entry && entry.type === "image" && entry.path === current)
                                    return i;

                            }
                            return 0;
                        }

                        onModelChanged: currentIndex = 0

                        Connections {
                            target: pickerRoot.services.wallpaper

                            function onOpenChanged() {
                                // Qualified: a Connections block does not pick up
                                // the enclosing object's own function declarations.
                                if (pickerRoot.services.wallpaper.open)
                                    grid.currentIndex = grid.indexOfCurrent();

                            }
                        }

                        model: pickerRoot.services.wallpaper.folders.map(path => {
                            return {
                                "path": path,
                                "type": "folder"
                            };
                        }).concat(pickerRoot.services.wallpaper.images.map(path => {
                            return {
                                "path": path,
                                "type": "image"
                            };
                        }))

                        delegate: Rectangle {
                            id: tile

                            required property var modelData

                            width: 116
                            height: 116
                            radius: pickerRoot.theme.radiusMedium
                            color: tileMouse.containsMouse || GridView.isCurrentItem ? pickerRoot.theme.alpha(pickerRoot.theme.primary, 0.22) : pickerRoot.theme.surfaceContainerLow

                            Behavior on color {
                                ColorAnimation {
                                    duration: pickerRoot.theme.motionShort
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Image {
                                id: thumb

                                anchors.fill: parent
                                anchors.margins: 4
                                source: tile.modelData.type === "image" ? "file://" + pickerRoot.services.wallpaper.thumbnailOf(tile.modelData.path).split("/").map(encodeURIComponent).join("/") : ""
                                fillMode: Image.PreserveAspectCrop
                                visible: tile.modelData.type === "image"
                                asynchronous: true
                                sourceSize: Qt.size(Math.round(grid.cellWidth * 2), Math.round(grid.cellWidth * 2))
                                smooth: false
                                // Decoded thumbnails (small) stay in the RHI atlas,
                                // so reopen and scroll are instant.
                                cache: true

                                // Fall back to the full-res original when no cached
                                // thumbnail exists for this wallpaper.
                                onStatusChanged: {
                                    if (status === Image.Error) {
                                        if (!thumb.usedFallback) {
                                            thumb.usedFallback = true;
                                            thumb.source = "file://" + tile.modelData.path.split("/").map(encodeURIComponent).join("/");
                                        }
                                    } else if (status === Image.Ready) {
                                        thumb.usedFallback = false;
                                    }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 4
                                visible: tile.modelData.type === "folder"
                                color: pickerRoot.theme.alpha(pickerRoot.theme.primary, 0.12)
                                border.width: 1
                                border.color: pickerRoot.theme.alpha(pickerRoot.theme.primary, 0.4)

                                Column {
                                    anchors.centerIn: parent
                                    spacing: pickerRoot.theme.space8

                                    Rectangle {
                                        width: 34
                                        height: 26
                                        radius: 4
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: pickerRoot.theme.primary

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            theme: pickerRoot.theme
                                            icon: "arrow_forward"
                                            iconColor: pickerRoot.theme.primaryOn
                                            iconSize: 16
                                        }

                                    }

                                    Text {
                                        text: "OPEN"
                                        color: pickerRoot.theme.surfaceOn
                                        font.family: pickerRoot.theme.mediumFamily
                                        font.pixelSize: pickerRoot.theme.labelMedium
                                        font.weight: Font.DemiBold
                                    }

                                }

                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 6
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 5
                                width: parent.width - 12
                                text: tile.modelData.type === "folder" ? tile.modelData.path.split("/").pop() : "Apply"
                                color: pickerRoot.theme.surfaceOn
                                font.family: pickerRoot.theme.mediumFamily
                                font.pixelSize: pickerRoot.theme.labelMedium
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Rectangle {
                                width: 10
                                height: 10
                                radius: 5
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 6
                                visible: tile.modelData.type === "image" && pickerRoot.services.wallpaper.isCurrent(tile.modelData.path)
                                color: pickerRoot.theme.primary
                                border.width: 2
                                border.color: pickerRoot.theme.surface
                            }

                            MouseArea {
                                id: tileMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (tile.modelData.type === "folder")
                                        pickerRoot.services.wallpaper.navigateTo(tile.modelData.path);
                                    else
                                        pickerRoot.services.wallpaper.choose(tile.modelData.path);
                                }
                            }

                        }

                        Text {
                            anchors.centerIn: parent
                            visible: grid.count === 0
                            text: "Empty folder"
                            color: pickerRoot.theme.surfaceVariantOn
                            opacity: 0.7
                            font.family: pickerRoot.theme.fontFamily
                            font.pixelSize: pickerRoot.theme.bodyMedium
                        }

                    }

                }

            }

        }

        Connections {
            target: pickerRoot.services.wallpaper

            function onOpenChanged() {
                pickerWindow.onOpenToggled();
            }
        }

        SequentialAnimation {
            id: openAnim

            onStarted: {
                pickerShown = true;
                cardShift.y = -40;
                cardWrap.scale = 0.94;
                card.opacity = 0;
            }
            ParallelAnimation {
                NumberAnimation {
                    target: cardShift
                    property: "y"
                    to: 0
                    duration: pickerRoot.theme.motionLong
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: card
                    property: "opacity"
                    to: 1
                    duration: pickerRoot.theme.motionMedium
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: cardWrap
                    property: "scale"
                    to: 1
                    duration: pickerRoot.theme.motionLong
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.1
                }
            }
            ScriptAction {
                script: grid.forceActiveFocus()
            }
        }

        SequentialAnimation {
            id: closeAnim

            ParallelAnimation {
                NumberAnimation {
                    target: cardShift
                    property: "y"
                    to: -28
                    duration: pickerRoot.theme.motionShort
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: cardWrap
                    property: "scale"
                    to: 0.95
                    duration: pickerRoot.theme.motionShort
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: card
                    property: "opacity"
                    to: 0
                    duration: pickerRoot.theme.motionShort
                    easing.type: Easing.InCubic
                }
            }
            ScriptAction {
                script: pickerShown = false
            }
        }

        function onOpenToggled() {
            if (pickerRoot.services.wallpaper.open) {
                closeAnim.stop();
                openAnim.restart();
            } else if (pickerShown) {
                openAnim.stop();
                closeAnim.restart();
            }
        }

    }

}
