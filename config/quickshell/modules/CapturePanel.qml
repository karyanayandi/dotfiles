pragma ComponentBehavior: Bound
import ".."
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "panels" as Panels
import "capture"

Item {
    id: root

    property string selectedMode: "area"
    required property var service
    property bool video: false
    property bool expanded: false
    property bool configuring: false
    property bool opened: false
    readonly property bool editing: !video && service.preview !== "" && !configuring
    readonly property bool recordingBusy: service.busy && service.action === "record"
    readonly property bool canCapture: Boolean(service.ready && !service.busy && (selectedMode === "window" ? service.windowSupported : service.tools.slurp && (video ? service.tools["wf-recorder"] : service.tools.grim)))

    implicitWidth: editing ? 960 : 360
    implicitHeight: layout.implicitHeight + 36
    visible: opened

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

    onVideoChanged: {
        if (video && selectedMode === "window")
            selectedMode = "area";
    }
    onOpenedChanged: {
        if (opened) {
            service.beginSession();
            Qt.callLater(() => {
                if (root.opened)
                    closeButton.forceActiveFocus();
            });
        }
    }

    Connections {
        target: root.service
        function onPreviewChanged() {
            if (root.service.preview !== "")
                root.configuring = false;
        }
    }

    component CaptureButton: Button {
        id: button

        hoverEnabled: true
        implicitWidth: 40
        implicitHeight: 36
        opacity: enabled ? 1 : 0.4
        font.family: Theme.fontFamily
        font.pixelSize: 16
        palette.buttonText: Theme.colFg
        ToolTip.visible: hovered && Accessible.name !== ""
        ToolTip.text: Accessible.name
        ToolTip.delay: 400

        background: Rectangle {
            radius: height / 2
            color: button.checked ? Theme.colChipActive : button.down ? Theme.colActionBg : button.hovered ? Theme.colHoverAlpha : "transparent"
            border.width: button.visualFocus ? 2 : 0
            border.color: Theme.colFg
        }
        contentItem: Text {
            text: button.text
            font: button.font
            color: button.checked ? Theme.colBg : Theme.colFg
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: 18
        spacing: 12
        Keys.onEscapePressed: root.opened = false

        RowLayout {
            Layout.fillWidth: true

            Label {
                Layout.fillWidth: true
                visible: root.editing
                text: "Screenshot"
                color: Theme.colFg
                font.family: Theme.fontUi
                font.pixelSize: 22
                font.bold: true
            }
            Item {
                Layout.fillWidth: true
                visible: !root.editing
            }
            CaptureButton {
                id: closeButton

                objectName: "captureClose"
                Accessible.name: "Close capture"
                text: "\uf00d"
                implicitWidth: 28
                implicitHeight: 28
                onClicked: root.opened = false
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: !root.editing && !root.service.recording

            Repeater {
                model: ["area", "screen", "window"]

                CaptureButton {
                    id: modeButton

                    required property string modelData
                    readonly property string label: modelData === "area" ? "Selection" : modelData === "screen" ? "Screen" : "Window"

                    objectName: "captureMode_" + modelData
                    Layout.fillWidth: true
                    implicitHeight: 88
                    autoExclusive: true
                    checkable: true
                    checked: root.selectedMode === modelData
                    enabled: !root.service.busy && (modelData !== "window" || (!root.video && root.service.windowSupported))
                    Accessible.name: label + " capture"
                    onClicked: root.selectedMode = modelData

                    background: Rectangle {
                        radius: 12
                        color: modeButton.checked ? Theme.colChipActive : modeButton.down ? Theme.colActionBg : modeButton.hovered ? Theme.colHoverAlpha : "transparent"
                        border.width: modeButton.visualFocus ? 2 : 0
                        border.color: Theme.colFg
                    }
                    contentItem: ColumnLayout {
                        spacing: 8
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modeButton.modelData === "area" ? "\uf125" : modeButton.modelData === "screen" ? "\uf108" : "\uf2d0"
                            font.family: Theme.fontFamily
                            font.pixelSize: 30
                            color: modeButton.checked ? Theme.colBg : Theme.colFg
                        }
                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: modeButton.label
                            font.family: Theme.fontUi
                            font.pixelSize: 13
                            color: modeButton.checked ? Theme.colBg : Theme.colFg
                        }
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            visible: !root.editing && root.service.recording
            text: "●  " + Math.floor(root.service.elapsed / 60) + ":" + String(root.service.elapsed % 60).padStart(2, "0")
            Accessible.name: "Recording, " + root.service.elapsed + " seconds"
            color: Theme.colUrgent
            font.family: Theme.fontUi
            font.pixelSize: 28
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.colBorder
            visible: !root.editing
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 64
            visible: !root.editing

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: switchRow.implicitWidth + 6
                height: 38
                radius: 19
                color: Theme.colInputBg

                RowLayout {
                    id: switchRow
                    anchors.centerIn: parent
                    spacing: 3

                    CaptureButton {
                        objectName: "capturePhoto"
                        Accessible.name: "Screenshot"
                        text: "\uf030"
                        autoExclusive: true
                        checkable: true
                        checked: !root.video
                        enabled: !root.service.busy
                        implicitHeight: 32
                        onClicked: root.video = false
                    }
                    CaptureButton {
                        objectName: "captureVideo"
                        Accessible.name: "Screen recording"
                        text: "\uf03d"
                        autoExclusive: true
                        checkable: true
                        checked: root.video
                        enabled: !root.service.busy
                        implicitHeight: 32
                        onClicked: root.video = true
                    }
                }
            }

            CaptureButton {
                id: shutter

                anchors.centerIn: parent
                implicitWidth: 64
                implicitHeight: 64
                objectName: root.editing ? "" : "captureStart"
                Accessible.name: root.video ? "Start recording" : "Take screenshot"
                enabled: root.canCapture
                visible: !root.recordingBusy
                onClicked: root.captureRequested(root.video ? "record" : "screenshot", {
                    "mode": root.selectedMode,
                    "audio": audio.currentValue || ""
                })

                background: Rectangle {
                    radius: width / 2
                    color: "transparent"
                    border.width: 4
                    border.color: shutter.visualFocus ? Theme.colChipActive : Theme.colFg
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 8
                        radius: width / 2
                        color: shutter.down ? Qt.darker(root.video ? Theme.colUrgent : Theme.colFg, 1.3) : shutter.hovered ? Qt.darker(root.video ? Theme.colUrgent : Theme.colFg, 1.1) : root.video ? Theme.colUrgent : Theme.colFg
                    }
                }
            }
            CaptureButton {
                id: stopButton

                anchors.centerIn: parent
                objectName: "captureStop"
                implicitWidth: 64
                implicitHeight: 64
                Accessible.name: root.service.recording ? "Stop recording" : "Cancel recording"
                visible: root.recordingBusy
                text: root.service.recording ? "\uf04d" : "\uf00d"
                background: Rectangle {
                    radius: width / 2
                    color: Theme.colUrgent
                    border.width: 4
                    border.color: stopButton.visualFocus ? Theme.colChipActive : Theme.colFg
                }
                onClicked: root.service.stop()
            }
        }

        Panels.PanelComboBox {
            id: audio

            objectName: "captureAudio"
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
            font.family: Theme.fontUi
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            text: root.service.recording ? "Close this panel to keep recording." : root.selectedMode === "screen" ? "Click a screen to capture." : root.selectedMode === "window" ? "Click a window to capture." : "Drag to select an area."
            visible: !root.editing
            wrapMode: Text.WordWrap
        }
        Panels.PanelButton {
            objectName: "captureBackToEditor"
            Layout.alignment: Qt.AlignHCenter
            visible: root.configuring && !root.video && root.service.preview !== ""
            text: "Back to editor"
            onClicked: root.configuring = false
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
            color: Theme.colFg
            text: root.service.hasResult ? "" : root.service.message
            visible: text !== ""
            wrapMode: Text.WrapAnywhere
        }
        Label {
            Layout.fillWidth: true
            color: Theme.colUrgent
            text: "Missing capture tools. Screen/area need slurp and grim; recording needs slurp and wf-recorder."
            visible: !root.editing && root.service.ready && (!root.service.tools.slurp || (!root.video && !root.service.tools.grim) || (root.video && !root.service.tools["wf-recorder"]))
            wrapMode: Text.WordWrap
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: root.editing

            Panels.PanelButton {
                text: ""
                glyph: root.expanded ? "\uf066" : "\uf065"
                Accessible.name: root.expanded ? "Use compact editor" : "Expand editor to screen"
                onClicked: root.expanded = !root.expanded
            }
            Panels.PanelButton {
                objectName: root.editing ? "captureStart" : ""
                Accessible.name: "Retake screenshot"
                text: ""
                glyph: "\uf030"
                enabled: root.canCapture
                onClicked: root.configuring = true
            }
            Item {
                Layout.fillWidth: true
            }
            Panels.PanelButton {
                objectName: "captureCopy"
                Accessible.name: "Copy image"
                enabled: Boolean(!root.service.busy && root.service.ready && root.service.tools["wl-copy"])
                glyph: "\uf0c5"
                implicitHeight: 48
                text: "Copy"
                tone: "primary"
                onClicked: root.service.request("copy-image")
            }
            Panels.PanelButton {
                objectName: "captureSave"
                Accessible.name: "Save PNG"
                enabled: !root.service.busy && root.service.ready
                glyph: "\uf0c7"
                implicitHeight: 48
                text: "Save PNG"
                onClicked: root.service.request("save")
            }
        }
    }
}
