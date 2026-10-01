import QtQuick
import Quickshell.Io

// Volume state for the shell. Two paths write it:
//
//   1. hypr/scripts/volume.sh applies the change with pamixer, then pushes the
//      new value over IPC (`quickshell ipc call --any-display shell setVolume`).
//      That is the instant path -- adoptVolume() below.
//   2. The 150ms watcher diffs wpctl's reported level and fires the OSD for any
//      change made outside the shell (hardware keys, mixer tools, pavucontrol).
//
// The shell's own slider uses setVolume(), which writes wpctl and records the
// level it asked for so path 2 does not treat that write as an external change.
Item {
    id: root

    property real volume: 0
    property bool muted: false
    property real previousVolume: -1
    property bool volumeReady: false

    signal osdRequested(string icon, string title, real progress)

    function setVolume(value) {
        const level = Math.max(0, Math.min(1.5, value));
        volume = level;
        previousVolume = level;
        volumeReady = true;
        muted = false;
        control.exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(level * 100) + "%"]);
        osdRequested("volume_up", Math.round(level * 100) + "%", level);
    }

    // Called from the IpcHandler once volume.sh has already applied the change
    // via pamixer. Syncs state and raises the OSD without re-issuing wpctl, so a
    // keypress does not write the volume twice.
    function adoptVolume(value) {
        const level = Math.max(0, Math.min(1.5, value));
        volume = level;
        previousVolume = level;
        volumeReady = true;
        osdRequested("volume_up", Math.round(level * 100) + "%", level);
    }

    function setMuted(value) {
        muted = value;
        control.exec(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", value ? "1" : "0"]);
        osdRequested(value ? "volume_off" : "volume_up", value ? "Muted" : Math.round(volume * 100) + "%", volume);
    }

    function refresh() {
        if (!reader.running)
            reader.running = true;

    }

    visible: false
    width: 0
    height: 0

    Process {
        id: control
    }

    Process {
        id: reader

        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]

        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/Volume:\s+([0-9.]+)/);
                if (!match)
                    return ;

                const next = Number(match[1]);
                muted = text.indexOf("MUTED") !== -1;
                volume = next;

                // 0.004 is roughly wpctl's own reporting granularity.
                if (volumeReady && Math.abs(next - previousVolume) > 0.004)
                    osdRequested(muted ? "volume_off" : "volume_up", muted ? "Muted" : Math.round(next * 100) + "%", next);

                previousVolume = next;
                volumeReady = true;
            }
        }

    }

    Timer {
        interval: 150
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

}
