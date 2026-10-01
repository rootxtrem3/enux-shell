import QtQuick

Item {
    id: root

    property var theme
    property var batteryService

    function iconForLevel() {
        if (batteryService.charging)
            return "battery_charging_full";

        if (batteryService.percentage <= 15)
            return "battery_horiz_000";

        if (batteryService.percentage <= 45)
            return "battery_horiz_050";

        if (batteryService.percentage <= 75)
            return "battery_horiz_075";

        return "battery_horiz_075";
    }

    implicitWidth: batteryText.implicitWidth + batteryIcon.width + 7
    implicitHeight: 22

    MaterialIcon {
        id: batteryIcon

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        theme: root.theme
        icon: root.iconForLevel()
        iconColor: root.batteryService.percentage <= 15 ? root.theme.error : root.theme.surfaceOn
        iconSize: 18
    }

    Text {
        id: batteryText

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: batteryIcon.right
        anchors.leftMargin: 4
        text: root.batteryService.ready ? root.batteryService.percentage + "%" : "—"
        color: root.theme.surfaceVariantOn
        font.family: root.theme.mediumFamily
        font.pixelSize: root.theme.labelMedium
    }

}
