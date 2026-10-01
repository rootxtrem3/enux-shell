import QtQuick

// The island is state only. It owns two channels and decides which one is
// allowed to present, but it draws nothing: the pill is a single surface, and
// the bar hosts whichever presenter is active as a sibling of its own resting
// contents. That is why an OSD does not stack a second surface under the bar,
// and it is now equally true of notifications.
//
//   OSD          state only. Presented by components/Osd.qml inside the pill.
//                Still a single replace-in-place slot, never queued, so holding
//                a volume key updates one readout instead of stacking a
//                duplicate behind every keypress.
//   notification a FIFO of transient events, drained one at a time, presented by
//                components/NotificationBar.qml inside the same pill.
//
// An OSD preempts whatever is showing and the paused notification resumes
// afterwards. The reverse does not hold: a notification arriving mid-OSD waits
// in the queue rather than interrupting, which is what stops a burst of
// notifications from making the OSD flicker.
//
// Neither presenter is allowed to grow the pill past the bar's height. The bar
// sits in a fixed exclusive zone, so anything taller would shift every window
// on the screen.
Item {
    id: root

    property var theme

    // Notification FIFO.
    property var queuedEvents: []
    property var eventData: null

    // OSD channel.
    property var osdData: null

    readonly property bool osdActive: osdData !== null
    readonly property bool notifActive: eventData !== null
    readonly property bool active: osdActive || notifActive

    // Which channel is allowed on screen. A paused notification is still
    // `notifActive`, so precedence has to be resolved here rather than at the
    // call site, otherwise an OSD arriving over a notification would leave both
    // presenters mounted and fully opaque in the same pill.
    readonly property bool presentingOsd: osdActive
    readonly property bool presentingNotif: notifActive && !osdActive

    // 0 while the bar shows its own contents, 1 while a presenter owns the pill.
    //
    // This is deliberately a single animated value rather than two independent
    // opacity animations on either side. The bar derives its width from it and
    // splits it: the resting contents clear out across the first half, the
    // presenter arrives across the second. Because both halves read the same
    // number, the two can never drift out of step and produce a frame where the
    // bar is showing a half-faded clock under a half-faded readout.
    //
    // Either channel drives it. A notification takes the pill exactly the way an
    // OSD does.
    property real morph: 0

    onActiveChanged: morph = active ? 1 : 0

    Behavior on morph {
        NumberAnimation {
            // Long enough that the width change reads as one movement rather
            // than a jump, and eased at both ends because the bar travels out
            // and back rather than setting off from rest.
            duration: theme.motionLong
            easing.type: Easing.InOutCubic
        }
    }

    // The notification presenter's own arrival, tracked separately from morph.
    //
    // morph deliberately does not move when an OSD preempts a notification: the
    // pill is already taken and its resting contents are already cleared, so
    // re-running the morph would only make the bar twitch. Without a value of
    // its own the notification would have to cut out on the spot and cut back in
    // when the OSD expired. This gives it a fade either way, while morph stays
    // put underneath.
    property real notifReveal: 0

    onPresentingNotifChanged: {
        notifReveal = presentingNotif ? 1 : 0;

        // A notification taking the pill back means the OSD was cut mid-fade, not
        // that it finished one. Dropping the latch here stops it flashing back in
        // when this notification later expires.
        if (presentingNotif && !osdActive)
            osdHeld = false;
    }

    Behavior on notifReveal {
        NumberAnimation {
            duration: theme.motionLong
            easing.type: Easing.InOutCubic
        }
    }

    // The OSD's arrival, split off from morph.
    //
    // Reading (morph - 0.5) * 2 straight off morph is wrong on its own, because
    // morph drops to 0 when *either* channel ends. The instant a notification
    // timed out, that expression reads 1 -- the OSD's full arrival -- while
    // osdData was already null. The OSD duly rendered its defaults, a bare
    // volume icon and an empty 150px track, at full opacity for the whole of the
    // fade. That was the flash that appeared every time a notification closed.
    //
    // osdHeld is the latch that says the OSD is the thing on the pill, or is on
    // its way off having been it. Set when the OSD channel opens; cleared on
    // either of the two ways the OSD can stop being shown.
    readonly property real osdSlide: Math.max(0, (morph - 0.5) * 2)

    property bool osdHeld: false

    onOsdActiveChanged: if (osdActive)
        osdHeld = true

    // Only once the OSD is no longer the active channel. Guarding on osdActive
    // matters: morph eases in, so the first frame of an arriving OSD sits at
    // ~0.000x and would otherwise trip this and drop the latch while the OSD
    // was still on its way in -- leaving the OSD to cut instead of fade the
    // moment it expired.
    onOsdSlideChanged: if (!osdActive && osdSlide <= 0.001)
        osdHeld = false

    // A notification resuming means the OSD was cut mid-fade rather than having
    // finished one. Without this the latch would still be set from that cut, and
    // the OSD would flash straight back in when the notification later expired.
    //
    // Folded into the notifReveal handler below rather than declared as a second
    // onPresentingNotifChanged: QML rejects a signal handler set twice on the
    // same object ("Property value set multiple times"), which takes the whole
    // config down.
    // Gated on presentingNotif rather than on osdActive, so that a preempted OSD
    // is still cut cleanly when its timer runs out: by then the notification is
    // presenting again, and the OSD has to yield to it rather than fade out
    // under a pill it no longer owns.
    readonly property real osdReveal: presentingNotif
        ? 0
        : (osdActive || osdHeld ? osdSlide : 0)

    // Replaces the current OSD and restarts its dismiss timer. Repeated calls for
    // the same channel are idempotent, which is what makes a held key feel like
    // one continuous readout.
    function showOsd(icon, title, body, progress) {
        osdData = {
            "icon": icon,
            "title": title,
            "body": body === undefined ? "" : body,
            "progress": progress === undefined ? -1 : progress
        };
        // Pause the notification countdown so it does not expire underneath.
        notificationTimer.stop();
        osdTimer.restart();
    }

    function enqueue(icon, title, body, progress) {
        queuedEvents = queuedEvents.concat([{
            "icon": icon,
            "title": title,
            "body": body,
            "progress": progress === undefined ? -1 : progress
        }]);
        if (!eventData && !osdActive)
            advance();
    }

    function enqueueNotification(notification) {
        enqueue("notifications", notification.summary || notification.appName || "Notification", notification.body, -1);
    }

    function advance() {
        if (queuedEvents.length > 0) {
            eventData = queuedEvents[0];
            queuedEvents = queuedEvents.slice(1);
            notificationTimer.restart();
        } else {
            eventData = null;
        }
    }

    Timer {
        id: notificationTimer

        interval: 3600
        onTriggered: root.advance()
    }

    Timer {
        id: osdTimer

        interval: 1600
        onTriggered: {
            root.osdData = null;

            // Hand the island back to the notification channel: resume the one
            // that was interrupted, or start draining the queue.
            if (root.eventData !== null)
                notificationTimer.restart();
            else
                root.advance();
        }
    }

}
