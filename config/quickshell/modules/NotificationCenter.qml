import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: win
    required property var theme
    required property var notifs
    property real _targetOpacity: notifs.controlCenterVisible ? 1 : 0
    property real _centerOpacity: _targetOpacity
    Behavior on _centerOpacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    visible: notifs.controlCenterVisible || _centerOpacity > 0.01
    anchors { top: true; right: true }
    margins { top: 18; right: 18 }
    implicitWidth: 420
    implicitHeight: 920
    exclusiveZone: 0
    color: "transparent"
    mask: Region { item: bgWrap }
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-center"

    Rectangle {
        id: scrim
        anchors.fill: parent
        radius: 24
        color: theme.colBg
        opacity: win._centerOpacity * 0.85
        Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        MouseArea {
            anchors.fill: parent
            enabled: win.notifs.controlCenterVisible
            onClicked: win.notifs.controlCenterVisible = false
        }
    }

    Item {
        id: bgWrap
        anchors.top: parent.top; anchors.right: parent.right
        width: 420; height: bg.height
        property real slide: win.notifs.controlCenterVisible ? 0 : 28
        transform: Translate { x: bgWrap.slide }
        opacity: win._centerOpacity
        scale: 0.97 + win._centerOpacity * 0.03
        Behavior on slide { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 24
        color: theme.colBgAlpha095
        border.color: theme.colBorderStrong; border.width: 1

        ColumnLayout {
            id: col
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            anchors.margins: 18
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6; Layout.leftMargin: 6; Layout.rightMargin: 6; Layout.bottomMargin: 6
                Text {
                    text: "Notifications"
                    color: theme.colFg
                    font.family: theme.fontFamily; font.pixelSize: 17; font.weight: Font.Medium
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

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 6; Layout.rightMargin: 6; Layout.bottomMargin: 6
                Text {
                    text: "Do Not Disturb"
                    color: theme.colFg
                    font.family: theme.fontFamily; font.pixelSize: 17
                    Layout.fillWidth: true
                }
                Rectangle {
                    Layout.preferredWidth: 46; Layout.preferredHeight: 26; radius: 8
                    color: win.notifs.doNotDisturb ? theme.colDndChecked : theme.colBgAlt
                    Behavior on color { ColorAnimation { duration: 200 } }
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

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; radius: 1; color: theme.g2; opacity: 0.45; Layout.leftMargin: 6; Layout.rightMargin: 6; Layout.topMargin: 4; Layout.bottomMargin: 8 }

            Flickable {
                id: flick
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(720, flickContent.implicitHeight)
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
                                        color: "transparent"
                                        implicitHeight: cardBg.implicitHeight
                                        Layout.topMargin: 4; Layout.bottomMargin: 0

                                        Rectangle {
                                            id: cardBg
                                            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                            implicitHeight: cardInner.implicitHeight + 16
                                            radius: 16
                                            color: theme.colBgAlt
                                            border.color: notif.urgency === NotificationUrgency.Critical ? theme.colCritical : "transparent"
                                            border.width: notif.urgency === NotificationUrgency.Critical ? 1 : 0

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
                                                anchors.margins: 8
                                                spacing: 4

                                                RowLayout {
                                                    Layout.fillWidth: true
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
                                                RowLayout {
                                                    visible: notif.actions.filter(a => a.identifier !== "activate" && a.text !== "Activate").length > 0
                                                    Layout.fillWidth: true
                                                    Layout.leftMargin: 0; Layout.rightMargin: 0; Layout.bottomMargin: 0; Layout.topMargin: 0
                                                    spacing: 0
                                                    Layout.preferredHeight: 38
                                                    Repeater {
                                                        model: notif.actions.filter(a => a.identifier !== "activate" && a.text !== "Activate")
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
}
