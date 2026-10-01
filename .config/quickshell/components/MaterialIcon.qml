import QtQuick

Text {
    id: root

    property var theme
    property string icon: "help"
    property color iconColor: theme ? theme.surfaceOn : "transparent"
    property int iconSize: 20

    text: icon
    color: iconColor
    font.family: theme ? theme.iconFamily : "Material Symbols Rounded"
    font.pixelSize: iconSize
    font.styleName: "Regular"
    font.hintingPreference: Font.PreferNoHinting
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
