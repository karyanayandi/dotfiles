import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import "../.."
import "../../components" as Comp

PanelWindow {
    id: win
    required property var notifs
    property var theme: Theme

    anchors {
        top: true
        right: true
    }
    margins {
        top: 16
        right: 16
    }
    implicitWidth: Config.popupWidth
    implicitHeight: list.implicitHeight
    exclusiveZone: 0
    color: "transparent"
    mask: Region {
        item: list
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifs"
    visible: notifs.popups.length > 0 && !notifs.controlCenterVisible

    ColumnLayout {
        id: list
        anchors.top: parent.top
        anchors.right: parent.right
        width: Config.popupWidth
        spacing: 0

        Repeater {
            model: win.notifs.popups
            delegate: Rectangle {
                id: row
                required property var modelData
                property var notif: modelData
                Layout.fillWidth: true
                implicitHeight: bg.implicitHeight
                color: "transparent"
                Layout.bottomMargin: 16
                opacity: 0
                property real _enter: 0
                Component.onCompleted: {
                    opacity = 1;
                    _enter = 1;
                }
                transform: Translate {
                    x: (1 - row._enter) * 24
                }
                scale: 0.96 + row._enter * 0.04
                Behavior on opacity {
                    NumberAnimation {
                        duration: 360
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on _enter {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    id: bg
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    implicitHeight: card.implicitHeight + 40
                    radius: 24
                    color: Theme.colBgAlpha085
                    border.color: row.notif.urgency === NotificationUrgency.Critical ? Theme.colCritical : Theme.colBorder
                    border.width: row.notif.urgency === NotificationUrgency.Critical ? 2 : 1

                    Timer {
                        id: ttl
                        interval: {
                            if (row.notif.urgency === NotificationUrgency.Low)
                                return Config.popupTtlLow;
                            if (row.notif.urgency === NotificationUrgency.Critical)
                                return Config.popupTtlCritical;
                            if (row.notif.expireTimeout > 0)
                                return row.notif.expireTimeout;
                            return Config.popupTtlNormal;
                        }
                        running: true
                        onTriggered: win.notifs.removePopup(row.notif)
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: ttl.stop()
                        onExited: ttl.restart()
                    }

                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 6
                        anchors.rightMargin: 6
                        width: 26
                        height: 26
                        radius: 7
                        color: cMa.containsMouse ? Theme.g2 : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: Theme.colFg
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                        MouseArea {
                            id: cMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.notifs.removePopup(row.notif)
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }
                        }
                    }

                    Comp.NotificationCard {
                        id: card
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        anchors.topMargin: 26
                        anchors.bottomMargin: 14
                        notification: row.notif
                        imgSize: 48
                        cardRadius: 0
                        cardBg: "transparent"
                        showClose: false
                    }
                }
            }
        }
    }
}
