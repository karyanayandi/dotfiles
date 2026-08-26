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
    leftPadding: 10; rightPadding: 10
    text: Qt.formatDateTime(new Date(), "HH:mm")
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.text = Qt.formatDateTime(new Date(), "HH:mm") }
    MouseArea { anchors.fill: parent; hoverEnabled: true }
}
