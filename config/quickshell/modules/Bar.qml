import ".."
import "../components" as Extras
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Hyprland
import "bar" as BarParts

Item {
    id: barWin

    required property var audio
    required property var notifs
    required property var controls
    required property var capture
    property var theme: Theme
    property string submap: ""

    signal launcherRequested(string mode)
    signal panelRequested(string panel)

    implicitWidth: Config.barMinWidth
    implicitHeight: Config.barHeight


    Connections {
        function onRawEvent(event) {
            if (event.name === "submap")
                barWin.submap = event.data;
        }
        target: Hyprland
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Config.barSideMargin
        anchors.rightMargin: Config.barSideMargin
        spacing: 2

        BarParts.Workspaces {
            submap: barWin.submap
        }
        Item { Layout.fillWidth: true }
        AbstractButton {
            id: recordingButton
            visible: barWin.capture.recording
            implicitWidth: contentItem.implicitWidth + 16
            implicitHeight: 28
            hoverEnabled: true
            Accessible.name: "Recording for " + barWin.capture.elapsed + " seconds. Stop recording"
            onClicked: barWin.capture.stop()
            contentItem: Extras.IconLabel {
                icon: "\uf111"
                text: Math.floor(barWin.capture.elapsed / 60) + ":" + String(barWin.capture.elapsed % 60).padStart(2, "0")
                color: Theme.colUrgent
            }
            background: Rectangle {
                radius: 6
                color: recordingButton.down ? Theme.colBarPressed : recordingButton.hovered ? Theme.colBarHover : "transparent"
                border.width: recordingButton.visualFocus ? 2 : 0
                border.color: Theme.colFg
            }
        }
        BarParts.MenuButton {
            glyph: ""
            label: "Bluetooth devices"
            onClicked: barWin.launcherRequested("bluetooth")
        }
        BarParts.MenuButton {
            glyph: barWin.audio.volumeIcon
            label: "Sound. Right click to mute"
            onClicked: barWin.panelRequested("audio")
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.MiddleButton | Qt.RightButton
                onClicked: barWin.audio.volMuteToggle()
                onWheel: event => {
                    if (event.angleDelta.y > 0)
                        barWin.audio.volRaise();
                    else if (event.angleDelta.y < 0)
                        barWin.audio.volLower();
                }
            }
        }
        BarParts.MenuButton {
            id: notificationButton
            glyph: barWin.notifs.doNotDisturb ? "" : ""
            label: "Notifications. Right click for Do Not Disturb"
            selected: barWin.notifs.controlCenterVisible
            onClicked: barWin.notifs.toggleCenter()
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 4
                width: 5
                height: 5
                radius: 3
                visible: barWin.notifs.hasUnread
                color: Theme.colUrgent
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: barWin.notifs.toggleDnd()
            }
        }
    }

    BarParts.Clock {
        anchors.centerIn: parent
        onClicked: barWin.panelRequested("calendar")
    }
}
