import "../.."
import QtQuick
import QtQuick.Layouts

Text {
    id: root

    property date now: new Date()

    color: Theme.colFg
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    Layout.alignment: Qt.AlignVCenter
    Layout.rightMargin: 10
    leftPadding: 10
    rightPadding: 10
    text: Qt.formatDateTime(now, "HH:mm")

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

}
