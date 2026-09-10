import ".."
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "capture"
import "panels" as Panels

CaptureSurface {
    id: root

    readonly property string rgb: service.hex ? "rgb(" + [1, 3, 5].map(offset => {
        return parseInt(service.hex.slice(offset, offset + 2), 16);
    }).join(", ") + ")" : ""
    required property var service

    signal pickRequested

    icon: "\uf1fb"
    title: "Pick a color"

    Rectangle {
        Accessible.name: root.service.hex ? "Picked color " + root.service.hex : "No color picked"
        Accessible.role: Accessible.Graphic
        Layout.fillWidth: true
        Layout.preferredHeight: 80
        border.color: Theme.colBorderStrong
        // Sample data is intentionally not themed; every UI color comes from Theme.
        color: root.service.hex || Theme.colBgAlt
        radius: 12
    }

    RowLayout {
        Layout.fillWidth: true

        Panels.PanelTextField {
            Accessible.name: "Color in HEX"
            Layout.fillWidth: true
            leadingGlyph: "\uf292"
            placeholderText: "HEX"
            readOnly: true
            selectByMouse: true
            text: root.service.hex
        }

        Panels.PanelButton {
            Accessible.name: "Copy HEX"
            ToolTip.delay: 500
            ToolTip.text: Accessible.name
            ToolTip.visible: hovered || activeFocus
            enabled: Boolean(root.service.ready && !root.service.busy && root.service.hex !== "" && root.service.tools["wl-copy"])
            glyph: "\uf0c5"
            onClicked: root.service.request("copy-color", {
                "text": root.service.hex
            })
        }
    }

    RowLayout {
        Layout.fillWidth: true

        Panels.PanelTextField {
            Accessible.name: "Color in RGB"
            Layout.fillWidth: true
            leadingGlyph: "\uf1de"
            placeholderText: "RGB"
            readOnly: true
            selectByMouse: true
            text: root.rgb
        }

        Panels.PanelButton {
            Accessible.name: "Copy RGB"
            ToolTip.delay: 500
            ToolTip.text: Accessible.name
            ToolTip.visible: hovered || activeFocus
            enabled: Boolean(root.service.ready && !root.service.busy && root.service.hex !== "" && root.service.tools["wl-copy"])
            glyph: "\uf0c5"
            onClicked: root.service.request("copy-color", {
                "text": root.rgb
            })
        }
    }

    Label {
        Accessible.name: text
        Layout.fillWidth: true
        text: root.service.ready && !root.service.tools.hyprpicker ? "Install hyprpicker to pick colors." : root.service.hasResult ? "" : root.service.message
        visible: text !== ""
        wrapMode: Text.WordWrap
    }

    RowLayout {
        Panels.PanelButton {
            enabled: Boolean(root.service.ready && !root.service.busy && root.service.tools.hyprpicker)
            glyph: "\uf1fb"
            text: "Pick pixel"
            onClicked: root.pickRequested()
        }

        Panels.PanelButton {
            glyph: "\uf00d"
            text: "Cancel"
            visible: root.service.busy
            onClicked: root.service.stop()
        }
    }
}
