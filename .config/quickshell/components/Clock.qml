import QtQuick
import Quickshell

Item {
    id: root

    property var theme

    implicitWidth: timeLabel.implicitWidth
    // The bar is theme.barHeight tall. 22 rather than something derived from
    // the font, so the clock's box is the same as the status buttons' and both
    // centre in the pill on the same line.
    implicitHeight: 22

    SystemClock {
        id: systemClock

        precision: SystemClock.Minutes
        enabled: true
    }

    Text {
        id: timeLabel

        anchors.centerIn: parent
        text: String(systemClock.hours).padStart(2, "0") + ":" + String(systemClock.minutes).padStart(2, "0")
        color: root.theme.surfaceOn
        font.family: root.theme.mediumFamily
        font.pixelSize: root.theme.labelLarge
        font.weight: Font.Bold
        font.letterSpacing: 0.3
    }

}
