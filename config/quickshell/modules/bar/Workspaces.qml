import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../.."

RowLayout {
    id: root
    spacing: 0
    property string submap: ""

    Layout.leftMargin: 15
    Layout.rightMargin: 15
    Layout.alignment: Qt.AlignVCenter

    WheelHandler {
        onWheel: e => {
            if (e.angleDelta.y > 0) Hyprland.dispatch("workspace e-1")
            else if (e.angleDelta.y < 0) Hyprland.dispatch("workspace e+1")
        }
    }

    Repeater {
        model: Hyprland.workspaces
        delegate: Rectangle {
            required property var modelData
            property bool isActive: modelData.active === true
            property bool isFocused: modelData.focused === true
            property bool isUrgent: modelData.urgent === true
            Layout.preferredHeight: 30
            Layout.preferredWidth: wsText.implicitWidth + 20
            color: isUrgent ? Theme.colUrgent : (wsMouse.containsMouse ? Theme.colAccent : "transparent")
            scale: wsMouse.pressed ? 0.96 : 1
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Rectangle {
                anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                height: isFocused || isActive ? 3 : 0
                color: Theme.colFg
                visible: isFocused || isActive
            }
            Text {
                id: wsText; anchors.centerIn: parent
                text: modelData.name
                color: Theme.colFg
                font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
            }
            MouseArea {
                id: wsMouse; anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: modelData.activate()
            }
        }
    }

    Text {
        visible: root.submap !== "" && root.submap !== "default"
        text: root.submap
        color: Theme.colFg
        font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize
        font.italic: true
        leftPadding: 10; rightPadding: 10
        Layout.alignment: Qt.AlignVCenter
    }
}