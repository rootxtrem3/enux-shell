import QtQuick

M3Button {
    id: root

    property var networkService
    property bool expanded: false

    function iconForState() {
        // A live cable outranks the radio. NetworkManager keeps a wifi profile
        // connected alongside the wired link, so the radio state says nothing
        // useful while the cable is the one carrying traffic.
        if (networkService.usingEthernet)
            return "lan";

        if (!networkService.wifiEnabled)
            return "wifi_off";

        if (!networkService.connected)
            return "wifi_find";

        return "wifi";
    }

    // Sized here rather than overridden at the use site: the bar's height is
    // theme.barHeight, and 22 leaves 2px of padding inside the pill, which is
    // what every other cell in the status row is set to.
    implicitWidth: 28
    implicitHeight: 22
    radius: 11
    containerColor: expanded ? theme.primaryContainer : "transparent"
    stateLayerColor: expanded ? theme.primaryContainerOn : theme.surfaceOn

    MaterialIcon {
        anchors.centerIn: parent
        theme: root.theme
        icon: root.iconForState()
        iconColor: root.expanded ? root.theme.primaryContainerOn : root.theme.surfaceOn
        iconSize: 18
    }

}
