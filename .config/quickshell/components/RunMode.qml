import Quickshell
import QtQuick

// "Run" mode of the launcher. The search field doubles as the command line, so
// this pane only has to explain that and run what was typed.
Item {
    id: root

    property var theme
    property var launcherService

    Column {
        anchors.centerIn: parent
        spacing: root.theme.space12

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Run a command"
            color: root.theme.surfaceOn
            font.family: root.theme.mediumFamily
            font.pixelSize: root.theme.titleMedium
            font.weight: Font.DemiBold
        }

        Text {
            width: 420
            horizontalAlignment: Text.AlignHCenter
            text: "The search bar above acts as the command line.\nPress Enter to execute, Esc to close."
            color: root.theme.surfaceVariantOn
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.bodyMedium
            wrapMode: Text.WordWrap
        }

    }

    function run(command) {
        if (command.trim().length === 0)
            return ;

        Quickshell.execDetached(["sh", "-c", command]);
        root.launcherService.closeLauncher();
    }

}
