pragma ComponentBehavior: Bound
import ".."
import "../services" as Services
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property bool active: visible
    property string helperPath: decodeURIComponent(Qt.resolvedUrl("../scripts/removable-drives.py").toString().replace(/^file:\/\//, ""))

    spacing: 8

    Services.ControlDataSource {
        id: source

        script: root.helperPath
        active: root.active
        interval: 5000
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: "\uf0a0"
            color: Theme.colFg
            font.family: Theme.fontFamily
            font.pixelSize: 18
        }
        Text {
            Layout.fillWidth: true
            text: "Removable drives"
            color: Theme.colFg
            font.family: Theme.fontUi
            font.pixelSize: 16
        }

        ControlAction {
            glyph: "\uf021"
            Accessible.name: "Refresh removable drives"
            enabled: !source.busy
            onClicked: source.request([])
        }
    }

    Text {
        Layout.fillWidth: true
        visible: text !== ""
        text: source.result.message || (source.result.ok !== true ? "Waiting for UDisks2" : source.result.devices && source.result.devices.length ? "Unmount all volumes before ejecting." : "No removable drives")
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        color: Theme.colFgDim
        font.family: Theme.fontUi
        font.pixelSize: 12
    }

    Repeater {
        model: source.result.devices || []

        delegate: ColumnLayout {
            id: volume

            required property var modelData

            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: volume.modelData.name
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: Theme.colFg
                font.family: Theme.fontUi
                font.pixelSize: 14
            }

            Text {
                Layout.fillWidth: true
                text: volume.modelData.mounts.length ? volume.modelData.mounts.join("\n") : "Not mounted"
                textFormat: Text.PlainText
                wrapMode: Text.WrapAnywhere
                color: Theme.colFgDim
                font.family: Theme.fontUi
                font.pixelSize: 12
            }

            RowLayout {
                ControlAction {
                    text: volume.modelData.mounts.length ? "Unmount" : "Mount"
                    glyph: volume.modelData.mounts.length ? "\uf127" : "\uf0c1"
                    Accessible.name: text + " " + volume.modelData.name
                    enabled: !source.busy
                    onClicked: source.request([volume.modelData.mounts.length ? "unmount" : "mount", volume.modelData.path])
                }

                ControlAction {
                    text: "Eject"
                    glyph: "\uf052"
                    Accessible.name: "Eject " + volume.modelData.name
                    enabled: !source.busy && volume.modelData.canEject
                    onClicked: source.request(["eject", volume.modelData.path])
                }
            }
        }
    }
}
