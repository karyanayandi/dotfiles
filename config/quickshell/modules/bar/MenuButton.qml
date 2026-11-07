import "../.."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    id: button

    property string glyph: ""
    property string label: ""
    property bool selected: false

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: contentItem.implicitWidth + 18
    implicitHeight: 28
    hoverEnabled: true
    Accessible.name: label
    ToolTip.visible: hovered
    ToolTip.text: label
    ToolTip.delay: 600

    contentItem: Text {
        text: button.glyph
        color: Theme.colFg
        font.family: Theme.fontFamily
        font.pixelSize: 15
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: 6
        color: button.down || button.selected ? Theme.colBarPressed : button.hovered ? Theme.colBarHover : "transparent"
        border.width: button.visualFocus ? 2 : 0
        border.color: Theme.colFg
    }
}
