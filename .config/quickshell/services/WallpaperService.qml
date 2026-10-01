import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper browsing and applying. Applying only runs `awww img`; the
// wallpaper-daemon.sh watcher notices the awww cache change and re-runs
// matugen, which rewrites hypr/colors.lua. Theme.qml is watching that file, so
// the bar recolors from the new wallpaper without a restart.
Item {
    id: root

    property bool open: false
    property var images: []
    property var folders: []
    readonly property string picturesDir: Quickshell.env("HOME") + "/Pictures"
    readonly property string rootDir: root.picturesDir + "/Wallpapers"
    property string currentDir: root.rootDir
    readonly property string thumbDir: Quickshell.env("HOME") + "/.cache/wallpaper-thumbs"

    // The wallpaper currently applied, as matugen recorded it in colors.lua.
    // shell.qml binds this from theme.currentWallpaper so this service does not
    // need a second file watcher on the same path.
    property string currentImage: ""

    property string pendingPath: ""
    property string status: ""
    property var cache: ({})

    function thumbnailOf(path) {
        // ~/.cache/wallpaper-thumbs mirrors the wallpaper tree with the same
        // basename; this is the "minimal cached thumbnail" — tiny jpegs, so the
        // grid never decodes a full-res file just to paint a 116px tile.
        if (!path)
            return "";

        const rel = path.replace(root.rootDir, "").replace(/^\/+/, "");
        return rel ? root.thumbDir + "/" + rel : "";
    }

    function show() {
        scan();
        root.open = true;
    }

    function hide() {
        root.open = false;
    }

    function choose(path) {
        root.pendingPath = path;
        root.status = "Applying…";
        // JSON.stringify yields a double-quoted, escaped literal, so paths
        // containing spaces or quotes cannot break out of the shell command.
        applyProcess.command = ["bash", "-c", "awww img --transition-type center --transition-fps 60 --transition-step 255 " + JSON.stringify(path)];
        applyProcess.running = true;
        statusTimer.start();
    }

    function navigateTo(path) {
        root.currentDir = path;
        scan();
    }

    function goBack() {
        if (root.isAtRoot())
            return ;

        const parts = root.currentDir.split("/");
        parts.pop();
        const parent = parts.join("/");
        root.currentDir = parent.length < root.rootDir.length ? root.rootDir : parent;
        scan();
    }

    function isAtRoot() {
        return root.currentDir === root.rootDir;
    }

    function folderName() {
        if (root.isAtRoot())
            return "All Wallpapers";

        const parts = root.currentDir.split("/");
        return parts[parts.length - 1];
    }

    function isCurrent(path) {
        return path === root.currentImage;
    }

    function scan() {
        const cached = root.cache[root.currentDir];
        if (cached) {
            root.folders = cached.folders;
            root.images = cached.images;
            return ;
        }

        listProcess.running = true;
    }

    visible: false
    width: 0
    height: 0

    // Re-validate the current directory periodically so files that land while
    // the picker is closed are picked up on reopen. Timer defaults to
    // running: false, and the previous config omitted it, so this never fired
    // and the listing stayed frozen at whatever was first scanned.
    Timer {
        interval: 3200
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.cache[root.currentDir]) {
                delete root.cache[root.currentDir];
                scan();
            }
        }
    }

    Process {
        id: listProcess

        command: ["sh", "-c",
            "echo '---FOLDERS---'; " +
            "find '" + root.currentDir + "' -maxdepth 1 -type d ! -path '" + root.currentDir + "' | sort; " +
            "echo '---IMAGES---'; " +
            "find '" + root.currentDir + "' -maxdepth 1 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                const sections = text.trim().split("---IMAGES---");
                const folderSection = sections[0].replace("---FOLDERS---", "").trim();
                const imageSection = sections.length > 1 ? sections[1].trim() : "";
                const folders = folderSection ? folderSection.split("\n") : [];
                const images = imageSection ? imageSection.split("\n") : [];
                root.folders = folders;
                root.images = images;

                // Remember every visited directory, not just the latest. Nothing
                // binds to `cache`, so in-place mutation needs no notify.
                root.cache[root.currentDir] = {
                    "folders": folders,
                    "images": images
                };
            }
        }
    }

    Process {
        id: applyProcess

        stdout: StdioCollector {
            onStreamFinished: root.status = "Applied"
        }
    }

    Timer {
        id: statusTimer

        interval: 900
        onTriggered: {
            root.status = "";
            root.hide();
        }
    }

}
