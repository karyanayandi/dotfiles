import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "panels"

Panel {
    id: root

    title: "Audio mixer"
    icon: "\uf1de"
    ipcTarget: "audioMixer"

    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    Text {
        Layout.fillWidth: true
        visible: !Pipewire.ready
        text: "Connecting to audio…"
        color: Theme.colFgDim
        wrapMode: Text.WordWrap
    }

    Repeater {
        model: Pipewire.nodes

        delegate: ColumnLayout {
            id: row

            required property var modelData
            readonly property var node: modelData

            visible: !!node.audio
            Layout.fillWidth: true

            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: row.node.isStream ? "\uf009" : row.node.isSink ? "\uf028" : "\uf130"
                    color: Theme.colFgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    Accessible.ignored: true
                }

                Text {
                    Layout.fillWidth: true
                    text: row.node.description || row.node.name
                    color: Theme.colFg
                    font.family: Theme.fontUi
                    font.weight: Font.Medium
                    wrapMode: Text.WordWrap
                }

                PanelButton {
                    readonly property bool isDefault: row.node === (row.node.isSink ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource)

                    visible: !row.node.isStream
                    glyph: isDefault ? "\uf058" : "\uf10c"
                    checked: isDefault
                    enabled: row.node.ready
                    Accessible.name: (isDefault ? "Default device: " : "Use as default: ") + (row.node.description || row.node.name)
                    ToolTip.visible: hovered || visualFocus
                    ToolTip.text: isDefault ? "Default device" : "Use as default"
                    onClicked: {
                        if (row.node.isSink)
                            Pipewire.preferredDefaultAudioSink = row.node;
                        else
                            Pipewire.preferredDefaultAudioSource = row.node;
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                PanelSlider {
                    Layout.fillWidth: true
                    enabled: row.node.ready && !!row.node.audio
                    value: row.node.audio ? row.node.audio.volume : 0
                    Accessible.name: "Volume for " + (row.node.description || row.node.name)
                    onMoved: {
                        if (row.node.audio) {
                            row.node.audio.volume = value;
                        }
                    }
                }

                Text {
                    text: Math.round((row.node.audio ? row.node.audio.volume : 0) * 100) + "%"
                    color: Theme.colFgDim
                    font.family: Theme.fontUi
                    Layout.minimumWidth: 40
                    horizontalAlignment: Text.AlignRight
                }

                PanelButton {
                    glyph: row.node.audio && row.node.audio.muted ? "\uf026" : "\uf028"
                    enabled: row.node.ready && !!row.node.audio
                    checked: !!row.node.audio && row.node.audio.muted
                    Accessible.name: (checked ? "Unmute " : "Mute ") + (row.node.description || row.node.name)
                    ToolTip.visible: hovered || visualFocus
                    ToolTip.text: checked ? "Unmute" : "Mute"
                    onClicked: row.node.audio.muted = !row.node.audio.muted
                }
            }
        }
    }

    Text {
        visible: Pipewire.ready && Pipewire.nodes.values.length === 0
        text: "No audio devices or streams"
        color: Theme.colFgDim
    }
}
