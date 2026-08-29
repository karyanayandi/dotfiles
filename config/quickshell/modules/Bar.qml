import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "bar" as BarParts
import ".."

PanelWindow {
    id: barWin
    required property var audio
    required property var notifs
    property var theme: Theme

    property string submap: ""
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "submap")
                barWin.submap = event.data;
        }
    }

    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: Config.barExclusiveZone
    exclusiveZone: Config.barExclusiveZone
    color: "transparent"
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Top

    Rectangle {
        id: bar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Config.barBottomMargin
        implicitWidth: Math.max(Config.barMinWidth, Math.min(Config.barMaxWidth, barContent.implicitWidth + 32))
        width: implicitWidth
        height: Config.barHeight
        radius: Config.barRadius
        color: Theme.colBgAlpha085
        border.color: Theme.colBorder
        border.width: 1

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
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent);
                        p.command = ["ghostty", "-e", "btm"];
                        p.running = true;
                    }
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
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent);
                        p.command = ["ghostty", "-e", "bluetui"];
                        p.running = true;
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
                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.OutCubic
                    }
                }
                MouseArea {
                    id: volMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton)
                            barWin.audio.volMuteToggle();
                        else {
                            let p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent);
                            p.command = ["ghostty", "-e", "wiremix"];
                            p.running = true;
                        }
                    }
                    onWheel: w => {
                        if (w.angleDelta.y > 0)
                            barWin.audio.volRaise();
                        else if (w.angleDelta.y < 0)
                            barWin.audio.volLower();
                    }
                }
            }

            Item {
                id: notifBell
                Layout.preferredWidth: 36
                Layout.preferredHeight: 30
                Layout.rightMargin: 20
                scale: bellMa.pressed ? 0.92 : 1
                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.OutCubic
                    }
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
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton)
                            barWin.notifs.toggleDnd();
                        else
                            barWin.notifs.toggleCenter();
                    }
                }
            }

            BarParts.Clock {}
        }
    }
}
