import QtQuick
import ".."

Item {
    id: root

    property string icon: ""
    property string text: ""
    property color color: Theme.colFg
    property font font: Qt.font({
        family: Theme.fontUi,
        pixelSize: 14
    })
    property bool wrap: false

    implicitWidth: (iconText.visible ? iconText.implicitWidth : 0) + row.spacing + label.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: root.icon && root.text ? 8 : 0

        Text {
            id: iconText
            visible: root.icon !== ""
            text: root.icon
            color: root.color
            font.family: Theme.fontFamily
            font.pixelSize: root.font.pixelSize + 2
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            id: label
            visible: root.text !== ""
            width: !visible ? 0 : root.wrap ? Math.max(0, root.width - (iconText.visible ? iconText.implicitWidth : 0) - row.spacing) : implicitWidth
            wrapMode: root.wrap ? Text.WordWrap : Text.NoWrap
            horizontalAlignment: Text.AlignHCenter
            text: root.text
            color: root.color
            font: root.font
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
