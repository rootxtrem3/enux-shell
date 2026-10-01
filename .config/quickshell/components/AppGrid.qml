import Quickshell
import Quickshell.Widgets
import QtQuick

GridView {
    id: root

    property var theme
    property var launcherService

    property var allApps: DesktopEntries.applications.values

    model: {
        const query = root.launcherService.query.trim().toLowerCase();
        if (!query)
            return root.allApps;

        const hits = [];
        for (const entry of root.allApps) {
            const s = root.score(entry, query);
            if (s > 0)
                hits.push([ entry, s ]);

        }
        hits.sort((a, b) => b[1] - a[1]);
        return hits.map(hit => hit[0]);
    }

    // Ranked, word-based scoring: prefix > word-boundary > substring > subsequence.
    // Requires every query word to match, and sorts best matches first.
    function score(entry, query) {
        const name = entry.name.toLowerCase();
        const comment = (entry.comment || "").toLowerCase();
        const id = entry.id.toLowerCase();
        const words = query.split(/\s+/);

        let total = 0;
        for (const word of words) {
            total += root.wordScore(name, word, 4) || root.wordScore(comment, word, 3) || root.wordScore(id, word, 2) || (root.subsequence(name + " " + comment, word) ? 1 : 0);
            if (total === 0)
                return 0;

        }
        return total;
    }

    function wordScore(haystack, word, base) {
        if (haystack === word)
            return base * 400;

        if (haystack.startsWith(word))
            return base * 300;

        if (haystack.includes(" " + word) || haystack.includes("-" + word) || haystack.includes("_" + word) || haystack.includes("/" + word))
            return base * 60;

        const at = haystack.indexOf(word);
        return at >= 0 ? base * 40 - at : 0;
    }

    function subsequence(haystack, word) {
        let at = 0;
        for (let i = 0; i < word.length; i++) {
            at = haystack.indexOf(word[i], at);
            if (at < 0)
                return false;

            at++;
        }
        return true;
    }

    cellWidth: 150
    cellHeight: 108
    clip: true
    focus: true
    activeFocusOnTab: true
    keyNavigationEnabled: false
    currentIndex: 0
    onModelChanged: currentIndex = 0

    Keys.onUpPressed: {
        stepSelection(0, -1);
        event.accepted = true;
    }
    Keys.onDownPressed: {
        stepSelection(0, 1);
        event.accepted = true;
    }
    Keys.onLeftPressed: {
        stepSelection(-1, 0);
        event.accepted = true;
    }
    Keys.onRightPressed: {
        stepSelection(1, 0);
        event.accepted = true;
    }
    Keys.onReturnPressed: {
        activateCurrent();
        event.accepted = true;
    }
    Keys.onEscapePressed: root.launcherService.closeLauncher()

    function stepSelection(dx, dy) {
        const count = root.count;
        if (!count)
            return ;

        const columns = Math.max(1, Math.floor(root.width / root.cellWidth));
        const rows = Math.ceil(count / columns);
        let row = Math.floor(root.currentIndex / columns);
        let column = root.currentIndex % columns;
        let nextRow = row + dy;
        let nextColumn = column + dx;
        if (nextColumn < 0) {
            nextColumn = columns - 1;
            nextRow--;
        }
        if (nextColumn >= columns) {
            nextColumn = 0;
            nextRow++;
        }
        if (nextRow < 0)
            nextRow = rows - 1;

        if (nextRow >= rows)
            nextRow = 0;

        root.currentIndex = Math.max(0, Math.min(count - 1, nextRow * columns + nextColumn));
    }

    function activateCurrent() {
        const entry = root.model[root.currentIndex];
        if (!entry)
            return ;

        // Route through the shared launcher path so Enter and click behave
        // identically, including the kitty wrap for Terminal=true entries.
        root.launcherService.launchEntry(entry);
        root.launcherService.closeLauncher();
    }

    highlight: Rectangle {
        radius: root.theme.radiusMedium
        color: root.theme.alpha(root.theme.primary, 0.16)
    }
    highlightMoveDuration: 120

    delegate: Rectangle {
        id: appTile

        required property var modelData

        readonly property bool hasIcon: !!modelData.icon && modelData.icon.length > 0
        readonly property string iconSource: !modelData.icon ? "" : (modelData.icon.indexOf("/") >= 0 ? modelData.icon : Quickshell.iconPath(modelData.icon))
        property bool iconError: false

        onModelDataChanged: iconError = false

        width: 116
        height: 96
        radius: root.theme.radiusMedium
        color: appMouse.containsMouse || GridView.isCurrentItem ? root.theme.alpha(root.theme.primary, 0.22) : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: root.theme.motionShort
                easing.type: Easing.OutCubic
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: root.theme.space8

            Rectangle {
                width: 46
                height: 46
                radius: root.theme.radiusSmall
                color: root.theme.surfaceContainerHigh
                anchors.horizontalCenter: parent.horizontalCenter

                IconImage {
                    anchors.fill: parent
                    anchors.margins: 6
                    visible: appTile.hasIcon && !appTile.iconError
                    source: appTile.hasIcon ? appTile.iconSource : ""
                    onStatusChanged: {
                        if (status === IconImage.Error)
                            appTile.iconError = true;

                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    theme: root.theme
                    icon: "apps"
                    iconColor: root.theme.surfaceVariantOn
                    iconSize: 22
                    visible: !appTile.hasIcon || appTile.iconError
                }

            }

            Text {
                width: 112
                text: appTile.modelData.name
                color: root.theme.surfaceOn
                font.family: root.theme.mediumFamily
                font.pixelSize: root.theme.bodyMedium
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                maximumLineCount: 1
            }

        }

        MouseArea {
            id: appMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.launcherService.launchEntry(appTile.modelData);
                root.launcherService.closeLauncher();
            }
        }

    }

}
