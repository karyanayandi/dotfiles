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

    implicitWidth: bar.implicitWidth
    implicitHeight: Config.barHeight

    Connections {
        function onRawEvent(event) {
            if (event.name === "submap")
                barWin.submap = event.data;

        }

        target: Hyprland
    }

    Rectangle {
        id: bar

        anchors.fill: parent
        implicitWidth: Math.max(Config.barMinWidth, Math.min(Config.barMaxWidth, barContent.implicitWidth + 32))
        color: "transparent"

        RowLayout {
            id: barContent

            anchors.fill: parent
            anchors.leftMargin: Config.barSideMargin
            anchors.rightMargin: Config.barSideMargin
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            spacing: 4

            BarParts.Workspaces {
                submap: barWin.submap
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: "󰍛"
                color: Theme.colFg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                Layout.alignment: Qt.AlignVCenter
                leftPadding: 10
                rightPadding: 10

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: cpuMouse.pressed ? Theme.colActionBg : cpuMouse.containsMouse ? Theme.colBgAlt : "transparent"
                    z: -1
                }

                MouseArea {
                    id: cpuMouse

                    hoverEnabled: true
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWin.controls.opened = !barWin.controls.opened
                }

            }

            Text {
                text: ""
                color: Theme.colFg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                Layout.alignment: Qt.AlignVCenter
                leftPadding: 10
                rightPadding: 10

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: bluetoothMouse.pressed ? Theme.colActionBg : bluetoothMouse.containsMouse ? Theme.colBgAlt : "transparent"
                    z: -1
                }

                MouseArea {
                    id: bluetoothMouse

                    hoverEnabled: true
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        barWin.launcherRequested("bluetooth");
                    }
                }

            }

            Text {
                id: volText

                text: barWin.audio.volumeIcon
                color: Theme.colFg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                Layout.alignment: Qt.AlignVCenter
                leftPadding: 10
                rightPadding: 10
                scale: volMa.pressed ? 0.92 : 1

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: volMa.pressed ? Theme.colActionBg : volMa.containsMouse ? Theme.colBgAlt : "transparent"
                    z: -1
                }

                MouseArea {
                    id: volMa

                    hoverEnabled: true
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.MiddleButton)
                            barWin.audio.volMuteToggle();
                        else
                            barWin.panelRequested("audio");
                    }
                    onWheel: (w) => {
                        if (w.angleDelta.y > 0)
                            barWin.audio.volRaise();
                        else if (w.angleDelta.y < 0)
                            barWin.audio.volLower();
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.OutCubic
                    }

                }

            }

            Item {
                id: notifBell

                Layout.preferredWidth: 36
                Layout.preferredHeight: 30
                Layout.rightMargin: 20
                scale: bellMa.pressed ? 0.92 : 1

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: bellMa.pressed ? Theme.colActionBg : bellMa.containsMouse ? Theme.colBgAlt : "transparent"
                }

                Text {
                    id: notifText

                    anchors.centerIn: parent
                    text: barWin.notifs.doNotDisturb ? "" : ""
                    color: Theme.colFg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                Text {
                    visible: barWin.notifs.hasUnread
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 6
                    anchors.rightMargin: 6
                    text: ""
                    color: Theme.colUrgent
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }

                MouseArea {
                    id: bellMa

                    hoverEnabled: true
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton)
                            barWin.notifs.toggleDnd();
                        else
                            barWin.notifs.toggleCenter();
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.OutCubic
                    }

                }

            }

            AbstractButton {
                id: recordingButton

                hoverEnabled: true
                visible: barWin.capture.recording
                implicitWidth: contentItem.implicitWidth + 16
                implicitHeight: 30
                Accessible.name: "Recording for " + barWin.capture.elapsed + " seconds. Stop recording"
                onClicked: barWin.capture.stop()

                contentItem: Extras.IconLabel {
                    icon: "\uf111"
                    text: Math.floor(barWin.capture.elapsed / 60) + ":" + String(barWin.capture.elapsed % 60).padStart(2, "0")
                    color: Theme.colUrgent
                }

                background: Rectangle {
                    radius: 8
                    color: recordingButton.down ? Theme.colActionBg : recordingButton.hovered ? Theme.colBgAlt : "transparent"
                    border.width: recordingButton.visualFocus ? 2 : 0
                    border.color: Theme.colFg
                }

            }

            BarParts.Clock {
                onClicked: barWin.panelRequested("calendar")
            }

        }

    }

}
