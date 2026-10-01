import QtQuick

M3Button {
    id: root

    property int workspaceIndex: 1
    property bool active: false
    property bool occupied: false
    property var workspaceService

    // The requested previous-strip pill treatment, fixed to three slots.
    implicitWidth: active ? 30 : 15
    implicitHeight: 12
    radius: 6
    containerColor: active ? theme.primary : theme.outline
    borderColor: "transparent"
    stateLayerColor: theme.surfaceOn
    opacity: active ? 1 : (occupied ? 0.82 : 0.45)
    onClicked: workspaceService.activate(workspaceIndex)

    Behavior on implicitWidth {
        NumberAnimation {
            duration: theme.motionMedium
            easing.type: Easing.OutCubic
        }

    }

}
