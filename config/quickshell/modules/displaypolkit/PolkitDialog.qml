import "../.." as Shell
import QtQuick
import QtQuick.Controls.Basic
import "../panels" as Panels
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Polkit

Item {
    id: root

    readonly property bool active: !!agent && agent.isActive
    readonly property var agent: loader.item

    // Opt in only after stopping the existing agent for a supervised test.
    property bool agentEnabled: Quickshell.env("QS_POLKIT_AGENT") === "1"
    readonly property var flow: agent ? agent.flow : null
    readonly property bool opened: active && !!flow && !flow.isCompleted

    function cancel() {
        if (flow)
            flow.cancelAuthenticationRequest();
    }

    implicitHeight: form.implicitHeight + 48
    implicitWidth: 480
    visible: opened

    Keys.onEscapePressed: cancel()
    onOpenedChanged: {
        response.clear();
        if (opened)
            Qt.callLater(() => {
                return response.forceActiveFocus();
            });
    }

    Loader {
        id: loader

        active: root.agentEnabled

        sourceComponent: Component {
            PolkitAgent {
            }
        }
    }
    IpcHandler {
        function cancel() {
            root.cancel();
        }
        // No open/preview/password IPC. Only real authority requests create dialogs.

        function status(): string {
            return !root.agentEnabled ? "disabled" : root.agent && root.agent.isRegistered ? "registered" : "not registered";
        }

        target: "polkit"
    }
    Connections {
        function onFlowChanged() {
            response.clear();
        }

        target: root.agent
    }
    Connections {
        function onIsCompletedChanged() {
            response.clear();
        }
        function onIsResponseRequiredChanged() {
            response.clear();
            if (root.flow && root.flow.isResponseRequired)
                response.forceActiveFocus();
        }
        function onSelectedIdentityChanged() {
            response.clear();
        }

        target: root.flow
    }
    Pane {
        anchors.fill: parent
        font.family: Shell.Theme.fontUi
        padding: 24
        palette.base: Shell.Theme.colBgAlt
        palette.button: Shell.Theme.colBgAlt
        palette.buttonText: Shell.Theme.colFg
        palette.highlight: Shell.Theme.g6
        palette.highlightedText: Shell.Theme.g0
        palette.text: Shell.Theme.colFg
        palette.windowText: Shell.Theme.colFg

        background: Item {
        }

        Keys.onEscapePressed: root.cancel()

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
                        text: "\uf023"
                    }
                    Label {
                        Layout.fillWidth: true
                        font.bold: true
                        font.pixelSize: 22
                        text: "Authenticate"
                        wrapMode: Text.Wrap
                    }
                }
                Label {
                    Layout.fillWidth: true
                    text: root.flow ? root.flow.message : ""
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                }
                Label {
                    Layout.fillWidth: true
                    font.pixelSize: 12
                    text: root.flow ? root.flow.actionId : ""
                    textFormat: Text.PlainText
                    wrapMode: Text.WrapAnywhere
                }
                Panels.PanelComboBox {
                    Accessible.name: "Authentication identity"
                    Layout.fillWidth: true
                    currentIndex: root.flow ? root.flow.identities.indexOf(root.flow.selectedIdentity) : -1
                    leadingGlyph: "\uf007"
                    model: root.flow ? root.flow.identities : []
                    textRole: "displayName"

                    onActivated: {
                        if (root.flow)
                            root.flow.selectedIdentity = root.flow.identities[currentIndex];
                    }
                }
                Panels.PanelTextField {
                    id: response

                    function submitResponse() {
                        if (!root.flow || !root.flow.isResponseRequired)
                            return;

                        root.flow.submit(text);
                        clear();
                    }

                    Accessible.name: root.flow ? root.flow.inputPrompt : "Authentication response"
                    Layout.fillWidth: true
                    echoMode: root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
                    enabled: !!root.flow && root.flow.isResponseRequired
                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                    leadingGlyph: "\uf023"
                    objectName: "polkitResponse"
                    placeholderText: root.flow ? root.flow.inputPrompt : "Password"

                    onAccepted: submitResponse()
                }
                Label {
                    Layout.fillWidth: true
                    color: Shell.Theme.colUrgent
                    text: root.flow ? root.flow.supplementaryMessage : ""
                    textFormat: Text.PlainText
                    visible: text !== ""
                    wrapMode: Text.Wrap
                }
                RowLayout {
                    Panels.PanelButton {
                        glyph: "\uf00d"
                        text: "Cancel"

                        onClicked: root.cancel()
                    }
                    Panels.PanelButton {
                        enabled: response.enabled
                        glyph: "\uf023"
                        text: "Authenticate"

                        onClicked: response.submitResponse()
                    }
                }
            }
        }
    }
}
