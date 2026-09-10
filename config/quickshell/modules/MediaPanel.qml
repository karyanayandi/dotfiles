pragma ComponentBehavior: Bound
import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "panels"

Panel {
    id: root

    title: "Media"
    icon: "\uf001"
    ipcTarget: "mediaPanel"

    Text {
        visible: Mpris.players.values.length === 0
        text: "No media playing"
        color: Theme.colFgDim
    }

    Repeater {
        model: Mpris.players

        delegate: ColumnLayout {
            id: row

            required property var modelData
            readonly property var player: modelData

            Layout.fillWidth: true
            spacing: 8

            Image {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                visible: status === Image.Ready
                source: row.player.trackArtUrl
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 480
                sourceSize.height: 360
            }

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: row.player.identity
                color: Theme.colFgDim
                font.family: Theme.fontUi
            }

            Text {
                Layout.fillWidth: true
                text: row.player.trackTitle || "Untitled track"
                color: Theme.colFg
                font.family: Theme.fontUi
                font.pixelSize: 20
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                font.family: Theme.fontUi
                text: [row.player.trackArtist, row.player.trackAlbum].filter(Boolean).join(" · ")
                color: Theme.colFgDim
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12
                PanelButton {
                    Accessible.name: "Previous"
                    ToolTip.visible: hovered || visualFocus
                    ToolTip.text: Accessible.name
                    glyph: "\uf048"
                    enabled: row.player.canControl && row.player.canGoPrevious
                    onClicked: row.player.previous()
                }

                PanelButton {
                    Accessible.name: row.player.playbackState === MprisPlaybackState.Playing ? "Pause" : "Play"
                    ToolTip.visible: hovered || visualFocus
                    ToolTip.text: Accessible.name
                    Layout.preferredWidth: 56
                    implicitHeight: 48
                    glyph: row.player.playbackState === MprisPlaybackState.Playing ? "\uf04c" : "\uf04b"
                    enabled: row.player.canControl && row.player.canTogglePlaying
                    onClicked: row.player.togglePlaying()
                }

                PanelButton {
                    Accessible.name: "Next"
                    ToolTip.visible: hovered || visualFocus
                    ToolTip.text: Accessible.name
                    glyph: "\uf051"
                    enabled: row.player.canControl && row.player.canGoNext
                    onClicked: row.player.next()
                }
            }

            Timer {
                interval: 1000
                running: root.opened && row.player.positionSupported && row.player.playbackState === MprisPlaybackState.Playing
                repeat: true
                triggeredOnStart: true
                // MPRIS extrapolates position in its getter; it does not notify every second.
                onTriggered: row.player.positionChanged()
            }

            PanelSlider {
                id: seek
                Layout.fillWidth: true
                visible: row.player.lengthSupported && row.player.positionSupported
                enabled: row.player.canControl && row.player.canSeek && row.player.length > 0
                to: Math.max(1, row.player.length)
                stepSize: 5
                Binding {
                    target: seek
                    property: "value"
                    value: row.player.position
                    when: !seek.pressed
                }
                Accessible.name: "Playback position for " + row.player.identity
                onMoved: row.player.position = value
            }
        }
    }
}
