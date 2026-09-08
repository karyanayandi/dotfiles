import "../.."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    required property var modelData
    required property int index
    property int selectedIndex: 0
    readonly property bool selected: index === selectedIndex

    signal hovered(int index)
    signal activated(int index, bool ctrl)

    width: ListView.view ? ListView.view.width : 0
    height: 60

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Theme.g2
        visible: pointer.pressed
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 32

        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: 10
            color: Theme.g16
            border.color: Theme.colBorder
            border.width: 1

            IconImage {
                anchors.centerIn: parent
                visible: root.modelData.kind === "app" && !!root.modelData.icon
                source: visible ? Quickshell.iconPath(root.modelData.icon, "application-x-executable") : ""
                implicitWidth: 22
                implicitHeight: 22
            }

            Image {
                anchors.centerIn: parent
                visible: root.modelData.kind === "clip" && !!root.modelData.img
                source: visible ? "file://" + root.modelData.img : ""
                width: 26
                height: 26
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            Text {
                anchors.centerIn: parent
                visible: !(root.modelData.kind === "app" && !!root.modelData.icon) && !(root.modelData.kind === "clip" && !!root.modelData.img)
                text: root.modelData.icon || "\u{f003b}"
                color: root.selected ? Theme.g7 : Theme.colFg
                font.family: root.modelData.kind === "emoji" ? "Noto Color Emoji" : Theme.fontFamily
                font.pixelSize: root.modelData.kind === "emoji" ? 18 : 15
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 3

            Text {
                text: root.modelData.title || ""
                color: Theme.colFg
                font.family: Theme.fontUi
                font.pixelSize: 15
                font.weight: root.selected ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.modelData.subtitle || ""
                color: Theme.g19
                font.family: Theme.fontUi
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text.length > 0
            }

        }

        Text {
            visible: !!root.modelData.actionHint
            text: root.modelData.actionHint || ""
            color: Theme.colMuted
            font.family: Theme.fontUi
            font.pixelSize: 11
            Layout.alignment: Qt.AlignVCenter
        }

    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered(root.index)
        onClicked: (mouse) => {
            return root.activated(root.index, !!(mouse.modifiers & Qt.ControlModifier));
        }
    }

}
