import "../.."
import "../../components" as Comp
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland

PanelWindow {
    id: win

    required property var notifs
    property var theme: Theme

    implicitWidth: Config.popupWidth
    implicitHeight: list.implicitHeight
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifs"
    visible: notifs.popups.length > 0 && !notifs.controlCenterVisible

    anchors {
        top: true
        right: true
    }

    margins {
        top: 16
        right: 16
    }

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
                property real _enter: 0

                Layout.fillWidth: true
                implicitHeight: bg.implicitHeight
                color: "transparent"
                Layout.bottomMargin: 10
                opacity: _enter
                Component.onCompleted: {
                    _enter = 1;
                }

                Rectangle {
                    id: bg

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    implicitHeight: card.implicitHeight
                    radius: 24
                    color: "transparent"
                    border.color: row.notif.urgency === NotificationUrgency.Critical ? Theme.colCritical : Theme.colBorder
                    border.width: 0

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

                    HoverHandler {
                        id: popupHover

                        onHoveredChanged: {
                            if (hovered)
                                ttl.stop();
                            else
                                ttl.restart();
                        }
                    }

                    Comp.NotificationCard {
                        id: card

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        notification: row.notif
                        imgSize: 32
                        cardRadius: 20
                        cardBg: Theme.colBg
                        onCloseRequested: win.notifs.removePopup(row.notif)
                    }

                }

                transform: Translate {
                    x: (1 - row._enter) * 12
                }

                Behavior on _enter {
                    NumberAnimation {
                        duration: Config.animNormal
                        easing.type: Easing.OutCubic
                    }

                }

            }

        }

    }

    mask: Region {
        item: list
    }

}
