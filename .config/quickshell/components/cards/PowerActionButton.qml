import ".."
import QtQuick

M3Button {
    id: root

    property string iconName: "power_settings_new"
    property string label: "Power"
    property bool destructive: false
    property bool armed: false

    signal confirmed()

    implicitWidth: 68
    implicitHeight: 64
    radius: theme.radiusMedium
    containerColor: armed ? (destructive ? theme.errorContainer : theme.primaryContainer) : "transparent"
    borderColor: armed ? "transparent" : theme.outlineVariant
    stateLayerColor: armed ? (destructive ? theme.error : theme.primaryContainerOn) : theme.surfaceOn
    onClicked: {
        if (destructive && !armed) {
            armed = true;
            confirmationTimer.restart();
        } else {
            armed = false;
            confirmationTimer.stop();
            confirmed();
        }
    }

    Timer {
        id: confirmationTimer

        interval: 2500
        onTriggered: root.armed = false
    }

    Column {
        anchors.centerIn: parent
        spacing: 3

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            theme: root.theme
            icon: root.iconName
            iconColor: root.armed && root.destructive ? root.theme.error : (root.armed ? root.theme.primaryContainerOn : root.theme.surfaceOn)
            iconSize: 20
        }

        Text {
            width: root.width - 6
            text: root.armed ? "Confirm" : root.label
            color: root.armed && root.destructive ? root.theme.error : (root.armed ? root.theme.primaryContainerOn : root.theme.surfaceOn)
            font.family: root.theme.mediumFamily
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

    }

}
