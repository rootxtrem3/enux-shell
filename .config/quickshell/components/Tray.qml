import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

// The tray, as a second pill flush against the island rather than inside it.
//
// A tray item appearing or exiting changes how many icons there are, and inside
// the island that would change restingWidth -- a binding, with no Behaviour on
// it on purpose, because width also carries the island's morph factor and
// animating it made the pill chase its own cross-fade. So every app that trayed
// up would have snapped the bar sideways. A pill of its own cannot affect that
// arithmetic at all, and it disappears entirely when there is nothing to show
// rather than sitting there as an empty lozenge.
//
// Sizing matches the bar exactly -- same height, same stadium shape, same fill
// and border, and the same glyph size, since they sit side by side on one line.
// A second pill is a grouping decision, not a hierarchy one: a tray a few
// pixels shorter would read as a lesser bar rather than as part of this one.
Item {
    id: tray

    property var theme
    // The window the tray sits in, handed in by shell.qml. It cannot be reached
    // from here: a QML id is private to the component that declares it, so the
    // panel's id means nothing in this file. It is needed because the D-Bus
    // ContextMenu call takes its coordinates relative to a specific window.
    property var parentWindow: null
    // The bar this sits beside, for the same reason: the panel's bar is not
    // nameable from in here. Everything about the placement is derived from it
    // rather than from the screen, so the two stay locked together.
    property var barItem: null

    readonly property var items: SystemTray.items

    // Passive items are filtered out here rather than in the delegate. Hiding a
    // delegate's visible flag would still leave its 30px cell in the Row, so a
    // hidden item would take up the space of one that is not there. Filtering the
    // model drops the cell too.
    readonly property var shownItems: {
        var out = [];
        var all = items.values;

        for (var i = 0; i < all.length; i++) {
            if (all[i].status !== SystemTrayItem.Passive)
                out.push(all[i]);
        }

        return out;
    }

    readonly property int count: shownItems.length

    // 1 when something is traying up, 0 when nothing is. Driven off the count
    // rather than off a separate flag so it cannot disagree with what is
    // actually on screen.
    property real reveal: 0

    Behavior on reveal {
        NumberAnimation {
            duration: theme.motionMedium
            easing.type: Easing.OutCubic
        }

    }

    // The same height as the bar, read from the same number rather than derived
    // from it. An earlier version took barHeight and subtracted a space8 to sit a
    // step below the bar, which meant shrinking the bar to the tray's height
    // shrank this to less than the 20px cells it has to contain and clipped
    // them. One height, both pills, is the only relationship that cannot fail
    // that way.
    //
    // Named pillHeight, not height: an underscore suffix is the only way to say
    // "this is not Item.height", and a property that has to apologise for its
    // own name is a sign it wants a different one.
    readonly property int pillHeight: theme.barHeight
    readonly property int glyphSize: theme.iconSize - theme.space2

    // The gap between the two pills. Half of what a space12 cell would give, so
    // the pair reads as touching without merging into one lozenge.
    readonly property real gap: theme.space8

    // Flush against the bar's right edge, tracking it as it grows. The bar is
    // centred and widens when an OSD or a notification takes the pill, so a
    // position pinned to the screen would leave the two drifting apart every
    // time something was shown and snapping back afterwards. Deriving x from
    // the bar's own geometry means the pair expands and contracts as one.
    //
    // Retracted, it sits one own-width further right rather than off the
    // screen: the slide is then a short local move out of the gap it came from
    // instead of a traverse of the whole panel, and it is still fully clear of
    // the bar because the offset exceeds the gap it started from.
    x: tray.barItem
        ? tray.barItem.x + tray.barItem.width + tray.gap + (1 - reveal) * (tray.width + tray.gap)
        : theme.space16
    // Top-aligned on the bar's own top edge. Once the heights match there is
    // nothing to centre, and spelling it as a centring expression would only be
    // a zero waiting for the two heights to come apart again.
    y: theme.panelTopMargin
    width: theme.space8 + row.implicitWidth + theme.space8
    height: pillHeight
    visible: reveal > 0.01

    Rectangle {
        id: pill

        anchors.fill: parent
        // Half the height, so the pill is a stadium like the bar's. The bar
        // uses radiusExtraLarge, which is larger than half its height and so
        // clamps to the same shape; spelling it as height/2 here says what is
        // meant and keeps working if the height changes.
        radius: tray.pillHeight / 2
        // surfaceContainerLowest, matching the bar. The bar's own comment says
        // why: with no outline, the pill has to contrast against the wallpaper
        // by fill alone, and the lowest surface is the one that goes darker than
        // a dark wallpaper rather than a few levels lighter than it.
        color: tray.theme.surfaceContainerLowest
        // No border, same as the bar. The two sit 8px apart at the same height,
        // so an outlined tray beside an unoutlined bar would read as a
        // rendering bug rather than as a choice.
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: tray.theme.space2
        Repeater {
            id: icons

            // A plain JS array, not the object model, because Passive entries
            // have to be left out entirely. Its delegates still arrive as
            // modelData.
            model: tray.shownItems

            delegate: TrayItem {
                item: modelData
                parentWindow: tray.parentWindow
                theme: tray.theme
                glyphSize: tray.glyphSize
            }

        }

    }

    // The reveal target. An explicit binding rather than one inline on the
    // property, so the Behaviour has a single writer to sit in front of.
    onCountChanged: tray.reveal = tray.count > 0 ? 1 : 0

    Component.onCompleted: tray.reveal = tray.count > 0 ? 1 : 0

}
