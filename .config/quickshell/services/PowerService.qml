import QtQuick
import Quickshell.Io

Item {
    id: root

    property var panelWindow: null

    // hypridle is a separate daemon that times input events itself; it does not
    // speak the Wayland idle-inhibit protocol that Quickshell's private
    // _IdleInhibitor type wraps, so that type could never hold hypridle's timers
    // open. hypridle *does* honour systemd inhibitor locks, so that is what the
    // shell takes out instead. Verified empirically: with `systemd-inhibit
    // --what=idle` held, a 5s hypridle test listener never fires; without it, it
    // fires on schedule.
    readonly property string inhibitWhy: "Quickshell: session idle inhibited"

    // The distinguishing fragment of our inhibitor's command line: what it is
    // told and why. Built from inhibitWhy rather than repeated, so the reaper
    // and the Process below can never drift apart.
    //
    // The leading and trailing spaces are part of the pattern, not decoration.
    // /proc/PID/cmdline starts with argv[0] -- "systemd-inhibit " -- so without
    // the leading space the fragment could match from inside the executable
    // name rather than at an argument boundary, and without the trailing one a
    // "--why=Quickshell: session idle inhibited but for a different reason"
    // would be caught by accident.
    readonly property string inhibitArgv: " --what=idle --why=" + inhibitWhy + " "

    // The flag is the source of truth rather than a binding on the Process's
    // `running`: that property only settles once the child has actually spawned,
    // so reading it back in the same tick reports the old value and any UI bound
    // to it lags a frame behind the click.
    property bool inhibited: false
    readonly property bool idleInhibited: inhibited

    function setIdleInhibited(inhibited) {
        if (root.inhibited === inhibited)
            return;

        root.inhibited = inhibited;
        inhibitor.running = inhibited;
    }

    // Kill any inhibitor this shell left behind when it died.
    //
    // The Process above is reaped when `running` goes false, but not when the
    // whole shell is killed: systemd-inhibit is left running and still holding
    // the idle lock, while the shell that restarts has no memory of it. The
    // visible result is a button reading "Idle" -- off -- while idle is in fact
    // inhibited with no way to undo it, and because every toggle spawns a
    // *second* lock the orphan survives all of them. This brings the two back
    // into agreement at startup: whatever we find goes, and we start off.
    //
    // The two-stage match is deliberate. Matching the command line alone (what
    // `pkill -f` does) also matches anything that merely mentions the string --
    // including the shell running this very script, which is a real way to kill
    // the caller instead of the target. So the executable is checked first, and
    // only a process that really is systemd-inhibit is considered, then its
    // arguments must contain inhibitArgv. That never touches an inhibitor taken
    // out by something else, such as a user's own systemd-inhibit with their own
    // --why, or a different --what under the same --why.
    function reapStrayInhibitors() {
        strays.running = true;
    }

    Process {
        id: strays

        // /proc is walked rather than `pgrep`/`pkill` called: the script needs a
        // per-pid executable check, and shelling out once per process to find
        // out what it is would be both slow and racy.
        //
        // Written as a single line with an explicit ";" between every clause.
        // The pieces are joined for readability, and joining them without a
        // separator silently produced `|| continue case ...`, which sh rejects
        // as a syntax error.
        //
        // The pattern arrives as "$1" rather than being spliced into the script
        // text. Splicing it means writing it as *"…"*, and the placement of
        // those two asterisks relative to the quotes is load-bearing in a way
        // that fails silently and totally: a leading * outside the quotes ends
        // the case pattern immediately, and a trailing * inside them is a
        // literal asterisk rather than a wildcard. Both mistakes still look
        // like a plausible pattern at a glance, and both leave the reaper
        // exiting non-zero having killed nothing. As an argument the pattern is
        // never re-quoted, so it cannot be mangled like that at all.
        command: ["/bin/sh", "-c",
            "for d in /proc/[0-9]*; do"
            + " e=$(readlink -f \"$d/exe\" 2>/dev/null) || continue;"
            + " case \"$e\" in *systemd-inhibit) ;; *) continue ;; esac;"
            + " a=$(tr '\\0' ' ' < \"$d/cmdline\" 2>/dev/null);"
            + " case \"$a\" in *\"$1\"*) kill \"${d#/proc/}\" ;; esac;"
            + " done",
            "quickshell-reaper", root.inhibitArgv]
    }

    // hyprlock, not loginctl: the session has no IdleAction set, so
    // `loginctl lock-session` has nothing to dispatch to, while hyprlock is
    // installed and is the lock screen the rest of the config is built around.
    function lock() {
        locker.command = ["/bin/sh", "-c", "pidof hyprlock || hyprlock"];
        locker.running = true;
    }

    function sleep() {
        runner.exec(["systemctl", "suspend"]);
    }

    function restart() {
        runner.exec(["systemctl", "reboot"]);
    }

    function powerOff() {
        runner.exec(["systemctl", "poweroff"]);
    }

    visible: false
    width: 0
    height: 0

    Process {
        id: inhibitor

        running: false
        command: ["systemd-inhibit", "--what=idle", "--why=" + root.inhibitWhy, "--mode=block", "sleep", "infinity"]
        // If the child dies on its own the lock is already gone, so the flag has
        // to follow reality rather than keep claiming we are holding it.
        onExited: root.setIdleInhibited(false)
    }

    Process {
        id: locker

        running: false
        command: ["/bin/sh", "-c", "pidof hyprlock || hyprlock"]
    }

    Process {
        id: runner
    }

    // Delayed rather than started in Component.onCompleted, because this is a
    // Quickshell.Io Process and a whole-tree teardown is exactly the moment it
    // is racing: a reaper fired at zero milliseconds would enumerate /proc in
    // the same window in which an orphaned systemd-inhibit is still tearing
    // down, and could kill a process the dying shell had not finished with.
    // A third of a second is far past that and still well before anyone could
    // click the button.
    Timer {
        interval: 300
        repeat: false
        running: true
        onTriggered: root.reapStrayInhibitors()
    }

}
