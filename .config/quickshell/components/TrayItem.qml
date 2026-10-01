import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick

// One StatusNotifierItem as a clickable icon.
//
// Nothing here interprets the app. Left click is the app's Activate, right
// click is the app's ContextMenu, and the app draws its own menu -- there is
// no second menu in this shell to keep in step with theirs.
Item {
    id: root

    property var theme
    property var item
    // The window the app's ContextMenu coordinates are relative to. Set by the
    // use site, because an item cannot work out which window it ended up in.
    property var parentWindow: null
    // Glyph size, from the use site, so the tray can be a step down from the
    // bar without every cell here hard-coding theme.iconSize. Defaults to the
    // theme value so the component still stands on its own.
    property int glyphSize: theme.iconSize

    // Padding is half a space4 a side. The bar's own cells are a space12 pad
    // around an 18px glyph; at the tray's smaller glyph that would put more
    // empty space around each icon than the icon itself occupies, and the pill
    // would read as mostly gaps.
    readonly property int pad: Math.round(theme.space4 / 2)

    width: glyphSize + pad * 2
    height: glyphSize + pad * 2

    // Passive is the spec's way of saying "I exist, but do not put me in a
    // tray" -- it is how an app publishes an item purely so something can
    // query it. Those are dropped by the model in Tray.qml rather than hidden
    // here, so that their cell is not left behind taking up space.
    readonly property bool shown: item.status !== SystemTrayItem.Passive

    // NeedsAttention is the app saying it wants the user to look at it, so it
    // gets the accent colour rather than the plain foreground.
    readonly property bool attention: item.status === SystemTrayItem.NeedsAttention

    readonly property color inkColor: attention ? theme.primary : theme.surfaceOn

    // An item's Icon property is whatever quickshell hands back, and that is not
    // the app's original string: for a name it resolved in the icon theme it
    // gives image://icon/<name>, and for one it rasterised itself it gives
    // image://qspixmap/<n>/<i>. A bare name only arrives when the app bypassed
    // the usual path, and then iconPath is what turns it into a reference.
    readonly property bool hasIcon: !!item.icon && item.icon.length > 0
    readonly property string iconSource: !hasIcon ? ""
        : (item.icon.indexOf("/") >= 0 ? item.icon : Quickshell.iconPath(item.icon))

    // The qspixmap provider is not actually registered in this build: an Image
    // whose source is one of those URLs reports Image.Error, and an IconImage
    // covering it paints a solid block instead of nothing. Since there is no way
    // to recover the app's original name from the URL, the honest reading is
    // that this item has no icon we can show, and the generic glyph is the right
    // thing to draw. image://icon/ and plain file paths both load normally, so
    // only this one form is treated as missing.
    readonly property bool sourceUsable: iconSource.indexOf("qspixmap") < 0

    // Records which source last failed rather than a bare boolean, so the
    // fallback clears itself the moment the app publishes a different icon.
    // Apps do swap icons at runtime -- a chat app changing its unread count is
    // the common case -- and a plain flag set once would leave those apps
    // showing the generic glyph for the rest of the session.
    property string failedSource: ""
    readonly property bool iconError: hasIcon && iconSource === failedSource

    readonly property bool showIcon: hasIcon && sourceUsable && !iconError

    // Three visible states, because hover-only is not enough to read as a
    // button: an icon that is only decorated once the pointer is already on it
    // gives a first-time user nothing to aim at, and the resting state is what
    // tells them the whole pill's worth of icons are individually clickable
    // rather than one undifferentiated lozenge.
    readonly property color restFill: theme.alpha(theme.surfaceOn, 0.07)
    readonly property color hoverFill: theme.alpha(theme.primary, 0.28)
    readonly property color pressFill: theme.alpha(theme.primary, 0.42)

    Rectangle {
        id: plate

        anchors.fill: parent
        // Matched to the cell rather than to the theme's radius scale: a
        // radiusMedium corner on a 20px cell is nearly a circle, and the
        // highlight would read as a dot rather than as the icon's own footprint.
        radius: width / 2
        color: trayMouse.pressed ? root.pressFill
            : trayMouse.containsMouse ? root.hoverFill
            : root.restFill
        // A hairline at rest, so the button has an edge rather than dissolving
        // into the pill behind it. It fades out on hover, where the fill change
        // already carries the state and a border on top of it just muddies it.
        border.width: 1
        border.color: trayMouse.containsMouse
            ? "transparent"
            : theme.alpha(theme.outlineVariant, 0.9)

        Behavior on color {
            ColorAnimation {
                duration: theme.motionShort
                easing.type: Easing.OutCubic
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: theme.motionShort
                easing.type: Easing.OutCubic
            }
        }

    }

    IconImage {
        anchors.fill: parent
        anchors.margins: root.pad
        visible: root.showIcon
        source: root.showIcon ? root.iconSource : ""
        // Tray icons are small files but there can be several arriving at once
        // when a batch of apps starts. Loading them off the render thread keeps
        // the bar's own animations smooth while that happens.
        asynchronous: true
        onStatusChanged: {
            if (status === IconImage.Error)
                root.failedSource = root.iconSource;

        }
    }

    MaterialIcon {
        anchors.centerIn: parent
        theme: root.theme
        icon: "extension"
        iconColor: root.inkColor
        iconSize: root.glyphSize
        visible: !root.showIcon
    }

    MouseArea {
        id: trayMouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: function(mouse) {
            root.handleClick(mouse.button, mouse.x, mouse.y);
        }

        onWheel: function(wheel) {
            // angleDelta rather than pixelDelta: the SNI Scroll method is
            // defined in degrees, and pixelDelta is empty on the kind of
            // high-resolution touchpads that report one.
            var d = wheel.angleDelta.y;
            if (d === 0)
                d = wheel.angleDelta.x;

            if (d !== 0)
                root.item.scroll(d, wheel.angleDelta.x !== 0);
        }
    }

    // Which app call each button maps to, kept out of onClicked so the mapping
    // is one function rather than three branches inside a signal handler.
    function handleClick(button, localX, localY) {
        if (button === Qt.LeftButton) {
            // ItemIsMenu: the app is saying it has no Activate, only a context
            // menu. Honouring that is the whole reason left click cannot be an
            // unconditional activate() -- a left click on one of these has to
            // open the menu or it does nothing at all.
            if (root.item.onlyMenu) {
                root.openMenu(localX, localY);
                return;
            }

            root.item.activate();
            return;
        }

        if (button === Qt.MiddleButton) {
            root.item.secondaryActivate();
            return;
        }

        root.openMenu(localX, localY);
    }

    // D-Bus ContextMenu takes its coordinates relative to a window, and the
    // window itself, so mapToGlobal is what converts an in-item position into
    // that: with no item argument it resolves against the window this icon
    // actually lives in, which is not the same as the window the caller named
    // if anyone ever nests one of these.
    function openMenu(localX, localY) {
        if (!root.parentWindow)
            return;

        var p = root.mapToGlobal(localX, localY);

        root.item.display(root.parentWindow, Math.round(p.x), Math.round(p.y));
    }

}
