import "../.."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root

    required property string title
    property string icon: ""
    property string ipcTarget: ""
    default property alias body: content.data
    property alias footer: footerContent.data
    property bool opened: false
    readonly property real bodyHeight: content.implicitHeight + (footerContent.visible ? footerContent.implicitHeight + 16 : 0)

    visible: opened
    implicitWidth: 440
    implicitHeight: Math.min(620, bodyHeight + 96)
    // Island owns window, material, and interruptible geometry transitions.
    onOpenedChanged: {
        if (opened) {
            Qt.callLater(() => {
                if (root.enabled && root.opened)
                    closeButton.forceActiveFocus();
            });
        }
    }

    IpcHandler {
        enabled: root.ipcTarget !== ""
        function toggle() {
            if (root.enabled)
                root.opened = !root.opened;
        }

        function open() {
            if (root.enabled)
                root.opened = true;
        }

        function close() {
            root.opened = false;
        }

        target: root.ipcTarget
    }

    Connections {
        target: root.Window.window
        function onActiveFocusItemChanged() {
            const item = root.Window.window.activeFocusItem;
            if (!item)
                return;
            let ancestor = item.parent;
            while (ancestor && ancestor !== content)
                ancestor = ancestor.parent;
            if (!ancestor)
                return;
            const y = item.mapToItem(content, 0, 0).y;
            const flick = scroll.contentItem as Flickable;
            if (!flick)
                return;
            if (y < flick.contentY)
                flick.contentY = y;
            else if (y + item.height > flick.contentY + flick.height)
                flick.contentY = y + item.height - flick.height;
        }
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16
        Keys.onEscapePressed: root.opened = false

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                visible: root.icon !== ""
                text: root.icon
                color: Theme.colFg
                font.family: Theme.fontFamily
                font.pixelSize: 22
            }
            Text {
                Layout.fillWidth: true
                text: root.title
                color: Theme.colFg
                font.family: Theme.fontUi
                font.pixelSize: 22
                font.bold: true
            }

            PanelButton {
                id: closeButton

                glyph: "\uf00d"
                Accessible.name: "Close " + root.title
                onClicked: root.opened = false
            }
        }

        ScrollView {
            id: scroll

            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            clip: true
            font.family: Theme.fontUi
            font.pixelSize: 14
            palette.window: Theme.colBg
            palette.windowText: Theme.colFg
            palette.text: Theme.colFg
            palette.base: Theme.colBgAlt
            palette.button: Theme.colBgAlt
            palette.buttonText: Theme.colFg
            palette.highlight: Theme.colChipActive
            palette.highlightedText: Theme.colBg

            ColumnLayout {
                id: content

                width: scroll.availableWidth
                spacing: 12
            }
        }

        ColumnLayout {
            id: footerContent
            Layout.fillWidth: true
            visible: children.length > 0
            spacing: 8
        }
    }
}
