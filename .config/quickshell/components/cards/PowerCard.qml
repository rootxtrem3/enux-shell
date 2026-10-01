import ".."
import QtQuick

Item {
    id: root

    property var theme
    property var powerService

    // Just the row of actions. The other three cards in the dashboard keep a
    // heading because what they hold needs one; this one is five buttons whose
    // labels each say what they do, so a "Power" heading on top only repeated
    // the two buttons already labelled "Power off" and "Inhibited".
    //
    // 16 of margin either side of a 64px row, which is what the height was
    // before the heading took 19px of itself and a space12 of gap below it.
    implicitHeight: 96

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radiusLarge
        color: root.theme.surfaceContainerHigh
    }

    Column {
        anchors.fill: parent
        anchors.margins: root.theme.space16
        // No spacing, with a single child to space it from. The card's height
        // comes from the row alone, so there is nothing for a gap to separate.

        Row {
            width: parent.width
            height: 64
            spacing: (width - 5 * 68) / 4

            PowerActionButton {
                width: 68
                height: 64
                theme: root.theme
                iconName: "bedtime"
                label: "Sleep"
                onConfirmed: root.powerService.sleep()
            }

            PowerActionButton {
                width: 68
                height: 64
                theme: root.theme
                iconName: "lock"
                label: "Lock"
                onConfirmed: root.powerService.lock()
            }

            PowerActionButton {
                width: 68
                height: 64
                theme: root.theme
                iconName: root.powerService.idleInhibited ? "timer_off" : "timer"
                // A state, not an action, so it does not read like the three
                // buttons around it -- every other label here is what the button
                // does, and "Idle off" as a verb-less phrase beside "Lock" and
                // "Restart" read as a fourth action rather than as the current
                // condition.
                label: root.powerService.idleInhibited ? "Inhibited" : "Idle"
                containerColor: root.powerService.idleInhibited ? root.theme.primaryContainer : "transparent"
                // Must go through the setter: idleInhibited is readonly, so
                // assigning to it here failed at runtime and the button did
                // nothing at all.
                onConfirmed: root.powerService.setIdleInhibited(!root.powerService.idleInhibited)
            }

            PowerActionButton {
                width: 68
                height: 64
                theme: root.theme
                iconName: "restart_alt"
                label: "Restart"
                destructive: true
                onConfirmed: root.powerService.restart()
            }

            PowerActionButton {
                width: 68
                height: 64
                theme: root.theme
                iconName: "power_settings_new"
                label: "Power off"
                destructive: true
                onConfirmed: root.powerService.powerOff()
            }

        }

    }

}
