import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: barWin
    required property var theme
    required property var audio
    required property var notifs

    property string submap: ""
    Connections {
        target: Hyprland
        function onRawEvent(event) { if (event.name === "submap") barWin.submap = event.data }
    }

    anchors { bottom: true; left: true; right: true }
    implicitHeight: 48
    exclusiveZone: 48
    color: "transparent"
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Top

    Rectangle {
        id: bar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        implicitWidth: Math.max(400, Math.min(900, barContent.implicitWidth + 32))
        width: implicitWidth
        height: 38
        radius: 10
        color: barWin.theme.colBg

        RowLayout {
            id: barContent
            anchors.fill: parent
            anchors.leftMargin: 12; anchors.rightMargin: 12
            anchors.topMargin: 4; anchors.bottomMargin: 4
            spacing: 4

            // workspaces
            RowLayout {
                id: wsRow
                Layout.leftMargin: 15; Layout.rightMargin: 15; spacing: 0
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
                        color: isUrgent ? barWin.theme.colUrgent : (wsMouse.containsMouse ? barWin.theme.colAccent : "transparent")
                        Rectangle {
                            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                            height: isFocused || isActive ? 3 : 0
                            color: barWin.theme.colFg
                            visible: isFocused || isActive
                        }
                        Text {
                            id: wsText; anchors.centerIn: parent
                            text: modelData.name
                            color: barWin.theme.colFg
                            font.family: barWin.theme.fontFamily; font.pixelSize: barWin.theme.fontSize
                        }
                        MouseArea {
                            id: wsMouse; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.activate()
                        }
                    }
                }
            }

            Text {
                visible: barWin.submap !== "" && barWin.submap !== "default"
                text: barWin.submap
                color: barWin.theme.colFg
                font.family: barWin.theme.fontFamily; font.pixelSize: barWin.theme.fontSize
                font.italic: true
                leftPadding: 10; rightPadding: 10
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            // tray icons
            Text {
                text: "󰍛"; color: barWin.theme.colFg; font.family: barWin.theme.fontFamily; font.pixelSize: barWin.theme.fontSize + 6
                Layout.alignment: Qt.AlignVCenter; leftPadding: 10; rightPadding: 10
                MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { let p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent); p.command = ["ghostty","-e","btm"]; p.running = true } }
            }
            Text {
                text: ""; color: barWin.theme.colFg; font.family: barWin.theme.fontFamily; font.pixelSize: barWin.theme.fontSize
                Layout.alignment: Qt.AlignVCenter; leftPadding: 10; rightPadding: 10
                MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { let p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent); p.command = ["ghostty","-e","bluetui"]; p.running = true } }
            }

            Text {
                id: volText
                text: barWin.audio.volumeIcon
                color: barWin.theme.colFg; font.family: barWin.theme.fontFamily; font.pixelSize: barWin.theme.fontSize + 10
                Layout.alignment: Qt.AlignVCenter; leftPadding: 10; rightPadding: 10
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) barWin.audio.volMuteToggle()
                        else { let p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent); p.command = ["ghostty","-e","wiremix"]; p.running = true }
                    }
                    onWheel: w => { if (w.angleDelta.y > 0) barWin.audio.volRaise(); else if (w.angleDelta.y < 0) barWin.audio.volLower() }
                }
            }

            Item {
                Layout.preferredWidth: 36; Layout.preferredHeight: 30; Layout.rightMargin: 20
                Text { id: notifText; anchors.centerIn: parent; text: barWin.notifs.doNotDisturb ? "" : ""; color: barWin.theme.colFg; font.family: barWin.theme.fontFamily; font.pixelSize: barWin.theme.fontSize + 6 }
                Text { visible: barWin.notifs.hasUnread; anchors.top: parent.top; anchors.right: parent.right; anchors.topMargin: 6; anchors.rightMargin: 6; text: ""; color: barWin.theme.colUrgent; font.family: barWin.theme.fontFamily; font.pixelSize: 10 }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) barWin.notifs.toggleDnd()
                        else barWin.notifs.toggleCenter()
                    }
                }
            }

            Text {
                id: clock; color: barWin.theme.colFg; font.family: barWin.theme.fontFamily; font.pixelSize: barWin.theme.fontSize
                Layout.alignment: Qt.AlignVCenter; Layout.rightMargin: 10; leftPadding: 10; rightPadding: 10
                text: Qt.formatDateTime(new Date(), "HH:mm")
                Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm") }
                MouseArea { anchors.fill: parent; hoverEnabled: true }
            }
        }
    }
}
