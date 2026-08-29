import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root
    required property var notification
    property int imgSize: 40
    property int cardRadius: 16
    property color cardBg: Theme.colBgAlt
    property bool showClose: true
    signal closeRequested()

    property var filteredActions: notification ? notification.actions.filter(a => a.identifier !== "activate" && a.text !== "Activate") : []

    radius: cardRadius
    color: cardBg
    border.color: notification && notification.urgency === NotificationUrgency.Critical ? Theme.colCritical : "transparent"
    border.width: notification && notification.urgency === NotificationUrgency.Critical ? 1 : 0
    implicitHeight: inner.implicitHeight + 16

    Rectangle {
        visible: root.showClose
        anchors.top: parent.top; anchors.right: parent.right
        anchors.topMargin: 3; anchors.rightMargin: 3
        width: 26; height: 26; radius: 7
        color: clsMa.containsMouse ? Theme.g2 : "transparent"
        Text { anchors.centerIn: parent; text: "✕"; color: Theme.colFg; font.family: Theme.fontFamily; font.pixelSize: 11 }
        MouseArea { id: clsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.closeRequested() }
    }

    ColumnLayout {
        id: inner
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 8
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 6; Layout.rightMargin: 6; Layout.topMargin: 6; Layout.bottomMargin: 6
            spacing: 0
            Image {
                property string _src: root.notification ? (root.notification.image !== "" ? root.notification.image : root.notification.appIcon) : ""
                visible: _src !== "" && (_src.indexOf("/") !== -1 || _src.indexOf("file:") === 0)
                source: _src
                Layout.preferredWidth: visible ? root.imgSize : 0
                Layout.preferredHeight: visible ? root.imgSize : 0
                Layout.rightMargin: visible ? 12 : 0
                fillMode: Image.PreserveAspectCrop
                onStatusChanged: if (status === Image.Error) visible = false
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Layout.rightMargin: 26
                Text {
                    text: root.notification ? (root.notification.summary || root.notification.appName || "Notification") : ""
                    color: Theme.colFg; font.family: Theme.fontFamily; font.pixelSize: 15; font.weight: Font.DemiBold
                    wrapMode: Text.Wrap; Layout.fillWidth: true; elide: Text.ElideRight
                }
                Text {
                    visible: root.notification ? root.notification.body !== "" : false
                    text: root.notification ? root.notification.body : ""
                    color: Theme.colFg; linkColor: Theme.g9; font.family: Theme.fontFamily; font.pixelSize: 13; opacity: 0.95
                    wrapMode: Text.Wrap; Layout.fillWidth: true; maximumLineCount: 6; lineHeight: 1.15
                }
                Text {
                    visible: root.notification ? (root.notification.appName !== "" && root.notification.summary !== "") : false
                    text: root.notification ? root.notification.appName : ""
                    color: Theme.g4; font.family: Theme.fontFamily; font.pixelSize: 11
                    Layout.fillWidth: true; elide: Text.ElideRight
                }
            }
        }

        RowLayout {
            visible: root.filteredActions.length > 0
            Layout.fillWidth: true
            spacing: 6
            Layout.preferredHeight: 38
            Repeater {
                model: root.filteredActions
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Layout.leftMargin: 6
                    Layout.rightMargin: index === root.filteredActions.length - 1 ? 6 : 0
                    Layout.topMargin: 6; Layout.bottomMargin: 6
                    radius: 12
                    color: aMa.containsMouse ? Theme.colSelected : Theme.colActionBg
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Text { anchors.centerIn: parent; text: modelData.text; color: Theme.colFg; font.family: Theme.fontFamily; font.pixelSize: 13; elide: Text.ElideRight }
                    MouseArea { id: aMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.invoke() }
                }
            }
        }
    }
}
