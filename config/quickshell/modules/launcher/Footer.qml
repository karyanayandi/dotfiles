import QtQuick
import QtQuick.Layouts
import "../.."

RowLayout {
    id: root
    property string mode: "all"
    required property var bluetooth
    required property var clipboard

    Layout.fillWidth: true
    Layout.leftMargin: 14
    Layout.rightMargin: 14
    Layout.topMargin: 8
    Layout.bottomMargin: 10
    spacing: 12

    Text { text: "\u21B5 select"; color: Theme.g18; font.family: Theme.fontFamily; font.pixelSize: 10 }
    Text { text: "esc close"; color: Theme.g18; font.family: Theme.fontFamily; font.pixelSize: 10 }
    Item { Layout.fillWidth: true }

    Rectangle {
        visible: root.mode === "bluetooth"
        height: 24
        radius: 8
        color: root.bluetooth.scanning ? Theme.colHoverAlpha : Theme.colChipBg
        border.color: Theme.colBorder
        border.width: 1
        implicitWidth: scanLabel.implicitWidth + 20
        Text { id: scanLabel; anchors.centerIn: parent; text: root.bluetooth.scanning ? "Scanning\u2026" : "Scan"; color: Theme.colFg; font.family: Theme.fontFamily; font.pixelSize: 11 }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.bluetooth.scan() }
    }

    Rectangle {
        visible: root.mode === "bluetooth"
        height: 24
        radius: 8
        color: root.bluetooth.powered ? Theme.g7 : Theme.colChipBg
        border.color: Theme.colBorder
        border.width: 1
        implicitWidth: powerLabel.implicitWidth + 20
        Text { id: powerLabel; anchors.centerIn: parent; text: root.bluetooth.powered ? "BT On" : "BT Off"; color: root.bluetooth.powered ? Theme.colBg : Theme.colFg; font.family: Theme.fontFamily; font.pixelSize: 11 }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.bluetooth.togglePower() }
    }

    Rectangle {
        visible: root.mode === "clipboard"
        height: 24
        radius: 8
        color: Theme.colChipBg
        border.color: Theme.colBorder
        border.width: 1
        implicitWidth: clearLabel.implicitWidth + 20
        Text { id: clearLabel; anchors.centerIn: parent; text: "Clear"; color: Theme.colFg; font.family: Theme.fontFamily; font.pixelSize: 11 }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.clipboard.clear() }
    }
}
