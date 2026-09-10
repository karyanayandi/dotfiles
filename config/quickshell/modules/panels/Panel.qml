import "../.."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root

    default property alias body: content.data
    readonly property real bodyHeight: content.implicitHeight + (footerContent.visible ? footerContent.implicitHeight + 16 : 0)
    property alias footer: footerContent.data
    property string icon: ""
    property string ipcTarget: ""
    property bool opened: false
    required property string title

    implicitHeight: bodyHeight + 96
    implicitWidth: 440
    visible: opened

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
        function close() {
            root.opened = false;
        }
        function open() {
            if (root.enabled)
                root.opened = true;
        }
        function toggle() {
            if (root.enabled)
                root.opened = !root.opened;
        }

        enabled: root.ipcTarget !== ""
        target: root.ipcTarget
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
                color: Theme.colFg
                font.family: Theme.fontFamily
                font.pixelSize: 22
                text: root.icon
                visible: root.icon !== ""
            }
            Text {
                Layout.fillWidth: true
                color: Theme.colFg
                font.bold: true
                font.family: Theme.fontUi
                font.pixelSize: 22
                text: root.title
            }
            PanelButton {
                id: closeButton

                Accessible.name: "Close " + root.title
                glyph: "\uf00d"

                onClicked: root.opened = false
            }
        }
        Pane {
            id: bodyPane

            Layout.fillHeight: true
            Layout.fillWidth: true
            font.family: Theme.fontUi
            font.pixelSize: 14
            padding: 0
            palette.base: Theme.colBgAlt
            palette.button: Theme.colBgAlt
            palette.buttonText: Theme.colFg
            palette.highlight: Theme.colChipActive
            palette.highlightedText: Theme.colBg
            palette.text: Theme.colFg
            palette.window: Theme.colBg
            palette.windowText: Theme.colFg

            background: Item {
            }

            ColumnLayout {
                id: content

                spacing: 12
                width: bodyPane.availableWidth
            }
        }
        ColumnLayout {
            id: footerContent

            Layout.fillWidth: true
            spacing: 8
            visible: children.length > 0
        }
    }
}
