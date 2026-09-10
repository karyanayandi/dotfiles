pragma ComponentBehavior: Bound
import ".."
import QtQuick
import QtQuick.Controls.Basic
import "panels" as Panels
import QtQuick.Layouts
import "capture"
import "../components" as Extras

CaptureSurface {
    id: root

    required property var service
    property bool video: false
    property string selectedMode: "area"

    signal captureRequested(string action, var options)

    function open(mode) {
        if (!enabled)
            return;
        if (mode === "record" || mode === "record-area") {
            video = true;
            selectedMode = mode === "record-area" ? "area" : "screen";
        } else {
            video = false;
            selectedMode = ["screen", "window", "area"].includes(mode) ? mode : "area";
        }
        opened = true;
    }

    title: "Capture"
    icon: "\uf030"
    preferredHeight: video ? 480 : 680

    RowLayout {
        Layout.fillWidth: true

        TabBar {
            id: tabs
            Layout.fillWidth: true
            implicitHeight: 44
            implicitWidth: 320
            padding: 4
            spacing: 4
            enabled: !root.service.busy
            currentIndex: root.video ? 1 : 0
            onCurrentIndexChanged: {
                root.video = currentIndex === 1;
                if (root.video && root.selectedMode === "window")
                    root.selectedMode = "area";
            }
            background: Rectangle {
                color: Theme.colInputBg
                radius: 12
            }
            Repeater {
                model: [
                    {
                        label: "Screenshot",
                        glyph: "\uf030"
                    },
                    {
                        label: "Recording",
                        glyph: "\uf03d"
                    }
                ]
                TabButton {
                    id: tab
                    required property var modelData
                    width: (tabs.availableWidth - tabs.spacing) / 2
                    implicitHeight: 36
                    text: modelData.label
                    font.family: Theme.fontUi
                    font.pixelSize: 14
                    Accessible.name: text
                    contentItem: Extras.IconLabel {
                        icon: tab.modelData.glyph
                        text: tab.text
                        font: tab.font
                        color: tab.checked ? Theme.colBg : Theme.colFg
                    }
                    background: Rectangle {
                        radius: 9
                        color: tab.checked ? Theme.colChipActive : tab.down ? Theme.colActionBg : tab.hovered ? Theme.colHoverAlpha : "transparent"
                        border.width: tab.visualFocus ? 2 : 0
                        border.color: Theme.colFg
                    }
                }
            }
        }

        Label {
            visible: root.service.recording
            text: root.service.recording ? "● REC  " + Math.floor(root.service.elapsed / 60) + ":" + String(root.service.elapsed % 60).padStart(2, "0") : ""
            color: Theme.colUrgent
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            Accessible.name: "Recording, " + root.service.elapsed + " seconds"
        }
    }

    RowLayout {
        Repeater {
            model: root.video ? ["screen", "area"] : ["screen", "window", "area"]

            Panels.PanelButton {
                required property string modelData
                checkable: true
                autoExclusive: true
                glyph: modelData === "screen" ? "\uf108" : modelData === "window" ? "\uf2d0" : "\uf125"

                text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                checked: root.selectedMode === modelData
                enabled: !root.service.busy && (modelData !== "window" || (!root.video && root.service.windowSupported))
                onClicked: root.selectedMode = modelData
                Accessible.name: text + " capture"
            }
        }
    }

    Label {
        visible: !root.video && !root.service.windowSupported
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "Window capture requires Hyprland, hyprctl, slurp and grim."
        color: Theme.colFgDim
    }

    Panels.PanelComboBox {
        id: audio
        leadingGlyph: "\uf130"

        visible: root.video
        enabled: !root.service.busy
        Layout.fillWidth: true
        model: root.service.sources
        textRole: "description"
        valueRole: "name"
        Accessible.name: "Recording audio source"
    }

    Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        visible: root.video && audio.currentValue !== "" && audio.currentIndex > 0
        text: "One audio source only. Reopen to refresh devices."
        color: Theme.colFgDim
    }

    CaptureEditor {
        id: editor
        service: root.service
        visible: !root.video && root.service.preview !== ""
        Layout.fillWidth: true
        Layout.preferredHeight: editor.preferredHeight
    }

    Label {
        Layout.fillWidth: true
        wrapMode: Text.WrapAnywhere
        visible: text !== ""
        text: root.service.message
        Accessible.role: Accessible.StaticText
        Accessible.name: text
    }

    Label {
        visible: root.service.ready && (!root.service.tools.slurp || (!root.video && !root.service.tools.grim) || (root.video && !root.service.tools["wf-recorder"]))
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "Missing capture tools. Screen/area need slurp and grim; recording needs slurp and wf-recorder."
        color: Theme.colUrgent
    }

    footer: RowLayout {
        id: actions
        Layout.fillWidth: true
        spacing: 10
        readonly property bool hasPreview: !root.video && root.service.preview !== ""
        readonly property bool recordingBusy: root.service.busy && root.service.action === "record"

        Panels.PanelButton {
            objectName: "captureStart"
            visible: !actions.recordingBusy
            Layout.fillWidth: !actions.hasPreview
            implicitHeight: 48
            tone: actions.hasPreview ? "neutral" : "primary"
            text: root.video ? "Start recording" : actions.hasPreview ? "Retake" : "Capture screenshot"
            Accessible.name: root.video ? "Start recording" : "Take screenshot"
            glyph: root.video ? "\uf111" : "\uf030"
            enabled: Boolean(root.service.ready && !root.service.busy && (root.selectedMode === "window" ? root.service.windowSupported : root.service.tools.slurp && (root.video ? root.service.tools["wf-recorder"] : root.service.tools.grim)))
            onClicked: root.captureRequested(root.video ? "record" : "screenshot", {
                "mode": root.selectedMode,
                "audio": audio.currentValue || ""
            })
        }

        Panels.PanelButton {
            visible: actions.recordingBusy
            Layout.fillWidth: true
            implicitHeight: 48
            tone: "danger"
            text: root.service.recording ? "Stop recording" : "Cancel"
            glyph: root.service.recording ? "\uf04d" : "\uf00d"
            onClicked: root.service.stop()
        }

        Panels.PanelButton {
            visible: actions.hasPreview
            Layout.fillWidth: true
            implicitHeight: 48
            tone: "primary"
            text: "Copy"
            Accessible.name: "Copy image"
            glyph: "\uf0c5"
            enabled: Boolean(!root.service.busy && root.service.ready && root.service.tools["wl-copy"])
            onClicked: root.service.request("copy-image")
        }

        Panels.PanelButton {
            visible: actions.hasPreview
            implicitHeight: 48
            implicitWidth: 48
            Accessible.name: "Save PNG"
            glyph: "\uf0c7"
            enabled: !root.service.busy && root.service.ready
            onClicked: root.service.request("save")
        }
    }
}
