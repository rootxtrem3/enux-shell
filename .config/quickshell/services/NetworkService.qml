import QtQuick
import Quickshell.Io
import Quickshell.Networking

Item {
    id: root

    readonly property var wifiDevice: {
        const devices = Networking.devices.values;
        for (let index = 0; index < devices.length; index++) {
            const device = devices[index];
            if (device.type === DeviceType.Wifi)
                return device;

        }
        return null;
    }
    readonly property var wiredDevice: {
        const devices = Networking.devices.values;
        for (let index = 0; index < devices.length; index++) {
            const device = devices[index];
            // Unmanaged ethernet devices (VirtualBox host-only/NAT interfaces,
            // container bridges) show up in the same list and would otherwise
            // win the lookup while never carrying traffic.
            if (device.type === DeviceType.Wired && device.nmManaged)
                return device;

        }
        return null;
    }

    readonly property bool wifiEnabled: Networking.wifiEnabled

    // A plugged cable wins over wifi. NetworkManager happily keeps a wifi profile
    // "connected" at the same time as a wired one, so keying the indicator off
    // wifi alone showed a wireless glyph on a machine that is on ethernet.
    readonly property bool wiredConnected: wiredDevice ? (wiredDevice.connected || wiredDevice.hasLink) : false
    readonly property bool wifiConnected: wifiDevice ? wifiDevice.connected : false
    readonly property bool connected: wiredConnected || wifiConnected
    readonly property bool usingEthernet: wiredConnected

    // What the wired link is actually called, e.g. "lab-link" for enp0s25.
    readonly property string wiredName: wiredDevice && wiredDevice.network ? wiredDevice.network.name : ""

    property string networkName: "Not connected"
    property var connectedNetwork: null
    property bool connectionInitialized: false

    // True only while a rescan is actually in flight, so the refresh button can
    // spin instead of looking like a no-op.
    property bool scanning: false

    signal connectionEvent(bool connected, string name)

    function setWifiEnabled(enabled) {
        Networking.wifiEnabled = enabled;
    }

    function enableScanning() {
        if (wifiDevice)
            wifiDevice.scannerEnabled = true;

    }

    // Quickshell 0.3.1's WifiDevice exposes no requestScan(), so a manual
    // rescan has to be coaxed out of NetworkManager by bouncing the scanner and
    // letting it re-trigger a scan. The off-beat matters: flipping it back on
    // within the same frame is a no-op as far as NM is concerned.
    function rescan() {
        if (!wifiDevice || !wifiEnabled || scanning)
            return;

        scanning = true;
        wifiDevice.scannerEnabled = false;
        scanRestart.restart();
    }

    function updateNetwork(network) {
        if (network.connected) {
            connectedNetwork = network;
            networkName = network.name;
        } else if (connectedNetwork === network) {
            connectedNetwork = null;
            networkName = "Not connected";
        }
    }

    // Keep the displayed name honest when the active link is the cable.
    function displayName() {
        if (usingEthernet)
            return wiredName !== "" ? wiredName : "Wired connection";

        return networkName;
    }

    visible: false
    width: 0
    height: 0
    onConnectedChanged: {
        if (connectionInitialized)
            connectionEvent(connected, connected ? displayName() : "Network disconnected");

        connectionInitialized = true;
    }
    onWifiDeviceChanged: enableScanning()
    Component.onCompleted: enableScanning()

    Timer {
        id: scanRestart

        interval: 250
        onTriggered: {
            if (root.wifiDevice) {
                root.wifiDevice.scannerEnabled = true;
                root.scanning = false;
            }
        }
    }

    // Instantiator keeps the display name synchronized with individual native
    // Network objects without a JavaScript polling loop.
    Instantiator {
        model: root.wifiDevice ? root.wifiDevice.networks : null

        delegate: Item {
            required property var modelData

            visible: false
            width: 0
            height: 0
            Component.onCompleted: root.updateNetwork(modelData)

            Connections {
                function onConnectedChanged() {
                    root.updateNetwork(modelData);
                }

                target: modelData
            }

        }

    }

}
