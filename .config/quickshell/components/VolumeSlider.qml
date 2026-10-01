import QtQuick

Item {
    id: root

    property var theme
    property var audioService
    readonly property real displayedValue: audioService ? Math.min(1, audioService.volume) : 0

    implicitWidth: 160
    implicitHeight: 36

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: 6
        radius: 3
        color: root.theme.surfaceContainerHighest
    }

    Rectangle {
        anchors.verticalCenter: track.verticalCenter
        anchors.left: track.left
        width: track.width * root.displayedValue
        height: track.height
        radius: track.radius
        color: root.theme.primary

        Behavior on width {
            NumberAnimation {
                duration: root.theme.motionShort
                easing.type: Easing.OutCubic
            }

        }

    }

    Rectangle {
        x: track.x + track.width * root.displayedValue - width / 2
        anchors.verticalCenter: track.verticalCenter
        width: 16
        height: 16
        radius: 8
        color: root.theme.primary
        scale: drag.pressed ? 1.16 : (drag.containsMouse ? 1.08 : 1)

        Behavior on scale {
            NumberAnimation {
                duration: root.theme.motionShort
                easing.type: Easing.OutCubic
            }

        }

    }

    MouseArea {
        id: drag

        function update(position) {
            if (root.audioService)
                root.audioService.setVolume(Math.max(0, Math.min(1, position / root.width)));

        }

        anchors.fill: parent
        hoverEnabled: true
        onPressed: (mouse) => {
            return update(mouse.x);
        }
        onPositionChanged: (mouse) => {
            if (pressed)
                update(mouse.x);

        }
    }

}
