import "../.."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    id: root

    property date now: new Date()

    Layout.alignment: Qt.AlignVCenter
    Layout.rightMargin: 0
    leftPadding: 10
    rightPadding: 10
    implicitHeight: 28
    hoverEnabled: true
    Accessible.name: "Open calendar, " + Qt.formatDateTime(now, "dddd, dd MMMM, HH:mm")

    contentItem: Text {
        text: Qt.formatDateTime(root.now, "ddd d MMM  HH:mm")
        color: Theme.colFg
        font.family: Theme.fontUi
        font.pixelSize: 13
        font.weight: Font.Medium
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    background: Rectangle {
        radius: 8
        color: root.down ? Theme.colBarPressed : root.hovered ? Theme.colBarHover : "transparent"
        border.width: root.visualFocus ? 2 : 0
        border.color: Theme.colFg
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
}
