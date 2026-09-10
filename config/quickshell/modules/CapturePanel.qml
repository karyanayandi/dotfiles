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

    property string selectedMode: "area"
    required property var service
    property bool video: false
    property bool expanded: false
    property bool configuring: false
    readonly property bool editing: !video && service.preview !== "" && !configuring
    fillBody: editing

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
        configuring = true;
        opened = true;
    }

    icon: "\uf030"
    title: editing ? "Edit screenshot" : video ? "Record screen" : "Take screenshot"

    Connections {
        target: root.service
        function onPreviewChanged() {
            if (root.service.preview !== "")
                root.configuring = false;
        }
    }

    footer: RowLayout {
        id: actions

        readonly property bool hasPreview: !root.video && root.service.preview !== ""
        readonly property bool recordingBusy: root.service.busy && root.service.action === "record"

        Layout.fillWidth: true
        spacing: 10

        Panels.PanelButton {
            visible: root.editing
            text: root.expanded ? "Compact" : "Expand"
            glyph: root.expanded ? "\uf066" : "\uf065"
            Accessible.name: root.expanded ? "Use compact editor" : "Expand editor to screen"
            onClicked: root.expanded = !root.expanded
        }
        Panels.PanelButton {
            Accessible.name: root.video ? "Start recording" : "Take screenshot"
            Layout.fillWidth: !actions.hasPreview
            enabled: Boolean(root.service.ready && !root.service.busy && (root.selectedMode === "window" ? root.service.windowSupported : root.service.tools.slurp && (root.video ? root.service.tools["wf-recorder"] : root.service.tools.grim)))
            glyph: root.video ? "\uf111" : "\uf030"
            implicitHeight: 48
            objectName: "captureStart"
            text: root.video ? "Start recording" : actions.hasPreview ? "Retake" : "Capture screenshot"
            tone: actions.hasPreview ? "neutral" : "primary"
            visible: !actions.recordingBusy

            onClicked: {
                if (root.editing) {
                    root.configuring = true;
                    return;
                }
                root.captureRequested(root.video ? "record" : "screenshot", {
                    "mode": root.selectedMode,
                    "audio": audio.currentValue || ""
                });
            }
        }
        Panels.PanelButton {
            Layout.fillWidth: true
            glyph: root.service.recording ? "\uf04d" : "\uf00d"
            implicitHeight: 48
            text: root.service.recording ? "Stop recording" : "Cancel"
            tone: "danger"
            visible: actions.recordingBusy

            onClicked: root.service.stop()
        }
        Panels.PanelButton {
            Accessible.name: "Copy image"
            Layout.fillWidth: true
            enabled: Boolean(!root.service.busy && root.service.ready && root.service.tools["wl-copy"])
            glyph: "\uf0c5"
            implicitHeight: 48
            text: "Copy"
            tone: "primary"
            visible: actions.hasPreview

            onClicked: root.service.request("copy-image")
        }
        Panels.PanelButton {
            Accessible.name: "Save PNG"
            enabled: !root.service.busy && root.service.ready
            glyph: "\uf0c7"
            implicitHeight: 48
            text: "Save PNG"
            visible: actions.hasPreview

            onClicked: root.service.request("save")
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: !root.editing && !root.service.recording

        TabBar {
            id: tabs

            Layout.fillWidth: true
            currentIndex: root.video ? 1 : 0
            enabled: !root.service.busy
            implicitHeight: 44
            implicitWidth: 320
            padding: 4
            spacing: 4

            background: Rectangle {
                color: Theme.colInputBg
                radius: 12
            }

            onCurrentIndexChanged: {
                root.video = currentIndex === 1;
                if (root.video && root.selectedMode === "window")
                    root.selectedMode = "area";
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

                    Accessible.name: text
                    font.family: Theme.fontUi
                    font.pixelSize: 14
                    implicitHeight: 36
                    text: modelData.label
                    width: (tabs.availableWidth - tabs.spacing) / 2

                    background: Rectangle {
                        border.color: Theme.colFg
                        border.width: tab.visualFocus ? 2 : 0
                        color: tab.checked ? Theme.colChipActive : tab.down ? Theme.colActionBg : tab.hovered ? Theme.colHoverAlpha : "transparent"
                        radius: 9
                    }
                    contentItem: Extras.IconLabel {
                        color: tab.checked ? Theme.colBg : Theme.colFg
                        font: tab.font
                        icon: tab.modelData.glyph
                        text: tab.text
                    }
                }
            }
        }
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 156
        radius: 16
        color: Theme.colInputBg
        visible: root.service.recording

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "● Recording"
                color: Theme.colUrgent
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                Accessible.name: "Recording, " + root.service.elapsed + " seconds"
                text: Math.floor(root.service.elapsed / 60) + ":" + String(root.service.elapsed % 60).padStart(2, "0")
                font.pixelSize: 36
                font.family: Theme.fontUi
                color: Theme.colFg
            }
            Label {
                text: "You can close this panel. Recording will continue."
                color: Theme.colFgDim
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        visible: !root.editing && !root.service.recording
        Repeater {
            model: root.video ? ["screen", "area"] : ["screen", "window", "area"]

            Panels.PanelButton {
                required property string modelData

                Layout.fillWidth: true
                implicitHeight: 64
                Accessible.name: text + " capture"
                autoExclusive: true
                checkable: true
                checked: root.selectedMode === modelData
                enabled: !root.service.busy && (modelData !== "window" || (!root.video && root.service.windowSupported))
                glyph: modelData === "screen" ? "\uf108" : modelData === "window" ? "\uf2d0" : "\uf125"
                text: modelData.charAt(0).toUpperCase() + modelData.slice(1)

                onClicked: root.selectedMode = modelData
            }
        }
    }
    Label {
        Layout.fillWidth: true
        color: Theme.colFgDim
        text: "Window capture requires Hyprland, hyprctl, slurp and grim."
        visible: !root.editing && !root.video && !root.service.windowSupported
        wrapMode: Text.WordWrap
    }
    Label {
        Layout.fillWidth: true
        color: Theme.colFgDim
        text: root.selectedMode === "screen" ? "Click a monitor to capture its entire screen. No area selection." : "Drag to select the area to capture."
        visible: !root.editing && !root.service.recording && root.selectedMode !== "window"
        wrapMode: Text.WordWrap
    }
    Panels.PanelComboBox {
        id: audio

        Accessible.name: "Recording audio source"
        Layout.fillWidth: true
        enabled: !root.service.busy
        leadingGlyph: "\uf130"
        model: root.service.sources
        textRole: "description"
        valueRole: "name"
        visible: root.video && !root.service.recording
    }
    Label {
        Layout.fillWidth: true
        color: Theme.colFgDim
        text: "One audio source only. Reopen to refresh devices."
        visible: root.video && audio.currentValue !== "" && audio.currentIndex > 0
        wrapMode: Text.WordWrap
    }
    RowLayout {
        Layout.fillWidth: true
        visible: root.configuring && !root.video && root.service.preview !== ""

        Label {
            Layout.fillWidth: true
            text: root.editing ? "Annotate, crop, then copy or save." : "Your current screenshot is still available."
            color: Theme.colFgDim
            wrapMode: Text.WordWrap
        }
        Panels.PanelButton {
            visible: !root.editing && !root.service.recording
            text: "Back to editor"
            onClicked: root.configuring = false
        }
    }
    CaptureEditor {
        id: editor

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 240
        Layout.preferredHeight: editor.preferredHeight
        service: root.service
        visible: root.editing
    }
    Label {
        Accessible.name: text
        Accessible.role: Accessible.StaticText
        Layout.fillWidth: true
        text: root.service.hasResult ? "" : root.service.message
        visible: text !== ""
        wrapMode: Text.WrapAnywhere
    }
    Label {
        Layout.fillWidth: true
        color: Theme.colUrgent
        text: "Missing capture tools. Screen/area need slurp and grim; recording needs slurp and wf-recorder."
        visible: root.service.ready && (!root.service.tools.slurp || (!root.video && !root.service.tools.grim) || (root.video && !root.service.tools["wf-recorder"]))
        wrapMode: Text.WordWrap
    }
}
