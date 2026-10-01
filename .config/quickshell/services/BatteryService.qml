import QtQuick
import Quickshell.Services.UPower

QtObject {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool ready: device && device.ready
    readonly property int percentage: ready ? Math.round(device.percentage * 100) : 0
    readonly property bool charging: ready && device.state === UPowerDeviceState.Charging
    readonly property bool runningOnBattery: UPower.onBattery
    property bool stateInitialized: false

    signal chargerEvent(bool charging, int percentage)

    onRunningOnBatteryChanged: {
        if (stateInitialized)
            chargerEvent(!runningOnBattery, percentage);

        stateInitialized = true;
    }
}
