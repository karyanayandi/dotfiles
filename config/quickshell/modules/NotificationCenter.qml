import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

// 1:1 swaync control-center — 420x860, margin 18, padding 12, groups stacked
PanelWindow {
    id: win
    required property var theme
    required property var notifs
    visible: notifs.controlCenterVisible
    anchors { top: true; right: true }
    margins { top: 18; right: 18 }
    implicitWidth: 420
    implicitHeight: 860
    exclusiveZone: 0
    color: "transparent"
    mask: Region { item: bg }
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-center"

    MouseArea {
        anchors.fill: parent
        enabled: win.visible
        onClicked: m => {
            const p = bg.mapFromItem(win.contentItem, m.x, m.y)
            if (p.x < 0 || p.x > bg.width || p.y < 0 || p.y > bg.height) win.notifs.controlCenterVisible = false
        }
    }

    Rectangle {
        id: bg
        anchors.top: parent.top; anchors.right: parent.right
        width: 420
        height: Math.min(860, col.implicitHeight + 24)
        radius: 24
        // swaync: background alpha(@background,0.95) border 1px @gruvbox0 shadow 0 0 10 rgba0,0,0,0.6
        color: theme.colBgAlpha095
        border.color: theme.g0; border.width: 1

        ColumnLayout {
            id: col
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            anchors.margins: 12 // swaync padding 12
            spacing: 0

            // widget-title: margin 6, font 1.2em, button bg @background-alt radius 6 padding 4 16
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6; Layout.leftMargin: 6; Layout.rightMargin: 6; Layout.bottomMargin: 6
                Text {
                    text: "Notifications"
                    color: theme.colFg
                    font.family: theme.fontFamily; font.pixelSize: 17; font.weight: Font.Medium // 1.2em = 16.8
                    Layout.fillWidth: true
                }
                Rectangle {
                    visible: win.notifs.notifCount > 0
                    Layout.preferredWidth: clearText.implicitWidth + 32
                    Layout.preferredHeight: 24
                    radius: 6
                    color: clearMa.containsMouse ? theme.colHoverAlpha : theme.colBgAlt
                    Text { id: clearText; anchors.centerIn: parent; text: "Clear All"; color: theme.colFg; font.family: theme.fontFamily; font.pixelSize: 13 }
                    MouseArea { id: clearMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.notifs.dismissAll() }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            // widget-dnd: margin 6, font 1.2rem, switch bg @background-alt radius 8 padding 2, checked #458588, slider #ebdbb2 radius 6
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 6; Layout.rightMargin: 6; Layout.bottomMargin: 6
                Text {
                    text: "Do Not Disturb"
                    color: theme.colFg
                    font.family: theme.fontFamily; font.pixelSize: 17 // 1.2rem
                    Layout.fillWidth: true
                }
                Rectangle {
                    Layout.preferredWidth: 46; Layout.preferredHeight: 26; radius: 8
                    color: win.notifs.doNotDisturb ? theme.colDndChecked : theme.colBgAlt
                    Behavior on color { ColorAnimation { duration: 200 } }
                    // hover like swaync switch:hover
                    Rectangle { anchors.fill: parent; radius: 8; color: dndMa.containsMouse ? theme.colHoverAlpha : "transparent" }
                    Rectangle {
                        width: 20; height: 20; radius: 6; color: theme.colFg
                        anchors.verticalCenter: parent.verticalCenter
                        x: win.notifs.doNotDisturb ? parent.width - width - 3 : 3
                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }
                    MouseArea { id: dndMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.notifs.toggleDnd() }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: theme.g2; opacity: 0.45; Layout.leftMargin: 6; Layout.rightMargin: 6; Layout.topMargin: 4; Layout.bottomMargin: 8 }

            Flickable {
                id: flick
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(640, flickContent.implicitHeight)
                clip: true
                contentHeight: flickContent.implicitHeight
                contentWidth: width
                boundsBehavior: Flickable.StopAtBounds
                property var _dep: win.notifs.notifCount

                ColumnLayout {
                    id: flickContent
                    width: flick.width
                    spacing: 0

                    Text {
                        visible: win.notifs.notifCount === 0
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 40
                        text: "No Notifications"
                        color: theme.colFg
                        font.family: theme.fontFamily; font.pixelSize: 15; opacity: 0.9
                    }

                    Repeater {
                        model: { let _ = win.notifs.notifCount; return win.notifs.grouped() }
                        delegate: ColumnLayout {
                            required property var modelData
                            property var grp: modelData
                            property bool collapsed: false
                            Layout.fillWidth: true
                            spacing: 0

                            // notification-group: margin 2 8 2 8
                            // headers: bold 1.25rem letter-spacing 2px
                            RowLayout {
                                visible: grp.notifications.length > 0
                                Layout.fillWidth: true
                                Layout.leftMargin: 8; Layout.rightMargin: 8; Layout.topMargin: 2; Layout.bottomMargin: 2
                                spacing: 6
                                Text { text: "󰂚"; color: theme.colFg; font.family: theme.fontFamily; font.pixelSize: 15; opacity: 1 }
                                Text {
                                    text: grp.appName
                                    color: theme.colFg; font.family: theme.fontFamily; font.pixelSize: 14; font.weight: Font.Bold; font.letterSpacing: 0.9
                                    Layout.fillWidth: true; elide: Text.ElideRight
                                }
                                Text {
                                    visible: grp.notifications.length > 1
                                    text: "(" + grp.notifications.length + ")"
                                    color: theme.colFg; font.family: theme.fontFamily; font.pixelSize: 13; opacity: 0.8
                                }
                                Rectangle {
                                    visible: grp.notifications.length > 1
                                    Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 7
                                    color: cMa.containsMouse ? theme.colHoverAlpha : "transparent"
                                    Text { anchors.centerIn: parent; text: collapsed ? "▸" : "▾"; color: theme.colFg; font.pixelSize: 13 }
                                    MouseArea { id: cMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: collapsed = !collapsed }
                                }
                                Rectangle {
                                    Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 7
                                    color: caMa.containsMouse ? theme.colHoverAlpha : "transparent"
                                    Text { anchors.centerIn: parent; text: "✕"; color: theme.colFg; font.pixelSize: 13 }
                                    MouseArea { id: caMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.notifs.dismissGroup(grp) }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 8; Layout.rightMargin: 8
                                spacing: 0
                                Repeater {
                                    model: collapsed ? (grp.notifications.length > 0 ? [grp.notifications[0]] : []) : grp.notifications
                                    delegate: Rectangle {
                                        required property var modelData
                                        property var notif: modelData
                                        Layout.fillWidth: true
                                        // swaync: .notification-background bg @background-alt radius 16 margin 4 0 padding 4
                                        // we are inside group, so outer is this
                                        color: "transparent"
                                        implicitHeight: cardBg.implicitHeight
                                        Layout.topMargin: 4; Layout.bottomMargin: 0

                                        Rectangle {
                                            id: cardBg
                                            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                            implicitHeight: cardInner.implicitHeight + 8
                                            radius: 16
                                            color: theme.colBgAlt
                                            border.color: notif.urgency === NotificationUrgency.Critical ? theme.colCritical : "transparent"
                                            border.width: notif.urgency === NotificationUrgency.Critical ? 1 : 0

                                            // close button — swaync: background transparent radius 6 padding 4 hover @selected (#d5c4a1) — we use g2 for dark fidelity
                                            Rectangle {
                                                anchors.top: parent.top; anchors.right: parent.right
                                                anchors.topMargin: 3; anchors.rightMargin: 3
                                                width: 26; height: 26; radius: 7
                                                color: clsMa.containsMouse ? theme.g2 : "transparent"
                                                Text { anchors.centerIn: parent; text: "✕"; color: theme.colFg; font.family: theme.fontFamily; font.pixelSize: 11 }
                                                MouseArea { id: clsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: notif.dismiss() }
                                            }

                                            ColumnLayout {
                                                id: cardInner
                                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                                anchors.margins: 4
                                                spacing: 0

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    // swaync: .notification-content margin 6 padding 8 6 2 2
                                                    Layout.leftMargin: 6; Layout.rightMargin: 6; Layout.topMargin: 6; Layout.bottomMargin: 6
                                                    spacing: 0
                                                    Image {
                                                        property string _src: notif.image !== "" ? notif.image : notif.appIcon
                                                        visible: _src !== "" && (_src.indexOf("/") !== -1 || _src.indexOf("file:") === 0)
                                                        source: _src
                                                        Layout.preferredWidth: visible ? 40 : 0; Layout.preferredHeight: visible ? 40 : 0
                                                        Layout.rightMargin: visible ? 12 : 0
                                                        fillMode: Image.PreserveAspectCrop
                                                        onStatusChanged: if (status === Image.Error) visible = false
                                                    }
                                                    ColumnLayout {
                                                        Layout.fillWidth: true; spacing: 2
                                                        Layout.rightMargin: 26
                                                        Text {
                                                            text: notif.summary || notif.appName || "Notification"
                                                            color: theme.colFg; font.family: theme.fontFamily; font.pixelSize: 15; font.weight: Font.DemiBold
                                                            wrapMode: Text.Wrap; Layout.fillWidth: true; elide: Text.ElideRight
                                                        }
                                                        Text {
                                                            visible: notif.body !== ""
                                                            text: notif.body; color: theme.colFg; font.family: theme.fontFamily; font.pixelSize: 13
                                                            opacity: 0.95; wrapMode: Text.Wrap; Layout.fillWidth: true; maximumLineCount: 6
                                                        }
                                                        Text {
                                                            visible: notif.appName !== "" && notif.summary !== ""
                                                            text: notif.appName; color: theme.g4; font.family: theme.fontFamily; font.pixelSize: 11
                                                            Layout.fillWidth: true; elide: Text.ElideRight
                                                        }
                                                    }
                                                }
                                                // actions — swaync: bg alpha(@selected,0.6) radius 12 margin 6 hover @selected
                                                RowLayout {
                                                    visible: notif.actions.length > 0
                                                    Layout.fillWidth: true
                                                    Layout.leftMargin: 0; Layout.rightMargin: 0; Layout.bottomMargin: 0; Layout.topMargin: 0
                                                    spacing: 0
                                                    // min-height 3.4em like swaync
                                                    Layout.preferredHeight: 38
                                                    Repeater {
                                                        model: notif.actions
                                                        delegate: Rectangle {
                                                            required property var modelData
                                                            Layout.fillWidth: true; Layout.fillHeight: true
                                                            Layout.leftMargin: 6; Layout.rightMargin: index === notif.actions.length -1 ? 6 : 0
                                                            Layout.topMargin: 6; Layout.bottomMargin: 6
                                                            radius: 12
                                                            color: aMa.containsMouse ? theme.colSelected : theme.colActionBg
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
                                Text {
                                    visible: collapsed && grp.notifications.length > 1
                                    text: "+" + (grp.notifications.length - 1) + " more"
                                    color: theme.g4; font.family: theme.fontFamily; font.pixelSize: 13
                                    Layout.leftMargin: 4; Layout.topMargin: 2
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
