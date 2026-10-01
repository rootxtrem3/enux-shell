import QtQuick

// The OSD lives inside the bar pill rather than floating in its own surface.
// shell.qml hides the workspace pills, clock and status row while this is up
// and resizes the bar to implicitWidth, so a volume or brightness change looks
// like the bar swapping itself out for the readout instead of a second widget
// appearing under it. That also keeps the exclusive zone stable: a popup that
// grew past the bar would have shifted every window on the screen.
Item {
    id: root

    property var theme

    // Whatever DynamicIsland.showOsd() was handed. null means the OSD is idle.
    property var osdData

    // 0 -> 1 across the second half of the island's morph, so the row arrives
    // from the left while it brightens instead of popping in already in place.
    property real reveal: 1

    // The bar is about to shrink to fit this, so the pill should not jump
    // further than it has to; 274 keeps it close to the resting bar's width.
    property int levelWidth: 150

    readonly property real progress: osdData && osdData.progress >= 0
        ? Math.max(0, Math.min(1, osdData.progress)) : 0

    implicitWidth: theme.space16 + 20 + theme.space12 + levelWidth + theme.space12 + 46 + theme.space16
    implicitHeight: theme.barHeight

    Row {
        id: row

        // Explicit geometry rather than anchors.fill, because the row slides.
        x: root.theme.space16 - (1 - root.reveal) * 16
        y: 0
        width: parent.width - root.theme.space16 * 2
        height: parent.height
        spacing: root.theme.space12

        MaterialIcon {
            id: icon

            width: 20
            anchors.verticalCenter: parent.verticalCenter
            theme: root.theme
            icon: root.osdData ? root.osdData.icon : "volume_up"
            iconColor: root.theme.primary
            iconSize: 20
        }

        Rectangle {
            id: level

            width: root.levelWidth
            height: 4
            radius: 2
            anchors.verticalCenter: parent.verticalCenter
            color: root.theme.surfaceContainerHighest

            Rectangle {
                id: fill

                width: parent.width * root.progress
                height: parent.height
                radius: parent.radius
                color: root.theme.primary

                Behavior on width {
                    NumberAnimation {
                        duration: root.theme.motionShort
                        easing.type: Easing.OutCubic
                    }
                }

            }

        }

        Text {
            width: 46
            anchors.verticalCenter: parent.verticalCenter
            text: root.osdData ? root.osdData.body : ""
            color: root.theme.surfaceOn
            font.family: root.theme.mediumFamily
            font.pixelSize: root.theme.bodyMedium
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }

    }

}
