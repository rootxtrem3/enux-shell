import QtQuick
import Quickshell.Hyprland

QtObject {
    id: root

    readonly property int activeWorkspace: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    readonly property int slotCount: {
        let highest = 3;
        const spaces = Hyprland.workspaces.values;
        for (let position = 0; position < spaces.length; position++) {
            if (spaces[position].id > highest)
                highest = spaces[position].id;

        }
        return highest;
    }

    function workspaceFor(index) {
        const spaces = Hyprland.workspaces.values;
        for (let position = 0; position < spaces.length; position++) {
            if (spaces[position].id === index)
                return spaces[position];

        }
        return null;
    }

    function activate(index) {
        const workspace = workspaceFor(index);
        if (workspace)
            workspace.activate();
        else if (Hyprland.usingLua)
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + index + " })");
        else
            Hyprland.dispatch("workspace " + index);
    }

    function isActive(index) {
        const workspace = workspaceFor(index);
        return workspace ? workspace.active : activeWorkspace === index;
    }

    function isOccupied(index) {
        const workspace = workspaceFor(index);
        // Workspace objects can persist after their last client closes.
        return workspace !== null && workspace.toplevels.values.length > 0;
    }

}
