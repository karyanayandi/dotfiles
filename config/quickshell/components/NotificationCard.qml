import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

Rectangle {
    id: root

    required property var notification
    property int imgSize: 40
    property int cardRadius: 16
    property color cardBg: Theme.g16
    property bool showClose: true
    property var filteredActions: notification ? notification.actions.filter((a) => {
        return a.identifier !== "activate" && a.text !== "Activate";
    }) : []

    signal closeRequested()

    radius: cardRadius
    color: cardBg
    border.color: notification && notification.urgency === NotificationUrgency.Critical ? Theme.colCritical : Theme.colBorder
    border.width: 1
    implicitHeight: inner.implicitHeight + 32

    ColumnLayout {
        id: inner

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Image {
                readonly property string icon: root.notification ? (root.notification.image || root.notification.appIcon || "") : ""

                source: !icon ? "" : icon.indexOf("/") !== -1 ? icon : Quickshell.iconPath(icon, "dialog-information")
                visible: status === Image.Ready
                Layout.preferredWidth: root.imgSize
                Layout.preferredHeight: root.imgSize
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            Text {
                text: root.notification ? root.notification.appName || "Notification" : ""
                textFormat: Text.PlainText
                color: Theme.colFgDim
                font.family: Theme.fontUi
                font.pixelSize: 12
                font.weight: Font.Medium
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Button {
                id: closeButton

                visible: root.showClose
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                Accessible.name: "Dismiss notification"
                onClicked: root.closeRequested()

                background: Rectangle {
                    radius: 10
                    color: closeButton.down ? Theme.g2 : closeButton.hovered ? Theme.g1 : "transparent"
                    border.width: closeButton.visualFocus ? 1 : 0
                    border.color: Theme.g7
                }

                contentItem: Text {
                    text: "\uf00d"
                    font.family: Theme.fontFamily
                    color: Theme.colFgDim
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

            }

        }

        Text {
            text: root.notification ? root.notification.summary || "Notification" : ""
            textFormat: Text.PlainText
            color: Theme.colFg
            font.family: Theme.fontUi
            font.pixelSize: 16
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            visible: text.length > 0
            text: root.notification ? root.notification.body : ""
            color: Theme.colFgDim
            linkColor: Theme.g9
            font.family: Theme.fontUi
            font.pixelSize: 14
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            maximumLineCount: 6
            elide: Text.ElideRight
            lineHeight: 1.2
        }

        ColumnLayout {
            visible: root.filteredActions.length > 0
            Layout.fillWidth: true
            Layout.topMargin: 2
            spacing: 6

            Repeater {
                model: root.filteredActions

                delegate: Button {
                    id: actionButton

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    text: modelData.text
                    onClicked: modelData.invoke()

                    background: Rectangle {
                        radius: 10
                        color: actionButton.down ? Theme.g3 : actionButton.hovered ? Theme.g2 : Theme.g1
                        border.width: actionButton.visualFocus ? 1 : 0
                        border.color: Theme.g7
                    }

                    contentItem: Text {
                        text: actionButton.text
                        textFormat: Text.PlainText
                        color: Theme.colFg
                        font.family: Theme.fontUi
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                }

            }

        }

    }

}
