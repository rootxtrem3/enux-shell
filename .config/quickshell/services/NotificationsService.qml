import QtQuick
import Quickshell.Services.Notifications

Item {
    id: root

    property bool doNotDisturb: false
    readonly property var notifications: notificationServer.trackedNotifications
    property var knownNotifications: []
    property var timestamps: ({
    })

    signal notificationReceived(var notification)

    function timestampFor(notification) {
        return timestamps[notification.id] || "Now";
    }

    function dismissAll() {
        const items = knownNotifications.slice(0);
        for (let index = 0; index < items.length; index++) items[index].dismiss()
    }

    visible: false
    width: 0
    height: 0

    NotificationServer {
        id: notificationServer

        keepOnReload: true
        bodyMarkupSupported: false
        actionsSupported: false
        onNotification: (notification) => {
            notification.tracked = true;
            if (root.knownNotifications.indexOf(notification) === -1)
                root.knownNotifications = root.knownNotifications.concat([notification]);

            const nextTimestamps = root.timestamps;
            nextTimestamps[notification.id] = new Date().toLocaleTimeString(Qt.locale(), "HH:mm");
            root.timestamps = nextTimestamps;
            if (!root.doNotDisturb)
                root.notificationReceived(notification);

        }
    }

}
