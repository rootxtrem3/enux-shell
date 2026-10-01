import QtQuick
import "cards"

Item {
    id: root

    property var theme
    property var services

    implicitWidth: 448
    implicitHeight: 512

    // 1 = at rest, 0 = retracted up behind the bar. shell.qml binds this to
    // whether this is the open surface and drives y and opacity off it, so the
    // slide in and the slide back both run off one number. See the note on the
    // same property in NetworkDropdown.qml.
    property real reveal: 0

    Behavior on reveal {
        NumberAnimation {
            duration: root.theme.motionMedium
            easing.type: Easing.OutCubic
        }

    }

    // Swallow clicks that land on the dashboard's own bare background. The
    // click-away behind it covers the whole screen, and a plain Rectangle does
    // not accept pointer events, so a click on the gap beside the cards would
    // otherwise fall through and dismiss the whole dashboard.
    //
    // Declared first so it sits underneath the Flickable and the cards inside
    // it. It holds no press drags, so the Flickable keeps scrolling -- it only
    // wins the gesture once the pointer moves, at which point this is no longer
    // a click.
    MouseArea {
        anchors.fill: parent
    }

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radiusLarge
        color: root.theme.surfaceContainer
        border.width: 1
        border.color: root.theme.outlineVariant
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: root.theme.space12
        clip: true
        contentWidth: width
        contentHeight: cards.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: cards

            width: parent.width
            spacing: root.theme.space12

            ToggleCard {
                width: parent.width
                theme: root.theme
                services: root.services
            }

            ResourceCard {
                width: parent.width
                theme: root.theme
                statsService: root.services.stats
            }

            PowerCard {
                width: parent.width
                theme: root.theme
                powerService: root.services.power
            }

            NotificationsCard {
                width: parent.width
                theme: root.theme
                notificationService: root.services.notifications
            }

        }

    }

}
