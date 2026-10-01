import QtQuick
import Quickshell.Bluetooth
import Quickshell.Io

// Item rather than QtObject: Quickshell's Process needs a default property to
// be parented into, which QtObject does not have. Matches the other services.
Item {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter

    // bluez is a separate system daemon. A session that boots without a radio,
    // or one that starts before the unit comes up, leaves defaultAdapter null --
    // and on such a machine the old service's setEnabled() was a silent no-op,
    // so the dashboard toggle looked live but did nothing. available is the
    // honest signal for that case.
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property string adapterName: adapter ? adapter.name : ""
    readonly property bool discovering: adapter ? adapter.discovering : false
    readonly property bool discoverable: adapter ? adapter.discoverable : false

    // Raw models on purpose. Filtering these into JS arrays inside a binding
    // would read each device's connected/paired flag without any way to
    // re-evaluate when one of them flips, so consumers bind per-delegate
    // instead (same approach the network list uses for its networks).
    readonly property var devices: Bluetooth.devices
    readonly property var adapters: Bluetooth.adapters

    // A short human-readable status for the toggle's tooltip/subtitle.
    readonly property string status: {
        if (!available)
            return "No adapter";

        if (!enabled)
            return "Off";

        if (discovering)
            return "Scanning";

        return adapterName !== "" ? adapterName : "On";
    }

    // Powering the radio on means starting the daemon when it is not up, not
    // just flipping a property on a stub. Harmless no-op once bluez is running.
    function setEnabled(on) {
        if (!adapter) {
            if (on)
                ensureDaemon();

            return;
        }

        if (adapter.enabled === on)
            return;

        adapter.enabled = on;
    }

    function setDiscovering(on) {
        if (adapter)
            adapter.discovering = on;

    }

    function setDiscoverable(on) {
        if (adapter)
            adapter.discoverable = on;

    }

    function connectDevice(device) {
        if (device)
            device.connect();

    }

    function disconnectDevice(device) {
        if (device)
            device.disconnect();

    }

    function pairDevice(device) {
        if (device)
            device.pair();

    }

    function forgetDevice(device) {
        if (device)
            device.forget();

    }

    function ensureDaemon() {
        if (daemon.running)
            return;

        daemon.running = true;
    }

    visible: false
    width: 0
    height: 0

    Process {
        id: daemon

        running: false
        command: ["systemctl", "start", "bluetooth.service"]
    }

}
