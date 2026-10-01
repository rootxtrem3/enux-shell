import ".."
import QtQuick

Item {
    id: root

    property var theme
    property var services

    implicitHeight: 202

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radiusLarge
        color: root.theme.surfaceContainerHigh
    }

    Column {
        anchors.fill: parent
        anchors.margins: root.theme.space16
        spacing: root.theme.space12

        Text {
            text: "Quick settings"
            color: root.theme.surfaceOn
            font.family: root.theme.mediumFamily
            font.pixelSize: root.theme.titleMedium
            font.weight: Font.DemiBold
        }

        Row {
            width: parent.width
            height: 54
            spacing: root.theme.space8

            // Four across, so each takes a quarter of the row less three gaps.
            // Every button below divides by 4 with spacing * 3; if one ever
            // changes, all four have to.
            M3Button {
                width: (parent.width - parent.spacing * 3) / 4
                height: parent.height
                theme: root.theme
                radius: root.theme.radiusMedium
                containerColor: root.services.network.wifiEnabled ? root.theme.primaryContainer : root.theme.surfaceContainer
                stateLayerColor: root.services.network.wifiEnabled ? root.theme.primaryContainerOn : root.theme.surfaceOn
                onClicked: root.services.network.setWifiEnabled(!root.services.network.wifiEnabled)

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    MaterialIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        theme: root.theme
                        // Off reads as off rather than as a working link that
                        // simply has no networks, which is what a bare "wifi"
                        // glyph would say.
                        icon: root.services.network.wifiEnabled ? "wifi" : "wifi_off"
                        iconColor: root.services.network.wifiEnabled ? root.theme.primaryContainerOn : root.theme.surfaceOn
                        iconSize: 21
                    }

                    Text {
                        text: "Wi-Fi"
                        color: root.services.network.wifiEnabled ? root.theme.primaryContainerOn : root.theme.surfaceOn
                        font.family: root.theme.mediumFamily
                        font.pixelSize: root.theme.labelMedium
                        horizontalAlignment: Text.AlignHCenter
                    }

                }

            }

            M3Button {
                width: (parent.width - parent.spacing * 3) / 4
                height: parent.height
                theme: root.theme
                radius: root.theme.radiusMedium
                // With no adapter there is nothing to switch, so the button says
                // so instead of taking clicks that go nowhere.
                enabled: root.services.bluetooth.available
                opacity: root.services.bluetooth.available ? 1 : 0.45
                containerColor: root.services.bluetooth.enabled ? root.theme.primaryContainer : root.theme.surfaceContainer
                stateLayerColor: root.services.bluetooth.enabled ? root.theme.primaryContainerOn : root.theme.surfaceOn
                onClicked: root.services.bluetooth.setEnabled(!root.services.bluetooth.enabled)

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    MaterialIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        theme: root.theme
                        icon: root.services.bluetooth.available ? "bluetooth" : "bluetooth_disabled"
                        iconColor: root.services.bluetooth.enabled ? root.theme.primaryContainerOn : root.theme.surfaceOn
                        iconSize: 21
                    }

                    Text {
                        text: root.services.bluetooth.available ? "Bluetooth" : "No adapter"
                        color: root.services.bluetooth.enabled ? root.theme.primaryContainerOn : root.theme.surfaceOn
                        font.family: root.theme.mediumFamily
                        font.pixelSize: root.theme.labelMedium
                        horizontalAlignment: Text.AlignHCenter
                    }

                }

            }

            M3Button {
                width: (parent.width - parent.spacing * 3) / 4
                height: parent.height
                theme: root.theme
                radius: root.theme.radiusMedium
                containerColor: root.services.notifications.doNotDisturb ? root.theme.primaryContainer : root.theme.surfaceContainer
                stateLayerColor: root.services.notifications.doNotDisturb ? root.theme.primaryContainerOn : root.theme.surfaceOn
                onClicked: root.services.notifications.doNotDisturb = !root.services.notifications.doNotDisturb

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    MaterialIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        theme: root.theme
                        icon: "do_not_disturb_on"
                        iconColor: root.services.notifications.doNotDisturb ? root.theme.primaryContainerOn : root.theme.surfaceOn
                        iconSize: 21
                    }

                    Text {
                        text: "Do not disturb"
                        color: root.services.notifications.doNotDisturb ? root.theme.primaryContainerOn : root.theme.surfaceOn
                        font.family: root.theme.mediumFamily
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                    }

                }

            }

            M3Button {
                width: (parent.width - parent.spacing * 3) / 4
                height: parent.height
                theme: root.theme
                radius: root.theme.radiusMedium
                containerColor: root.services.audio.muted ? root.theme.surfaceContainer : root.theme.primaryContainer
                stateLayerColor: root.services.audio.muted ? root.theme.surfaceOn : root.theme.primaryContainerOn
                onClicked: root.services.audio.setMuted(!root.services.audio.muted)

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    MaterialIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        theme: root.theme
                        icon: root.services.audio.muted ? "volume_off" : "volume_up"
                        iconColor: root.services.audio.muted ? root.theme.surfaceOn : root.theme.primaryContainerOn
                        iconSize: 21
                    }

                    Text {
                        text: "Sound"
                        color: root.services.audio.muted ? root.theme.surfaceOn : root.theme.primaryContainerOn
                        font.family: root.theme.mediumFamily
                        font.pixelSize: root.theme.labelMedium
                    }

                }

            }

        }

        Row {
            width: parent.width
            height: 28
            spacing: root.theme.space8

            MaterialIcon {
                width: 22
                height: parent.height
                theme: root.theme
                icon: root.services.audio.muted ? "volume_off" : "volume_up"
                iconColor: root.theme.surfaceVariantOn
                iconSize: 19
            }

            VolumeSlider {
                width: parent.width - 68
                height: parent.height
                theme: root.theme
                audioService: root.services.audio
            }

            Text {
                width: 38
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                text: root.services.audio.muted ? "Off" : Math.round(root.services.audio.volume * 100) + "%"
                color: root.theme.surfaceVariantOn
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.labelMedium
            }

        }

        Row {
            width: parent.width
            height: 28
            spacing: root.theme.space8

            MaterialIcon {
                width: 22
                height: parent.height
                theme: root.theme
                icon: "brightness_6"
                iconColor: root.theme.surfaceVariantOn
                iconSize: 19
            }

            BrightnessSlider {
                width: parent.width - 68
                height: parent.height
                theme: root.theme
                brightnessService: root.services.brightness
            }

            Text {
                width: 38
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                text: root.services.brightness.brightnessPath.length > 0 ? Math.round(root.services.brightness.fraction * 100) + "%" : "—"
                color: root.theme.surfaceVariantOn
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.labelMedium
            }

        }

    }

}
