import QtQuick
import QtQuick.Layouts
import "../.."

Text {
    id: root
    color: Theme.colFg
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    Layout.alignment: Qt.AlignVCenter
    Layout.rightMargin: 10
    leftPadding: 10
    rightPadding: 10
    property date now: new Date()
    text: Qt.formatDateTime(now, clockMouse.containsMouse ? "HH:mm · dddd, dd MMMM" : "HH:mm")

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
    MouseArea {
        id: clockMouse
        anchors.fill: parent
        hoverEnabled: true
    }
}
