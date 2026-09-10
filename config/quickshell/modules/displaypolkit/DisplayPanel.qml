import "../.." as Shell
import QtQuick
import QtQuick.Controls.Basic
import "../panels" as Panels
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root

    // Island owns visibility arbitration and keyboard exclusivity.
    property bool blocked: false
    property string error: ""
    readonly property string helper: Qt.resolvedUrl("../../scripts/display-settings.py").toString().replace("file://", "")
    property bool opened: false
    property var outputs: []
    property int remaining: 0
    property var trial: ({
            "pending": false,
            "message": "Ready"
        })

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

    enabled: !blocked
    implicitHeight: form.implicitHeight + 48
    implicitWidth: 520
    visible: opened

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
        repeat: true
        running: root.opened
        triggeredOnStart: true

        onTriggered: {
            if (!status.running) {
                status.running = true;
            }
        }
    }
    Pane {
        anchors.fill: parent
        font.family: Shell.Theme.fontUi
        padding: 24
        palette.text: Shell.Theme.colFg
        palette.windowText: Shell.Theme.colFg

        background: Item {
        }

        Pane {
            id: bodyPane

            anchors.fill: parent
            padding: 0

            background: Item {
            }

            ColumnLayout {
                id: form

                spacing: 16
                width: bodyPane.availableWidth

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Label {
                        font.family: Shell.Theme.fontFamily
                        font.pixelSize: 22
                        text: "\uf108"
                    }
                    Label {
                        Layout.fillWidth: true
                        font.bold: true
                        font.pixelSize: 22
                        text: "Displays"
                    }
                    Panels.PanelButton {
                        Accessible.name: "Refresh displays"
                        enabled: !root.trial.pending
                        glyph: "\uf021"

                        onClicked: root.refresh()
                    }
                    Panels.PanelButton {
                        Accessible.name: "Close displays"
                        glyph: "\uf00d"

                        onClicked: root.opened = false
                    }
                }
                Panels.PanelComboBox {
                    id: output

                    Accessible.name: "Display"
                    Layout.fillWidth: true
                    enabled: !root.trial.pending
                    leadingGlyph: "\uf108"
                    model: root.outputs.map(m => m.name)

                    onActivated: root.selectOutput()
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    enabled: !root.trial.pending && !command.running && root.outputs.length > 0
                    spacing: 12

                    Label {
                        color: Shell.Theme.colFgDim
                        font.pixelSize: 12
                        text: "Resolution"
                    }
                    Panels.PanelComboBox {
                        id: mode

                        Accessible.name: "Resolution and refresh rate"
                        Layout.fillWidth: true
                        displayText: currentText ? currentText.replace("@", " · ") + " Hz" : "Select resolution"
                        leadingGlyph: "\uf065"
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0

                            Label {
                                color: Shell.Theme.colFgDim
                                font.pixelSize: 12
                                text: "Scale"
                            }
                            Panels.PanelTextField {
                                id: scale

                                Accessible.name: "Display scale"
                                Layout.fillWidth: true
                                leadingGlyph: "\uf00e"

                                validator: DoubleValidator {
                                    bottom: 0.5
                                    locale: "C"
                                    top: 4
                                }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0

                            Label {
                                color: Shell.Theme.colFgDim
                                font.pixelSize: 12
                                text: "Rotation"
                            }
                            Panels.PanelComboBox {
                                id: rotation

                                Accessible.name: "Display rotation"
                                Layout.fillWidth: true
                                leadingGlyph: "\uf01e"
                                model: ["Normal", "90°", "180°", "270°", "Flipped", "Flipped 90°", "Flipped 180°", "Flipped 270°"]
                            }
                        }
                    }
                    Label {
                        color: Shell.Theme.colFgDim
                        font.pixelSize: 12
                        text: "Position"
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Panels.PanelTextField {
                            id: positionX

                            Accessible.name: "Horizontal position in pixels"
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            leadingGlyph: "\uf07e"
                            placeholderText: "X"

                            validator: IntValidator {
                                bottom: -99999
                                top: 99999
                            }
                        }
                        Panels.PanelTextField {
                            id: positionY

                            Accessible.name: "Vertical position in pixels"
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            leadingGlyph: "\uf07d"
                            placeholderText: "Y"

                            validator: IntValidator {
                                bottom: -99999
                                top: 99999
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true

                        Panels.PanelButton {
                            enabled: scale.acceptableInput && positionX.acceptableInput && positionY.acceptableInput
                            glyph: "\uf06e"
                            text: "Preview"

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
                            color: Shell.Theme.colFgDim
                            font.pixelSize: 12
                            text: "Reverts after 20 seconds"
                        }
                    }
                }
                Label {
                    Layout.fillWidth: true
                    color: root.error ? Shell.Theme.colUrgent : Shell.Theme.colFg
                    text: root.error || (root.trial.pending ? "Reverting in " + root.remaining + "s" : root.trial.message === "Ready" ? "" : root.trial.message)
                    textFormat: Text.PlainText
                    visible: text !== ""
                    wrapMode: Text.Wrap
                }
                RowLayout {
                    visible: root.trial.pending

                    Panels.PanelButton {
                        glyph: "\uf00c"
                        text: "Keep"

                        onClicked: root.run("keep")
                    }
                    Panels.PanelButton {
                        Accessible.name: "Keep and save layout for next session"
                        glyph: "\uf0c7"
                        text: "Save"

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
