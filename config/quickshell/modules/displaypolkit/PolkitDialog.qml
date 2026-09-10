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

    // Opt in only after stopping the existing agent for a supervised test.
    property bool agentEnabled: Quickshell.env("QS_POLKIT_AGENT") === "1"
    readonly property var agent: loader.item
    readonly property var flow: agent ? agent.flow : null
    readonly property bool active: !!agent && agent.isActive
    readonly property bool opened: active && !!flow && !flow.isCompleted

    function cancel() {
        if (flow)
            flow.cancelAuthenticationRequest();
    }

    visible: opened
    implicitWidth: 480
    implicitHeight: Math.min(560, form.implicitHeight + 48)
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
            PolkitAgent {}
        }
    }

    IpcHandler {
        // No open/preview/password IPC. Only real authority requests create dialogs.

        function status(): string {
            return !root.agentEnabled ? "disabled" : root.agent && root.agent.isRegistered ? "registered" : "not registered";
        }

        function cancel() {
            root.cancel();
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
        function onIsResponseRequiredChanged() {
            response.clear();
            if (root.flow && root.flow.isResponseRequired)
                response.forceActiveFocus();
        }

        function onSelectedIdentityChanged() {
            response.clear();
        }

        function onIsCompletedChanged() {
            response.clear();
        }

        target: root.flow
    }

    Pane {
        anchors.fill: parent
        padding: 24
        font.family: Shell.Theme.fontUi
        palette.windowText: Shell.Theme.colFg
        palette.text: Shell.Theme.colFg
        palette.base: Shell.Theme.colBgAlt
        palette.button: Shell.Theme.colBgAlt
        palette.buttonText: Shell.Theme.colFg
        palette.highlight: Shell.Theme.g6
        palette.highlightedText: Shell.Theme.g0
        Keys.onEscapePressed: root.cancel()

        ScrollView {
            id: scroll
            anchors.fill: parent
            contentWidth: availableWidth

            ColumnLayout {
                id: form
                width: scroll.availableWidth
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Label {
                        text: "\uf023"
                        font.family: Shell.Theme.fontFamily
                        font.pixelSize: 22
                    }
                    Label {
                        text: "Authenticate"
                        font.pixelSize: 22
                        font.bold: true
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }
                }

                Label {
                    text: root.flow ? root.flow.message : ""
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                Label {
                    text: root.flow ? root.flow.actionId : ""
                    textFormat: Text.PlainText
                    wrapMode: Text.WrapAnywhere
                    Layout.fillWidth: true
                    font.pixelSize: 12
                }

                Panels.PanelComboBox {
                    leadingGlyph: "\uf007"
                    currentIndex: root.flow ? root.flow.identities.indexOf(root.flow.selectedIdentity) : -1
                    Layout.fillWidth: true
                    Accessible.name: "Authentication identity"
                    model: root.flow ? root.flow.identities : []
                    textRole: "displayName"
                    onActivated: {
                        if (root.flow)
                            root.flow.selectedIdentity = root.flow.identities[currentIndex];
                    }
                }

                Panels.PanelTextField {
                    id: response
                    leadingGlyph: "\uf023"
                    placeholderText: root.flow ? root.flow.inputPrompt : "Password"
                    objectName: "polkitResponse"

                    function submitResponse() {
                        if (!root.flow || !root.flow.isResponseRequired)
                            return;

                        root.flow.submit(text);
                        clear();
                    }

                    Layout.fillWidth: true
                    enabled: !!root.flow && root.flow.isResponseRequired
                    Accessible.name: root.flow ? root.flow.inputPrompt : "Authentication response"
                    echoMode: root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                    onAccepted: submitResponse()
                }

                Label {
                    text: root.flow ? root.flow.supplementaryMessage : ""
                    visible: text !== ""
                    color: Shell.Theme.colUrgent
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                RowLayout {
                    Panels.PanelButton {
                        text: "Cancel"
                        glyph: "\uf00d"
                        onClicked: root.cancel()
                    }

                    Panels.PanelButton {
                        text: "Authenticate"
                        glyph: "\uf023"
                        enabled: response.enabled
                        onClicked: response.submitResponse()
                    }
                }
            }
        }

        background: Item {}
    }
}
