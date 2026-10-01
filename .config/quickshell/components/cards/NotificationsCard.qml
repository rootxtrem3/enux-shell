import ".."
import QtQuick

Item {
    id: root

    property var theme
    property var notificationService

    implicitHeight: 258

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radiusLarge
        color: root.theme.surfaceContainer
    }

    Text {
        id: header

        anchors.left: parent.left
        anchors.leftMargin: root.theme.space16
        anchors.top: parent.top
        anchors.topMargin: root.theme.space16
        text: "Notifications"
        color: root.theme.surfaceOn
        font.family: root.theme.mediumFamily
        font.pixelSize: root.theme.titleMedium
        font.weight: Font.DemiBold
    }

    M3Button {
        anchors.right: parent.right
        anchors.rightMargin: root.theme.space12
        anchors.verticalCenter: header.verticalCenter
        width: 76
        height: 30
        theme: root.theme
        radius: 15
        containerColor: "transparent"
        borderColor: root.theme.outlineVariant
        onClicked: root.notificationService.dismissAll()

        MaterialIcon {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            theme: root.theme
            icon: "clear_all"
            iconColor: root.theme.surfaceOn
            iconSize: 17
        }

        Text {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: 9
            text: "Clear"
            color: root.theme.surfaceOn
            font.family: root.theme.mediumFamily
            font.pixelSize: root.theme.labelMedium
        }

    }

    Flickable {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.margins: root.theme.space12
        clip: true
        contentWidth: width
        contentHeight: notificationList.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: notificationList

            width: parent.width
            spacing: root.theme.space4

            Repeater {
                model: root.notificationService.notifications

                delegate: Item {
                    property var notification: modelData

                    width: notificationList.width
                    height: Math.max(54, notificationBody.implicitHeight + 18)

                    Rectangle {
                        anchors.fill: parent
                        radius: root.theme.radiusSmall
                        color: root.theme.surfaceContainerHigh
                    }

                    MaterialIcon {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        theme: root.theme
                        icon: "notifications"
                        iconColor: root.theme.primary
                        iconSize: 18
                    }

                    Column {
                        id: notificationBody

                        anchors.left: parent.left
                        anchors.leftMargin: 34
                        anchors.right: closeButton.left
                        anchors.rightMargin: 4
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        spacing: 2

                        Text {
                            width: parent.width
                            text: notification.summary || notification.appName || "Notification"
                            color: root.theme.surfaceOn
                            font.family: root.theme.mediumFamily
                            font.pixelSize: root.theme.bodySmall
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }

                        Text {
                            width: parent.width
                            visible: notification.body.length > 0
                            text: notification.body
                            color: root.theme.surfaceVariantOn
                            font.family: root.theme.fontFamily
                            font.pixelSize: 11
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }

                        Text {
                            text: root.notificationService.timestampFor(notification)
                            color: root.theme.outline
                            font.family: root.theme.fontFamily
                            font.pixelSize: 10
                        }

                    }

                    M3Button {
                        id: closeButton

                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        width: 28
                        height: 28
                        theme: root.theme
                        radius: 14
                        containerColor: "transparent"
                        onClicked: notification.dismiss()

                        MaterialIcon {
                            anchors.centerIn: parent
                            theme: root.theme
                            icon: "close"
                            iconColor: root.theme.surfaceVariantOn
                            iconSize: 17
                        }

                    }

                }

            }

            Text {
                width: parent.width
                visible: root.notificationService.notifications.values.length === 0
                text: "Nothing new"
                color: root.theme.surfaceVariantOn
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.bodyMedium
                horizontalAlignment: Text.AlignHCenter
                topPadding: 36
            }

        }

    }

}
