import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: win
    required property var theme
    required property var notifs
    anchors { top: true; right: true }
    margins { top: 16; right: 16 }
    implicitWidth: 400
    implicitHeight: list.implicitHeight
    exclusiveZone: 0
    color: "transparent"
    mask: Region { item: list }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifs"
    visible: notifs.popups.length > 0 && !notifs.controlCenterVisible

    ColumnLayout {
        id: list
        anchors.top: parent.top
        anchors.right: parent.right
        width: 400
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
                Layout.topMargin: 0; Layout.bottomMargin: 16
                opacity: 0
                property real _enter: 0
                Component.onCompleted: { opacity = 1; _enter = 1 }
                transform: Translate { x: (1 - row._enter) * 24 }
                scale: 0.96 + row._enter * 0.04
                Behavior on opacity { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
                Behavior on _enter { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                Rectangle {
                    id: bg
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                    implicitHeight: inner.implicitHeight + 20
                    radius: 24
                    color: theme.colBgAlpha085
                    border.color: notif.urgency === NotificationUrgency.Critical ? theme.colCritical : theme.colBorder
                    border.width: notif.urgency === NotificationUrgency.Critical ? 2 : 1

                    Timer {
                        id: ttl
                        interval: {
                            if (row.notif.urgency === NotificationUrgency.Low) return 2000
                            if (row.notif.urgency === NotificationUrgency.Critical) return 6000
                            if (row.notif.expireTimeout > 0) return row.notif.expireTimeout
                            return 4000
                        }
                        running: true
                        onTriggered: win.notifs.removePopup(row.notif)
                    }
                    MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: ttl.stop(); onExited: ttl.restart() }

                    Rectangle {
                        anchors.top: parent.top; anchors.right: parent.right
                        anchors.topMargin: 6; anchors.rightMargin: 6
                        width: 26; height: 26; radius: 7
                        color: cMa.containsMouse ? theme.g2 : "transparent"
                        Text { anchors.centerIn: parent; text: "✕"; color: theme.colFg; font.family: theme.fontFamily; font.pixelSize: 13 }
                        MouseArea { id: cMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.notifs.removePopup(row.notif) }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    ColumnLayout {
                        id: inner
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                        anchors.leftMargin: 18; anchors.rightMargin: 18; anchors.topMargin: 18; anchors.bottomMargin: 10
                        spacing: 0

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Image {
                                property string _src: row.notif.image !== "" ? row.notif.image : row.notif.appIcon
                                visible: _src !== "" && (_src.indexOf("/") !== -1 || _src.indexOf("file:") === 0)
                                source: _src
                                Layout.preferredWidth: visible ? 48 : 0; Layout.preferredHeight: visible ? 48 : 0
                                Layout.rightMargin: visible ? 20 : 0
                                Layout.topMargin: 10; Layout.bottomMargin: 10
                                fillMode: Image.PreserveAspectCrop
                                onStatusChanged: if (status === Image.Error) visible = false
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Layout.rightMargin: 28
                                Text {
                                    text: row.notif.summary || row.notif.appName || "Notification"
                                    color: theme.colFg; font.family: theme.fontFamily; font.pixelSize: 15; font.weight: Font.ExtraBold
                                    wrapMode: Text.Wrap; Layout.fillWidth: true; elide: Text.ElideRight
                                }
                                Text {
                                    visible: row.notif.body !== ""
                                    text: row.notif.body; color: theme.colFg; font.family: theme.fontFamily; font.pixelSize: 13; opacity: 0.95
                                    wrapMode: Text.Wrap; Layout.fillWidth: true; maximumLineCount: 6; lineHeight: 1.15
                                }
                                Text {
                                    visible: row.notif.appName !== "" && row.notif.summary !== ""
                                    text: row.notif.appName; color: theme.g4; font.family: theme.fontFamily; font.pixelSize: 11
                                    Layout.fillWidth: true; elide: Text.ElideRight
                                }
                            }
                        }
                        RowLayout {
                            visible: row.notif.actions.filter(a => a.identifier !== "activate" && a.text !== "Activate").length > 0
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            spacing: 6
                            Repeater {
                                model: row.notif.actions.filter(a => a.identifier !== "activate" && a.text !== "Activate")
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true; implicitHeight: 30; radius: 8
                                    color: aMa.containsMouse ? theme.colHoverAlpha : theme.colBgAlt
                                    border.color: aMa.containsMouse ? theme.colSelected : "transparent"; border.width: 1
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Text { anchors.centerIn: parent; text: modelData.text; color: theme.colFg; font.family: theme.fontFamily; font.pixelSize: 13; elide: Text.ElideRight }
                                    MouseArea { id: aMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.invoke() }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
