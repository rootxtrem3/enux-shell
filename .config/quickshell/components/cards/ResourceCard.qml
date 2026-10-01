import ".."
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var theme
    property var statsService

    function percent(value) {
        return Math.round(value * 100) + "%";
    }

    // Just the dials: a 12px margin top and bottom around one 60px row. The
    // "Resources" heading and the network ring are both gone, which took this
    // from 268px -- the tallest card in the dashboard, for four numbers -- to
    // 84px. What is left is three percentages, and it says so by being three
    // dials in a row with nothing above them.
    implicitHeight: 12 + 60 + 12

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radiusLarge
        color: root.theme.surfaceContainerHighest
    }

    // One row of three rather than 2x2. With the network ring gone there are
    // three readings, and a 2x2 grid would leave an empty fourth cell; a
    // 3-wide row also costs one row instead of two, which is most of the height
    // that came back. Each cell measures 125px, of which the dial takes 60 and
    // the label and reading share the rest -- a percentage and a short word are
    // the two shortest strings on the card, so they are the last things that
    // need the width the rates did.
    GridLayout {
        anchors.fill: parent
        anchors.margins: root.theme.space12
        columns: 3
        columnSpacing: root.theme.space12

        ResourceStat {
            Layout.fillWidth: true
            theme: root.theme
            icon: "memory"
            label: "CPU"
            detail: root.percent(root.statsService.cpu)
            value: root.statsService.cpu
        }

        ResourceStat {
            Layout.fillWidth: true
            theme: root.theme
            icon: "developer_board"
            label: "RAM"
            detail: root.percent(root.statsService.memory)
            value: root.statsService.memory
        }

        ResourceStat {
            Layout.fillWidth: true
            theme: root.theme
            icon: "hard_drive"
            label: "Disk"
            detail: root.percent(root.statsService.disk)
            value: root.statsService.disk
        }

    }

}
