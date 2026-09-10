import ".."
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "capture"
import "panels" as Panels

CaptureSurface {
    id: root

    required property var service
    readonly property string rgb: service.hex ? "rgb(" + [1, 3, 5].map(offset => {
        return parseInt(service.hex.slice(offset, offset + 2), 16);
    }).join(", ") + ")" : ""

    signal pickRequested

    title: "Pick a color"
    icon: "\uf1fb"
    preferredHeight: 360

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 80
        radius: 12
        // Sample data is intentionally not themed; every UI color comes from Theme.
        color: root.service.hex || Theme.colBgAlt
        border.color: Theme.colBorderStrong
        Accessible.role: Accessible.Graphic
        Accessible.name: root.service.hex ? "Picked color " + root.service.hex : "No color picked"
    }

    RowLayout {
        Layout.fillWidth: true

        Panels.PanelTextField {
            Layout.fillWidth: true
            leadingGlyph: "\uf292"
            text: root.service.hex
            placeholderText: "HEX"
            readOnly: true
            selectByMouse: true
            Accessible.name: "Color in HEX"
        }

        Panels.PanelButton {
            glyph: "\uf0c5"
            Accessible.name: "Copy HEX"
            ToolTip.text: Accessible.name
            ToolTip.visible: hovered || activeFocus
            ToolTip.delay: 500
            enabled: Boolean(root.service.ready && !root.service.busy && root.service.hex !== "" && root.service.tools["wl-copy"])
            onClicked: root.service.request("copy-color", {
                "text": root.service.hex
            })
        }
    }

    RowLayout {
        Layout.fillWidth: true

        Panels.PanelTextField {
            Layout.fillWidth: true
            leadingGlyph: "\uf1de"
            text: root.rgb
            placeholderText: "RGB"
            readOnly: true
            selectByMouse: true
            Accessible.name: "Color in RGB"
        }

        Panels.PanelButton {
            glyph: "\uf0c5"
            Accessible.name: "Copy RGB"
            ToolTip.text: Accessible.name
            ToolTip.visible: hovered || activeFocus
            ToolTip.delay: 500
            enabled: Boolean(root.service.ready && !root.service.busy && root.service.hex !== "" && root.service.tools["wl-copy"])
            onClicked: root.service.request("copy-color", {
                "text": root.rgb
            })
        }
    }

    Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        visible: text !== ""
        text: root.service.ready && !root.service.tools.hyprpicker ? "Install hyprpicker to pick colors." : root.service.message
        Accessible.name: text
    }

    RowLayout {
        Panels.PanelButton {
            text: "Pick pixel"
            glyph: "\uf1fb"
            enabled: Boolean(root.service.ready && !root.service.busy && root.service.tools.hyprpicker)
            onClicked: root.pickRequested()
        }

        Panels.PanelButton {
            visible: root.service.busy
            text: "Cancel"
            glyph: "\uf00d"
            onClicked: root.service.stop()
        }
    }
}
