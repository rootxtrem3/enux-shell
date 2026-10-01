import QtQuick

Item {
    id: root

    property var theme
    property color containerColor: theme ? theme.surfaceContainerHigh : "transparent"
    property color stateLayerColor: theme ? theme.surfaceOn : "transparent"
    property color borderColor: "transparent"
    property int radius: theme ? theme.radiusMedium : 16
    property bool enabled: true
    readonly property bool hovered: pointer.containsMouse
    readonly property bool pressed: pointer.pressed
    default property alias content: content.data

    signal clicked()
    signal pressAndHold()

    implicitWidth: 40
    implicitHeight: 40
    opacity: enabled ? 1 : 0.38

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.containerColor
        border.width: root.borderColor === "transparent" ? 0 : 1
        border.color: root.borderColor

        Behavior on color {
            ColorAnimation {
                duration: root.theme ? root.theme.motionShort : 140
                easing.type: Easing.OutCubic
            }

        }

        Behavior on border.color {
            ColorAnimation {
                duration: root.theme ? root.theme.motionShort : 140
                easing.type: Easing.OutCubic
            }

        }

    }

    Item {
        id: content

        anchors.fill: parent
        enabled: root.enabled
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.stateLayerColor
        opacity: pointer.pressed ? 0.12 : (pointer.containsMouse ? 0.08 : 0)

        Behavior on opacity {
            NumberAnimation {
                duration: root.theme ? root.theme.motionShort : 140
                easing.type: Easing.OutCubic
            }

        }

    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        onClicked: root.clicked()
        onPressAndHold: root.pressAndHold()
    }

}
