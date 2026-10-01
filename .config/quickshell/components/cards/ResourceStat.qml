import ".."
import QtQuick
import QtQuick.Shapes

// One resource as a ring gauge with its reading beside it, for a grid cell.
//
// Side by side rather than stacked, and that is the whole point of the layout.
// A ring above a label above a reading is three bands tall, and two rows of
// them made this the tallest card in the dashboard. It also put the text
// directly under the dial, close enough to read as touching it. Putting the
// text in its own column to the right of the ring costs one row instead of two,
// which is where the height went, and the two can no longer overlap at all
// because they never share an axis.
Item {
    id: root

    property var theme
    property string icon: "monitoring"
    property string label: "CPU"
    // May contain newlines, which stack into as many lines as given. Nothing
    // does at the moment -- every reading is a single short string -- but the
    // two Texts below are already sized off each other's height, so a second
    // line costs nothing to allow for.
    property string detail: "0%"
    property real value: 0

    // Driven by the ring, which is the tallest thing here. The reading beside it
    // is two lines of 12px text (~30px), so it fits inside the dial's height
    // without pushing the cell taller. GridLayout sizes rows off this, so all
    // three cells come out identical and sit on a common baseline.
    implicitHeight: 60

    // Clamped once here rather than at every use, and animated so the arc glides
    // to a new reading instead of jumping. Reporting over 100% (disk, or network
    // throughput against its own ceiling) fills the ring rather than spilling
    // past it.
    property real shown: Math.max(0, Math.min(1, root.value))

    Behavior on shown {
        NumberAnimation {
            duration: root.theme.motionMedium
            easing.type: Easing.OutCubic
        }
    }

    readonly property real ringDiameter: 60
    readonly property real ringWidth: 5
    readonly property real ringRadius: ringDiameter / 2 - ringWidth

    // A plain Item rather than a bare Shape, so the icon has a non-Positioner
    // parent to centre on. A Shape cannot host children.
    Item {
        id: dial

        width: root.ringDiameter
        height: width
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        Shape {
            id: track

            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            // The empty part of the dial.
            ShapePath {
                strokeWidth: root.ringWidth
                strokeColor: root.theme.surfaceContainer
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: track.width / 2
                    centerY: track.height / 2
                    radiusX: root.ringRadius
                    radiusY: root.ringRadius
                    // Start at 12 o'clock rather than 3, so a low reading fills
                    // from the top the way a dial does.
                    startAngle: -90
                    sweepAngle: 360
                }
            }

            // The filled part.
            ShapePath {
                strokeWidth: root.ringWidth
                strokeColor: root.theme.primary
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: track.width / 2
                    centerY: track.height / 2
                    radiusX: root.ringRadius
                    radiusY: root.ringRadius
                    startAngle: -90
                    sweepAngle: 360 * root.shown
                }
            }
        }

        // Centred on the dial rather than on the ring's parent, and inside a
        // plain Item. Two earlier arrangements both failed quietly: as a child
        // of a Column it made the Column log "Column will not function" and
        // stack nothing at all, and as a sibling anchored to an item that a
        // Column owned, the anchor resolved to nothing and parked the icon in
        // the corner of the cell.
        MaterialIcon {
            anchors.centerIn: parent
            theme: root.theme
            icon: root.icon
            iconColor: root.theme.primary
            iconSize: 22
        }
    }

    // A plain Item, not a Column, and deliberately so. A Positioner owns its
    // children's geometry and takes its own implicitHeight from them, but this
    // one had anchors on it: the Column reported height 0 and implicitHeight 0
    // while the Text inside it reported 414, so verticalCenter parked a
    // zero-height box on the cell's midline and the reading spilled 23px above
    // the ring. Nothing errored, and the text simply rendered in the wrong
    // place. Here the height is the sum of two explicitly-sized Texts, so the
    // centring anchor has a real number to work with and the reading is always
    // the full height of its own text.
    Item {
        id: readout

        // The gap is what keeps the text off the ring, and it is wider than the
        // stroke plus the round cap that overshoots the arc's radius, so there
        // is clearance even at a full sweep.
        anchors.left: dial.right
        anchors.leftMargin: root.theme.space8
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - root.ringDiameter - root.theme.space8
        height: labelText.height + detailText.height

        Text {
            id: labelText

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: parent.width
            // Explicit, so the height is driven by the content and not by any
            // parent trying to size it.
            height: implicitHeight

            text: root.label
            color: root.theme.surfaceOn
            font.family: root.theme.mediumFamily
            font.pixelSize: root.theme.bodySmall
            font.weight: Font.DemiBold
            // NoWrap rather than the WordWrap default: a wrapping label would
            // silently double the reading's height and push it off the dial's
            // midline. Every label here is one short word, so it can only ever
            // need eliding.
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }

        Text {
            id: detailText

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: labelText.bottom
            width: parent.width
            height: implicitHeight

            text: root.detail
            color: root.theme.surfaceVariantOn
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.bodySmall
            // Fixed rather than proportional, so a reading that does carry a
            // second line is exactly two lines tall and the block height above
            // stays predictable. Under ProportionalHeight lineHeight multiplies
            // whatever the font's natural line box happens to be.
            lineHeightMode: Text.FixedHeight
            lineHeight: 1.15 * font.pixelSize
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }
    }
}
