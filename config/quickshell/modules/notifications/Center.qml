import "../.."
import "../../components" as Comp
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: win
    objectName: "notificationCenter"

    required property var notifs
    property var theme: Theme

    function toggleStacks() {
        let expand = false;
        for (let i = 0; i < groups.count; i++) {
            const group = groups.itemAt(i);
            if (group && group.grp.notifications.length > 1 && group.collapsed)
                expand = true;
        }
        for (let i = 0; i < groups.count; i++) {
            const group = groups.itemAt(i);
            if (group)
                group.collapsed = !expand;
        }
    }

    IpcHandler {
        target: "notificationStacks"
        function toggle() {
            win.toggleStacks();
        }
    }

    visible: notifs.controlCenterVisible
    implicitWidth: Config.centerWidth
    implicitHeight: Math.min(Config.centerMaxHeight, Math.max(280, flickContent.implicitHeight + 160))
    Keys.onEscapePressed: win.notifs.controlCenterVisible = false

    ColumnLayout {
        id: col

        anchors.fill: parent
        anchors.margins: 18
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.bottomMargin: 6

            Text {
                text: "Notifications"
                color: Theme.colFg
                font.family: Theme.fontUi
                font.pixelSize: 22
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }

            Button {
                id: closeCenter

                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                Accessible.name: "Close notification center"
                onClicked: win.notifs.controlCenterVisible = false

                background: Rectangle {
                    radius: 10
                    color: closeCenter.down ? Theme.g2 : closeCenter.hovered ? Theme.g1 : "transparent"
                    border.width: closeCenter.visualFocus ? 1 : 0
                    border.color: Theme.g7
                }

                contentItem: Text {
                    text: "\uf00d"
                    font.family: Theme.fontFamily
                    color: Theme.colFgDim
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Rectangle {
                visible: win.notifs.notifCount > 0
                Layout.preferredWidth: clearText.implicitWidth + 32
                Layout.preferredHeight: 32
                radius: 6
                color: clearMa.pressed ? Theme.g2 : clearMa.containsMouse ? Theme.g1 : Theme.g16

                Text {
                    id: clearText

                    anchors.centerIn: parent
                    text: "Clear all"
                    color: Theme.colFg
                    font.family: Theme.fontUi
                    font.pixelSize: 13
                }

                MouseArea {
                    id: clearMa

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.notifs.dismissAll()
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 18
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.bottomMargin: 6

            Text {
                text: "Do not disturb"
                color: Theme.colFg
                font.family: Theme.fontUi
                font.pixelSize: 14
                Layout.fillWidth: true
            }

            Switch {
                id: dndSwitch

                Layout.preferredWidth: 48
                Layout.preferredHeight: 32
                checked: win.notifs.doNotDisturb
                Accessible.name: "Do not disturb"
                onClicked: win.notifs.toggleDnd()

                indicator: Rectangle {
                    width: 48
                    height: 28
                    y: (dndSwitch.height - height) / 2
                    radius: 14
                    color: dndSwitch.checked ? Theme.g7 : Theme.g2
                    border.width: dndSwitch.visualFocus ? 2 : 0
                    border.color: Theme.colFg

                    Rectangle {
                        width: 22
                        height: 22
                        radius: 11
                        y: 3
                        x: dndSwitch.checked ? 23 : 3
                        color: dndSwitch.checked ? Theme.colBg : Theme.colFg

                        Behavior on x {
                            NumberAnimation {
                                duration: Config.animFast
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            radius: 1
            color: Theme.g2
            opacity: 0.45
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.topMargin: 4
            Layout.bottomMargin: 8
        }

        Flickable {
            id: flick

            property var _dep: win.notifs.notifCount

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: flickContent.implicitHeight
            contentWidth: width
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: flickContent

                width: flick.width
                spacing: 0

                Text {
                    visible: win.notifs.notifCount === 0
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 64
                    Layout.bottomMargin: 40
                    text: "You’re all caught up"
                    color: Theme.colFg
                    font.family: Theme.fontUi
                    font.pixelSize: 15
                    opacity: 0.9
                }

                Repeater {
                    id: groups
                    model: {
                        let _ = win.notifs.notifCount;
                        return win.notifs.grouped();
                    }

                    delegate: ColumnLayout {
                        id: group
                        objectName: "notificationStack"

                        required property var modelData
                        property var grp: modelData
                        property bool collapsed: true

                        Layout.fillWidth: true
                        spacing: 0

                        RowLayout {
                            visible: grp.notifications.length > 0
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            Layout.rightMargin: 8
                            Layout.topMargin: 14
                            Layout.bottomMargin: 6
                            spacing: 6

                            Text {
                                text: "󰂚"
                                color: Theme.colFgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 15
                            }

                            Text {
                                text: grp.appName
                                color: Theme.colFg
                                font.family: Theme.fontUi
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                font.letterSpacing: 0
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: grp.notifications.length > 1
                                text: "(" + grp.notifications.length + ")"
                                color: Theme.colFg
                                font.family: Theme.fontUi
                                font.pixelSize: 13
                                opacity: 0.8
                            }

                            Button {
                                id: collapseButton

                                visible: grp.notifications.length > 1
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                Accessible.name: group.collapsed ? "Expand notifications" : "Collapse notifications"
                                onClicked: group.collapsed = !group.collapsed

                                background: Rectangle {
                                    radius: 10
                                    color: collapseButton.down ? Theme.g2 : collapseButton.hovered ? Theme.g1 : "transparent"
                                    border.width: collapseButton.visualFocus ? 1 : 0
                                    border.color: Theme.g7
                                }

                                contentItem: Text {
                                    text: group.collapsed ? "\uf077" : "\uf078"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    color: Theme.colFgDim
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                radius: 7
                                color: caMa.pressed ? Theme.g2 : caMa.containsMouse ? Theme.g1 : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf00d"
                                    font.family: Theme.fontFamily
                                    color: Theme.colFg
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    id: caMa

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.notifs.dismissGroup(grp)
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            Layout.rightMargin: 8
                            spacing: 0

                            Repeater {
                                model: collapsed ? (grp.notifications.length > 0 ? [grp.notifications[0]] : []) : grp.notifications

                                delegate: Item {
                                    required property var modelData
                                    property var notif: modelData

                                    Layout.fillWidth: true
                                    implicitHeight: card.implicitHeight + 4 + (group.collapsed ? Math.min(2, group.grp.notifications.length - 1) * 7 : 0)
                                    Layout.topMargin: 4

                                    Repeater {
                                        model: group.collapsed ? Math.min(2, group.grp.notifications.length - 1) : 0

                                        delegate: Rectangle {
                                            required property int index
                                            readonly property int depth: index + 1

                                            x: depth * 7
                                            y: depth * 7
                                            width: parent.width - depth * 14
                                            height: card.implicitHeight
                                            radius: card.cardRadius
                                            color: depth === 1 ? Theme.g1 : Theme.g2
                                            border.color: Theme.colBorderStrong
                                            border.width: 1
                                            z: -depth
                                        }
                                    }

                                    Comp.NotificationCard {
                                        id: card

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        notification: notif
                                        onCloseRequested: notif.dismiss()
                                    }
                                }
                            }

                            Text {
                                visible: collapsed && grp.notifications.length > 1
                                text: "+" + (grp.notifications.length - 1) + " more"
                                color: Theme.g4
                                font.family: Theme.fontUi
                                font.pixelSize: 13
                                Layout.leftMargin: 4
                                Layout.topMargin: 6
                            }
                        }
                    }
                }
            }
        }
    }
}
