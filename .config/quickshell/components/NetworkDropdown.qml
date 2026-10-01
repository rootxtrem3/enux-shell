import QtQuick
import Quickshell.Networking

Item {
    id: root

    property var theme
    property var networkService
    property var passwordTarget: null

    signal closeRequested()

    implicitWidth: 372
    implicitHeight: 420

    // 1 = at rest, 0 = retracted up behind the bar. shell.qml binds this to
    // whether this is the open surface and drives y and opacity off it, so the
    // slide in and the slide back both run off one number.
    //
    // The Behaviour lives here rather than at the use site so that a re-target
    // mid-flight eases from wherever it had got to instead of jumping. That is
    // what makes opening the dashboard while the network menu is out work: the
    // two animate at the same time, each on its own value.
    property real reveal: 0

    Behavior on reveal {
        NumberAnimation {
            duration: root.theme.motionMedium
            easing.type: Easing.OutCubic
        }

    }

    // The refresh glyph's angle, held here rather than animated straight onto the
    // icon so that the icon's `rotation` can be a *binding*. It has to be: the
    // 250ms scan is shorter than one 900ms turn, so the loop is always
    // interrupted at an arbitrary angle, and an imperative animation leaves the
    // glyph parked there -- it used to stop dead at 100 degrees and stay there.
    // Binding to 0 while idle puts it back upright, and because 360 is the same
    // orientation as 0 the loop boundary itself is invisible.
    property real refreshSpin: 0

    NumberAnimation on refreshSpin {
        running: root.networkService.scanning
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: 900
    }

    // Wired up to Enter and Escape on the field as well as the two buttons, so
    // the prompt can be answered without reaching for the mouse.
    function acceptPassword() {
        if (root.passwordTarget)
            root.passwordTarget.connectWithPsk(passwordInput.text);

        root.passwordTarget = null;
        passwordInput.text = "";
    }

    function cancelPassword() {
        root.passwordTarget = null;
        passwordInput.text = "";
    }

    // The prompt is the last child, so it paints over the list -- but painting
    // over something does not stop it being hit-tested. Forcing the field's
    // focus the moment a target is set is what actually puts a cursor in it; the
    // `focus:` binding on its own is not enough for a field that appears in
    // response to a click somewhere else entirely.
    onPasswordTargetChanged: if (passwordTarget !== null)
        Qt.callLater(passwordInput.forceActiveFocus)

    // Swallow clicks that land on the menu's own bare background.
    //
    // The click-away behind this menu is a MouseArea covering the whole screen,
    // and a plain Rectangle does not accept pointer events, so without this a
    // click on the padding around the wifi list would fall straight through and
    // close the menu. "Away" should mean away, not "anywhere that is not a
    // control".
    //
    // Declared before everything else so it sits underneath them: every control
    // below is a later sibling and so still gets first refusal on its own area.
    // A MouseArea holding no press drags, so the Flickable further down keeps
    // its scrolling -- it only wins the gesture once the pointer actually
    // moves, at which point this stops being a click anyway.
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

    Column {
        anchors.fill: parent
        anchors.margins: root.theme.space16
        spacing: root.theme.space12
        // Everything in here is covered by the password prompt once that is up,
        // but "covered" only affects painting, not hit-testing: a click on the
        // prompt's own padding would otherwise land on a network row or on
        // Disconnect, both of which are still live underneath. One flag takes
        // the lot out of play. The prompt's own controls live outside this
        // Column, so they are unaffected.
        enabled: root.passwordTarget === null

        Row {
            width: parent.width
            height: 32
            // Spacing does the horizontal work here. anchors.leftMargin inside a
            // Row is applied inconsistently -- the title Column's was honoured,
            // the refresh button's was silently dropped -- which left the pair of
            // buttons floating ~39px short of the right edge.
            spacing: root.theme.space8

            MaterialIcon {
                width: 22
                height: 22
                anchors.verticalCenter: parent.verticalCenter
                theme: root.theme
                icon: root.networkService.usingEthernet ? "lan" : (root.networkService.connected ? "wifi" : "wifi_off")
                iconColor: root.networkService.connected ? root.theme.primary : root.theme.surfaceVariantOn
                iconSize: 22
            }

            Column {
                // Absorbs the slack so the two buttons end flush with the edge:
                // row - icon - three gaps - toggle - refresh.
                width: parent.width - 22 - root.theme.space8 * 3 - 56 - 30
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    width: parent.width
                    text: root.networkService.usingEthernet ? root.networkService.displayName() : (root.networkService.connected ? root.networkService.networkName : "Wi-Fi")
                    color: root.theme.surfaceOn
                    font.family: root.theme.mediumFamily
                    font.pixelSize: root.theme.titleMedium
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    text: {
                        if (root.networkService.usingEthernet) {
                            const speed = root.networkService.wiredDevice ? root.networkService.wiredDevice.linkSpeed : 0;
                            return speed > 0 ? "Connected · " + speed + " Mb/s" : "Connected";
                        }

                        return root.networkService.connected ? "Connected" : (root.networkService.wifiEnabled ? "Not connected" : "Turned off");
                    }
                    color: root.theme.surfaceVariantOn
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.bodySmall
                }

            }

            M3Button {
                width: 56
                height: 30
                radius: 15
                anchors.verticalCenter: parent.verticalCenter
                theme: root.theme
                containerColor: root.networkService.wifiEnabled ? root.theme.primaryContainer : root.theme.surfaceContainerHigh
                stateLayerColor: root.networkService.wifiEnabled ? root.theme.primaryContainerOn : root.theme.surfaceOn
                onClicked: root.networkService.setWifiEnabled(!root.networkService.wifiEnabled)

                Text {
                    anchors.centerIn: parent
                    text: root.networkService.wifiEnabled ? "On" : "Off"
                    color: root.networkService.wifiEnabled ? root.theme.primaryContainerOn : root.theme.surfaceOn
                    font.family: root.theme.mediumFamily
                    font.pixelSize: root.theme.labelMedium
                }

            }

            M3Button {
                width: 30
                height: 30
                radius: 15
                anchors.verticalCenter: parent.verticalCenter
                theme: root.theme
                enabled: root.networkService.wifiEnabled && !root.networkService.scanning
                opacity: enabled ? 1 : 0.4
                containerColor: "transparent"
                stateLayerColor: root.theme.surfaceOn
                onClicked: root.networkService.rescan()

                MaterialIcon {
                    id: refreshIcon

                    anchors.centerIn: parent
                    theme: root.theme
                    icon: "refresh"
                    iconColor: root.theme.surfaceOn
                    iconSize: 18
                    // A plain NumberAnimation on a value in the root, rather than
                    // the RotationAnimator that used to be here.
                    //
                    // `target: parent` is the animator's QObject parent, so what
                    // got spun was decided by where the animator happened to be
                    // declared rather than by anything named. And an Animator is
                    // driven off the render thread, which left the QML `rotation`
                    // property pinned at 0 for the whole run, so the spin was
                    // invisible to anything reading the item.
                    rotation: root.networkService.scanning ? root.refreshSpin : 0
                }

            }

        }

        Rectangle {
            width: parent.width
            height: 1
            color: root.theme.outlineVariant
        }

        Text {
            text: root.networkService.wifiEnabled ? "Available networks" : "Wi-Fi is off"
            color: root.theme.surfaceVariantOn
            font.family: root.theme.mediumFamily
            font.pixelSize: root.theme.labelMedium
            font.capitalization: Font.AllUppercase
        }

        Flickable {
            width: parent.width
            // Trimmed alongside the popup's 456 -> 420 so the column still fits
            // its margins with the Disconnect button showing. The list scrolls,
            // so this is a viewport, not a content height.
            height: 252
            clip: true
            contentWidth: width
            contentHeight: networkList.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            visible: root.networkService.wifiEnabled

            Column {
                id: networkList

                width: parent.width
                spacing: root.theme.space4

                Repeater {
                    model: root.networkService.wifiDevice ? root.networkService.wifiDevice.networks : null

                    delegate: M3Button {
                        id: networkButton

                        property var network: modelData

                        function signalIcon() {
                            const strength = network.signalStrength > 1 ? network.signalStrength / 100 : network.signalStrength;
                            if (strength < 0.25)
                                return "wifi_1_bar";

                            if (strength < 0.6)
                                return "wifi_2_bar";

                            return "wifi";
                        }

                        width: networkList.width
                        height: 46
                        theme: root.theme
                        radius: root.theme.radiusSmall
                        containerColor: network.connected ? root.theme.primaryContainer : "transparent"
                        stateLayerColor: network.connected ? root.theme.primaryContainerOn : root.theme.surfaceOn
                        onClicked: {
                            if (network.connected)
                                network.disconnect();
                            else if (network.security !== WifiSecurityType.Open && !network.known)
                                root.passwordTarget = network;
                            else
                                network.connect();
                        }

                        MaterialIcon {
                            anchors.left: parent.left
                            anchors.leftMargin: root.theme.space8
                            anchors.verticalCenter: parent.verticalCenter
                            theme: root.theme
                            icon: networkButton.signalIcon()
                            iconColor: network.connected ? root.theme.primaryContainerOn : root.theme.surfaceOn
                            iconSize: 20
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 40
                            anchors.right: lockIcon.left
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: network.name
                            color: network.connected ? root.theme.primaryContainerOn : root.theme.surfaceOn
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.bodyMedium
                            elide: Text.ElideRight
                        }

                        MaterialIcon {
                            id: lockIcon

                            anchors.right: parent.right
                            anchors.rightMargin: root.theme.space8
                            anchors.verticalCenter: parent.verticalCenter
                            visible: network.security !== WifiSecurityType.Open
                            theme: root.theme
                            icon: "lock"
                            iconColor: network.connected ? root.theme.primaryContainerOn : root.theme.surfaceVariantOn
                            iconSize: 16
                        }

                    }

                }

            }

        }

        M3Button {
            visible: root.networkService.connected
            width: 116
            height: 32
            theme: root.theme
            radius: 16
            containerColor: root.theme.surfaceContainerHigh
            borderColor: root.theme.outlineVariant
            onClicked: {
                // On ethernet the active link lives on the device, not in the
                // wifi network list this button used to reach into.
                if (root.networkService.usingEthernet && root.networkService.wiredDevice)
                    root.networkService.wiredDevice.disconnect();
                else if (root.networkService.connectedNetwork)
                    root.networkService.connectedNetwork.disconnect();

            }

            MaterialIcon {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                theme: root.theme
                icon: "link_off"
                iconColor: root.theme.surfaceOn
                iconSize: 17
            }

            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 9
                text: "Disconnect"
                color: root.theme.surfaceOn
                font.family: root.theme.mediumFamily
                font.pixelSize: root.theme.labelMedium
            }

        }

    }

    Rectangle {
        anchors.fill: parent
        visible: root.passwordTarget !== null
        radius: root.theme.radiusLarge
        color: root.theme.surfaceContainerHighest
        border.width: 1
        border.color: root.theme.outline
        opacity: visible ? 1 : 0

        Column {
            anchors.centerIn: parent
            width: parent.width - root.theme.space32
            spacing: root.theme.space12

            Text {
                width: parent.width
                text: "Connect to " + (root.passwordTarget ? root.passwordTarget.name : "")
                color: root.theme.surfaceOn
                font.family: root.theme.mediumFamily
                font.pixelSize: root.theme.titleMedium
                wrapMode: Text.Wrap
            }

            TextInput {
                id: passwordInput

                width: parent.width
                height: 42
                focus: root.passwordTarget !== null
                echoMode: TextInput.Password
                color: root.theme.surfaceOn
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.bodyMedium
                leftPadding: root.theme.space12
                verticalAlignment: TextInput.AlignVCenter
                onAccepted: root.acceptPassword()
                // Escape normally belongs to the menu layer's shortcut, but that
                // one stands aside while this prompt is up, so this is the
                // handler that actually runs. Marking the event accepted stops
                // it also travelling up and dismissing the whole menu along
                // with the passphrase.
                Keys.onEscapePressed: {
                    root.cancelPassword();
                    event.accepted = true;
                }

                Rectangle {
                    anchors.fill: parent
                    z: -1
                    radius: root.theme.radiusSmall
                    color: root.theme.surfaceContainer
                    border.width: 1
                    border.color: passwordInput.activeFocus ? root.theme.primary : root.theme.outline
                }

            }

            Row {
                spacing: root.theme.space8

                M3Button {
                    width: 88
                    height: 36
                    theme: root.theme
                    radius: 18
                    containerColor: "transparent"
                    borderColor: root.theme.outline
                    onClicked: root.cancelPassword()

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: root.theme.surfaceOn
                        font.family: root.theme.mediumFamily
                        font.pixelSize: root.theme.labelMedium
                    }

                }

                M3Button {
                    width: 100
                    height: 36
                    theme: root.theme
                    radius: 18
                    containerColor: root.theme.primaryContainer
                    stateLayerColor: root.theme.primaryContainerOn
                    onClicked: root.acceptPassword()

                    Text {
                        anchors.centerIn: parent
                        text: "Connect"
                        color: root.theme.primaryContainerOn
                        font.family: root.theme.mediumFamily
                        font.pixelSize: root.theme.labelMedium
                    }

                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.theme.motionMedium
                easing.type: Easing.OutCubic
            }

        }

    }

}
