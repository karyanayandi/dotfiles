import QtQuick
import QtQuick.Controls.Basic
import "../.."

TextField {
    id: root

    property string leadingGlyph: ""

    implicitHeight: 44
    implicitWidth: 160
    leftPadding: leadingGlyph ? 42 : 14
    rightPadding: 14
    font.family: Theme.fontUi
    font.pixelSize: 14
    color: Theme.colFg
    placeholderTextColor: Theme.colFgDim
    selectionColor: Theme.colChipActive
    selectedTextColor: Theme.colBg
    selectByMouse: true
    hoverEnabled: true

    Text {
        visible: root.leadingGlyph !== ""
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.leadingGlyph
        font.family: Theme.fontFamily
        font.pixelSize: 17
        color: root.activeFocus ? Theme.colFg : Theme.colFgDim
    }
    background: Rectangle {
        radius: 12
        color: root.hovered ? Theme.colBgAlt : Theme.colInputBg
        border.width: root.activeFocus ? 2 : 1
        border.color: root.activeFocus ? Theme.colChipActive : Theme.colBorder
    }
}
