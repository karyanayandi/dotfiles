import "../.." as Shell
import QtQuick
import QtQuick.Controls.Basic
import "../panels" as Panels
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root

    property bool opened: false
    property var outputs: []
    property var trial: ({
            "pending": false,
            "message": "Ready"
        })
    property string error: ""
    property int remaining: 0
    readonly property string helper: Qt.resolvedUrl("../../scripts/display-settings.py").toString().replace("file://", "")
    // Island owns visibility arbitration and keyboard exclusivity.
    property bool blocked: false

    function refresh() {
        if (!listing.running)
            listing.running = true;
    }

    function run(action) {
        if (command.running)
            return;

        error = "";
        command.command = ["python3", helper, action];
        command.running = true;
    }

    function selectOutput() {
        const m = outputs[output.currentIndex];
        if (!m)
            return;

        mode.model = Array.from(new Set(m.availableModes.map(v => {
            return v.replace("Hz", "");
        })));
        mode.currentIndex = Math.max(0, mode.model.findIndex(v => {
            return v.startsWith(m.width + "x" + m.height + "@") && Math.abs(Number(v.split("@")[1]) - m.refreshRate) < 0.02;
        }));
        scale.text = String(m.scale);
        positionX.text = String(m.x);
        positionY.text = String(m.y);
        rotation.currentIndex = m.transform;
    }

    visible: opened
    implicitWidth: 520
    implicitHeight: Math.min(640, form.implicitHeight + 48)
    enabled: !blocked
    Keys.onEscapePressed: opened = false
    onOpenedChanged: {
        if (opened) {
            refresh();
            Qt.callLater(() => {
                if (root.enabled && root.opened)
                    output.forceActiveFocus();
            });
        }
    }

    Process {
        id: listing

        command: ["python3", root.helper, "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const data = JSON.parse(text);
                if (data.error) {
                    root.error = data.error;
                } else {
                    root.outputs = data.filter(m => {
                        return !m.disabled;
                    });
                    root.selectOutput();
                }
            }
        }
    }

    Process {
        id: command

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.error = JSON.parse(text).error || "";
            }
        }
    }

    Process {
        id: status

        command: ["python3", root.helper, "status"]

        stdout: StdioCollector {
            onStreamFinished: {
                const wasPending = root.trial.pending;
                root.trial = JSON.parse(text);
                root.remaining = Math.max(0, Math.ceil((root.trial.deadline || 0) - Date.now() / 1000));
                if (wasPending && !root.trial.pending)
                    root.refresh();
            }
        }
    }

    Timer {
        interval: 500
        running: root.opened
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!status.running) {
                status.running = true;
            }
        }
    }
    Pane {
        anchors.fill: parent
        padding: 24
        font.family: Shell.Theme.fontUi
        palette.windowText: Shell.Theme.colFg
        palette.text: Shell.Theme.colFg
        background: Item {}

        ScrollView {
            id: scroll
            anchors.fill: parent
            contentWidth: availableWidth
            clip: true

            ColumnLayout {
                id: form
                width: scroll.availableWidth
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Label {
                        text: "\uf108"
                        font.family: Shell.Theme.fontFamily
                        font.pixelSize: 22
                    }
                    Label {
                        text: "Displays"
                        font.pixelSize: 22
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Panels.PanelButton {
                        glyph: "\uf021"
                        Accessible.name: "Refresh displays"
                        enabled: !root.trial.pending
                        onClicked: root.refresh()
                    }
                    Panels.PanelButton {
                        glyph: "\uf00d"
                        Accessible.name: "Close displays"
                        onClicked: root.opened = false
                    }
                }

                Panels.PanelComboBox {
                    id: output
                    leadingGlyph: "\uf108"
                    Layout.fillWidth: true
                    model: root.outputs.map(m => m.name)
                    Accessible.name: "Display"
                    enabled: !root.trial.pending
                    onActivated: root.selectOutput()
                }

                ColumnLayout {
                    enabled: !root.trial.pending && !command.running && root.outputs.length > 0
                    Layout.fillWidth: true
                    spacing: 12

                    Label {
                        text: "Resolution"
                        color: Shell.Theme.colFgDim
                        font.pixelSize: 12
                    }
                    Panels.PanelComboBox {
                        id: mode
                        leadingGlyph: "\uf065"
                        Layout.fillWidth: true
                        Accessible.name: "Resolution and refresh rate"
                        displayText: currentText ? currentText.replace("@", " · ") + " Hz" : "Select resolution"
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            Label {
                                text: "Scale"
                                color: Shell.Theme.colFgDim
                                font.pixelSize: 12
                            }
                            Panels.PanelTextField {
                                id: scale
                                leadingGlyph: "\uf00e"
                                Layout.fillWidth: true
                                Accessible.name: "Display scale"
                                validator: DoubleValidator {
                                    bottom: 0.5
                                    top: 4
                                    locale: "C"
                                }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            Label {
                                text: "Rotation"
                                color: Shell.Theme.colFgDim
                                font.pixelSize: 12
                            }
                            Panels.PanelComboBox {
                                id: rotation
                                leadingGlyph: "\uf01e"
                                Layout.fillWidth: true
                                Accessible.name: "Display rotation"
                                model: ["Normal", "90°", "180°", "270°", "Flipped", "Flipped 90°", "Flipped 180°", "Flipped 270°"]
                            }
                        }
                    }
                    Label {
                        text: "Position"
                        color: Shell.Theme.colFgDim
                        font.pixelSize: 12
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Panels.PanelTextField {
                            id: positionX
                            leadingGlyph: "\uf07e"
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            placeholderText: "X"
                            Accessible.name: "Horizontal position in pixels"
                            validator: IntValidator {
                                bottom: -99999
                                top: 99999
                            }
                        }
                        Panels.PanelTextField {
                            id: positionY
                            leadingGlyph: "\uf07d"
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            placeholderText: "Y"
                            Accessible.name: "Vertical position in pixels"
                            validator: IntValidator {
                                bottom: -99999
                                top: 99999
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Panels.PanelButton {
                            glyph: "\uf06e"
                            text: "Preview"
                            enabled: scale.acceptableInput && positionX.acceptableInput && positionY.acceptableInput
                            onClicked: {
                                root.error = "";
                                command.command = ["python3", root.helper, "apply", JSON.stringify({
                                        output: output.currentText,
                                        mode: mode.currentText,
                                        scale: scale.text,
                                        position: positionX.text + "x" + positionY.text,
                                        transform: rotation.currentIndex
                                    })];
                                command.running = true;
                            }
                        }
                        Label {
                            text: "Reverts after 20 seconds"
                            color: Shell.Theme.colFgDim
                            font.pixelSize: 12
                        }
                    }
                }
                Label {
                    visible: text !== ""
                    text: root.error || (root.trial.pending ? "Reverting in " + root.remaining + "s" : root.trial.message === "Ready" ? "" : root.trial.message)
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    color: root.error ? Shell.Theme.colUrgent : Shell.Theme.colFg
                }
                RowLayout {
                    visible: root.trial.pending
                    Panels.PanelButton {
                        glyph: "\uf00c"
                        text: "Keep"
                        onClicked: root.run("keep")
                    }
                    Panels.PanelButton {
                        glyph: "\uf0c7"
                        text: "Save"
                        Accessible.name: "Keep and save layout for next session"
                        onClicked: root.run("save")
                    }
                    Panels.PanelButton {
                        glyph: "\uf0e2"
                        text: "Revert"
                        onClicked: root.run("revert")
                    }
                }
            }
        }
    }
}
