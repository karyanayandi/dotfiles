import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import ".."
import "../components" as Comp

PanelWindow {
    id: win
    required property var notifs
    property var theme: Theme
    property real _targetOpacity: notifs.controlCenterVisible ? 1 : 0
    property real _centerOpacity: _targetOpacity
    Behavior on _centerOpacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    visible: notifs.controlCenterVisible || _centerOpacity > 0.01
    anchors { top: true; right: true }
    margins { top: 18; right: 18 }
    implicitWidth: Config.centerWidth
    implicitHeight: bgWrap.height
    exclusiveZone: 0
    color: "transparent"
    mask: Region { item: bgWrap }
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-center"

    Rectangle {
        id: scrim
        anchors.fill: parent
        radius: 24
        color: Theme.colBg
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
        width: Config.centerWidth; height: col.implicitHeight + 36
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
            color: Theme.colBgAlpha095
            border.color: Theme.colBorderStrong; border.width: 1

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
                        color: Theme.colFg
                        font.family: Theme.fontFamily; font.pixelSize: 17; font.weight: Font.Medium
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        visible: win.notifs.notifCount > 0
                        Layout.preferredWidth: clearText.implicitWidth + 32
                        Layout.preferredHeight: 24
                        radius: 6
                        color: clearMa.containsMouse ? Theme.colHoverAlpha : Theme.colBgAlt
                        Text { id: clearText; anchors.centerIn: parent; text: "Clear All"; color: Theme.colFg; font.family: Theme.fontFamily; font.pixelSize: 13 }
                        MouseArea { id: clearMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.notifs.dismissAll() }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 6; Layout.rightMargin: 6; Layout.bottomMargin: 6
                    Text {
                        text: "Do Not Disturb"
                        color: Theme.colFg
                        font.family: Theme.fontFamily; font.pixelSize: 17
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        Layout.preferredWidth: 46; Layout.preferredHeight: 26; radius: 8
                        color: win.notifs.doNotDisturb ? Theme.colDndChecked : Theme.colBgAlt
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Rectangle { anchors.fill: parent; radius: 8; color: dndMa.containsMouse ? Theme.colHoverAlpha : "transparent" }
                        Rectangle {
                            width: 20; height: 20; radius: 6; color: Theme.colFg
                            anchors.verticalCenter: parent.verticalCenter
                            x: win.notifs.doNotDisturb ? parent.width - width - 3 : 3
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }
                        MouseArea { id: dndMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.notifs.toggleDnd() }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; radius: 1; color: Theme.g2; opacity: 0.45; Layout.leftMargin: 6; Layout.rightMargin: 6; Layout.topMargin: 4; Layout.bottomMargin: 8 }

                Flickable {
                    id: flick
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(Config.centerMaxHeight, flickContent.implicitHeight)
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
                            color: Theme.colFg
                            font.family: Theme.fontFamily; font.pixelSize: 15; opacity: 0.9
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
                                    Text { text: "󰂚"; color: Theme.colFg; font.family: Theme.fontFamily; font.pixelSize: 15 }
                                    Text {
                                        text: grp.appName
                                        color: Theme.colFg; font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.Bold; font.letterSpacing: 0.9
                                        Layout.fillWidth: true; elide: Text.ElideRight
                                    }
                                    Text {
                                        visible: grp.notifications.length > 1
                                        text: "(" + grp.notifications.length + ")"
                                        color: Theme.colFg; font.family: Theme.fontFamily; font.pixelSize: 13; opacity: 0.8
                                    }
                                    Rectangle {
                                        visible: grp.notifications.length > 1
                                        Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 7
                                        color: cMa.containsMouse ? Theme.colHoverAlpha : "transparent"
                                        Text { anchors.centerIn: parent; text: collapsed ? "▸" : "▾"; color: Theme.colFg; font.pixelSize: 13 }
                                        MouseArea { id: cMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: collapsed = !collapsed }
                                    }
                                    Rectangle {
                                        Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 7
                                        color: caMa.containsMouse ? Theme.colHoverAlpha : "transparent"
                                        Text { anchors.centerIn: parent; text: "✕"; color: Theme.colFg; font.pixelSize: 13 }
                                        MouseArea { id: caMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.notifs.dismissGroup(grp) }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 8; Layout.rightMargin: 8
                                    spacing: 0
                                    Repeater {
                                        model: collapsed ? (grp.notifications.length > 0 ? [grp.notifications[0]] : []) : grp.notifications
                                        delegate: Item {
                                            required property var modelData
                                            property var notif: modelData
                                            Layout.fillWidth: true
                                            implicitHeight: card.implicitHeight + 4
                                            Layout.topMargin: 4

                                            Comp.NotificationCard {
                                                id: card
                                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                                notification: notif
                                                onCloseRequested: notif.dismiss()
                                            }
                                        }
                                    }
                                    Text {
                                        visible: collapsed && grp.notifications.length > 1
                                        text: "+" + (grp.notifications.length - 1) + " more"
                                        color: Theme.g4; font.family: Theme.fontFamily; font.pixelSize: 13
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
