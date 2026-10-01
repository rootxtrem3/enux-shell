import QtQuick

// The notification presenter for the bar pill. Deliberately the same shape as
// components/Osd.qml: an icon, then one line of text, filling the pill and
// arriving on the second half of the island's morph.
//
// It is not the old two-line card shrunk down. The pill is theme.barHeight tall
// and the bar's exclusive zone is fixed to that, so there is no room for a
// heading over a body without either clipping the text or growing the bar and
// shifting every window on the screen. Instead the heading takes the line and
// the body is dropped: on a 26px pill a notification reads as "something
// happened, this is what it was" rather than a summary plus a paragraph.
//
// The progress track from the card is kept, because the battery and network
// events pass one and it is the only part of those that carries information the
// heading does not.
Item {
    id: root

    property var theme

    // Whatever DynamicIsland.enqueue() was handed. null means this presenter is
    // idle and the bar is showing its own contents.
    property var eventData

    // 0 -> 1 as the pill is handed over, so the line slides in exactly as it
    // brightens instead of popping in already in place.
    property real reveal: 1

    // Dips when the queue hands over to its next item.
    //
    // That handover never touches reveal: the pill is already taken, so
    // presentingNotif stays true and the island has no reason to move. The
    // consequence is that the text would be replaced on the spot. The card this
    // presenter replaced had a Behavior on its own opacity, so consecutive
    // notifications used to cross-fade and going back to a hard swap would be a
    // regression, not a simplification.
    property real contentReveal: 1

    onEventDataChanged: {
        // Only a swap, never an arrival. On arrival reveal is still climbing and
        // the presenter is fading in anyway, so dipping as well would just make
        // the fade-in lurch.
        if (root.reveal > 0.01) {
            contentReveal = 0;
            swapTimer.restart();
        }
    }

    Timer {
        id: swapTimer

        interval: root.theme.motionShort
        onTriggered: root.contentReveal = 1
    }

    Behavior on contentReveal {
        NumberAnimation {
            duration: root.theme.motionShort
            easing.type: Easing.OutCubic
        }
    }

    readonly property real progress: eventData && eventData.progress >= 0
        ? Math.max(0, Math.min(1, eventData.progress)) : 0
    readonly property bool hasProgress: eventData && eventData.progress >= 0

    readonly property int levelWidth: 64

    // Fitted to the heading so the pill is never wider than the text it has to
    // show -- a reserved slot leaves a hole on the right whenever the summary is
    // shorter than the slot, which reads as a layout bug rather than as padding.
    //
    // Measured with TextMetrics rather than read off the Text itself. Using the
    // Text's implicitWidth means binding it from the heading while binding the
    // heading's width back from that same value; elide makes the implicit width
    // depend on the constraint, so the two chase each other and settle a few
    // pixels short, which showed up as the text running under the right inset.
    // TextMetrics measures the string with no width constraint, so it cannot
    // feed back. The cap keeps one long summary from stretching the bar across
    // the screen; past it the heading elides as usual.
    readonly property int textWidth: Math.max(90, Math.min(260, Math.ceil(metrics.width)))

    implicitWidth: theme.space16 + 20 + theme.space12 + textWidth
        + (hasProgress ? theme.space12 + levelWidth : 0) + theme.space16
    implicitHeight: theme.barHeight

    TextMetrics {
        id: metrics

        font.family: root.theme.mediumFamily
        font.pixelSize: root.theme.bodyMedium
        font.weight: Font.DemiBold
        text: root.eventData ? root.eventData.title : ""
    }

    Row {
        id: row

        // Explicit geometry rather than anchors.fill, because the row slides.
        x: root.theme.space16 - (1 - root.reveal) * 16
        y: 0
        width: parent.width - root.theme.space16 * 2
        height: parent.height
        spacing: root.theme.space12
        opacity: root.contentReveal

        MaterialIcon {
            width: 20
            anchors.verticalCenter: parent.verticalCenter
            theme: root.theme
            icon: root.eventData ? root.eventData.icon : "notifications"
            iconColor: root.theme.primary
            iconSize: 20
        }

        Text {
            id: heading

            width: root.textWidth
            anchors.verticalCenter: parent.verticalCenter
            // Heading only. The body is dropped rather than elided into a
            // trailing "...": a truncated fragment of a message body is noise,
            // and at this width it would be all that survives anyway.
            text: root.eventData ? root.eventData.title : ""
            color: root.theme.surfaceOn
            font.family: root.theme.mediumFamily
            font.pixelSize: root.theme.bodyMedium
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            width: root.levelWidth
            height: 4
            radius: 2
            visible: root.hasProgress
            anchors.verticalCenter: parent.verticalCenter
            color: root.theme.surfaceContainerHighest

            Rectangle {
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

    }

}
