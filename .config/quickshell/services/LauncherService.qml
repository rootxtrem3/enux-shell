import QtQuick
import Quickshell

QtObject {
    id: root

    property bool open: false
    property string mode: "apps" // "apps" | "run"
    property string query: ""

    function openLauncher(modeOverride) {
        root.mode = modeOverride || "apps";
        root.query = "";
        root.open = true;
    }

    function closeLauncher() {
        root.open = false;
        root.query = "";
    }

    function toggleLauncher() {
        if (root.open)
            root.closeLauncher();
        else
            root.openLauncher("apps");

    }

    function toggleMode() {
        root.mode = root.mode === "apps" ? "run" : "apps";
        root.query = "";
    }

    // Shared launch path for both Enter and click. Terminal-tagged apps
    // (Terminal=true) are wrapped in `kitty -e`; everything else runs through the
    // desktop entry's own execute().
    function launchEntry(entry) {
        if (!entry)
            return ;

        if (entry.runInTerminal)
            Quickshell.execDetached(["kitty", "-e"].concat(entry.command));
        else
            entry.execute();

    }

}
