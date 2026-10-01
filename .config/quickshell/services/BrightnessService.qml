import QtQuick
import Quickshell.Io

// Brightness state. brightnessctl writes sysfs directly, so there is no set-and-
// read-back round trip to hang an OSD off: the backlight FileView keeps `fraction`
// current for free, and the 150ms watcher below diffs the level to fire the OSD
// for changes made outside the shell.
//
// hypr/scripts/brightness.sh applies the change first and then pushes the value
// over IPC, which is the instant path -- adoptBrightness() below.
Item {
    id: root

    property string brightnessPath: ""
    property int brightness: 0
    property int maximum: 100
    property real previousBrightness: -1
    property bool brightnessReady: false
    readonly property real fraction: maximum > 0 ? brightness / maximum : 0

    signal osdRequested(string icon, string title, real progress)

    function setBrightness(value) {
        const level = Math.max(0.01, Math.min(1, value));
        const percent = Math.round(level * 100);
        brightness = Math.round(maximum * level);
        previousBrightness = level;
        brightnessReady = true;
        brightnessRunner.exec(["brightnessctl", "set", percent + "%"]);
        osdRequested("brightness_6", percent + "%", level);
    }

    // Called from the IpcHandler once brightness.sh has already applied the
    // change with brightnessctl, so this only syncs state and raises the OSD.
    function adoptBrightness(value) {
        const level = Math.max(0, Math.min(1, value));
        const percent = Math.round(level * 100);
        brightness = Math.round(maximum * level);
        previousBrightness = level;
        brightnessReady = true;
        osdRequested("brightness_6", percent + "%", level);
    }

    // Keeps the slider position in sync. OSD emission belongs to the watcher so
    // a change is reported once, not once per observer.
    function syncBrightness() {
        const parsed = Number(brightnessFile.text().trim());
        if (isNaN(parsed))
            return ;

        brightness = parsed;
    }

    function refreshBrightness() {
        if (!watcher.running)
            watcher.running = true;

    }

    visible: false
    width: 0
    height: 0

    Process {
        id: findBacklight

        command: ["sh", "-c", "for f in /sys/class/backlight/*/brightness; do [ -r \"$f\" ] && { printf '%s\\n' \"$f\"; break; }; done"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const candidate = text.trim();
                if (candidate.length > 0)
                    root.brightnessPath = candidate;

            }
        }

    }

    FileView {
        id: brightnessFile

        path: root.brightnessPath
        preload: true
        watchChanges: true
        printErrors: false
        onTextChanged: root.syncBrightness()
    }

    FileView {
        id: maximumFile

        path: root.brightnessPath.length > 0 ? root.brightnessPath.replace(/brightness$/, "max_brightness") : ""
        preload: true
        watchChanges: true
        printErrors: false
        onTextChanged: {
            const parsed = Number(maximumFile.text().trim());
            if (!isNaN(parsed) && parsed > 0)
                root.maximum = parsed;

        }
    }

    Process {
        id: watcher

        command: ["sh", "-c", "brightnessctl -m 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                if (fields.length < 4)
                    return ;

                const next = Number(fields[3].replace("%", "")) / 100;
                if (isNaN(next))
                    return ;

                if (brightnessReady && Math.abs(next - previousBrightness) > 0.004)
                    osdRequested("brightness_6", Math.round(next * 100) + "%", next);

                previousBrightness = next;
                brightnessReady = true;
            }
        }

    }

    Process {
        id: brightnessRunner
    }

    Timer {
        interval: 150
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshBrightness()
    }

}
