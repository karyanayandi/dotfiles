import ".."
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "panels" as Panels

Rectangle {
    id: root

    property bool shown: false
    property bool failed: false
    property string message: ""

    function show(text, isError) {
        expiry.stop();
        message = text;
        failed = isError;
        shown = true;
        expiry.restart();
    }

    radius: 18
    color: Theme.colBg
    border.color: failed ? Theme.colUrgent : Theme.colBorderStrong
    border.width: 1
    implicitHeight: row.implicitHeight + 24
    height: implicitHeight
    opacity: shown ? 1 : 0
    visible: opacity > 0
    enabled: shown
    scale: Config.reducedMotion || shown ? 1 : 0.97
    transformOrigin: Item.Bottom
    Accessible.role: Accessible.AlertMessage
    Accessible.name: (failed ? "Error: " : "Success: ") + message

    Timer {
        id: expiry

        interval: root.failed ? 6500 : 3200
        onTriggered: root.shown = false
    }

    // Keep clicks on feedback from dismissing the panel underneath.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: expiry.stop()
        onExited: {
            if (root.shown) {
                expiry.restart();
            }
        }
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Label {
            text: root.failed ? "\uf06a" : "\uf00c"
            font.family: Theme.fontFamily
            font.pixelSize: 24
            color: root.failed ? Theme.colUrgent : Theme.colFg
            Accessible.ignored: true
        }

        Label {
            Layout.fillWidth: true
            text: root.message
            color: Theme.colFg
            font.family: Theme.fontUi
            font.pixelSize: 14
            wrapMode: Text.WrapAnywhere
        }

        Panels.PanelButton {
            Accessible.name: "Dismiss " + (root.failed ? "error" : "confirmation")
            glyph: "\uf00d"
            onClicked: root.shown = false
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Config.animFast
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        enabled: !Config.reducedMotion

        NumberAnimation {
            duration: Config.animNormal
            easing.type: Easing.OutCubic
        }
    }
}
