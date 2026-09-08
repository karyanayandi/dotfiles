import ".."
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var audio

    implicitWidth: 400
    implicitHeight: 76

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Text {
            text: root.audio.osdIcon
            color: root.audio.muted ? Theme.colMuted : Theme.colFg
            font.family: Theme.fontFamily
            font.pixelSize: 30
            Layout.preferredWidth: 36
            horizontalAlignment: Text.AlignHCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: root.audio.osdKind === "mic" ? (root.audio.muted ? "Microphone muted" : "Microphone") : (root.audio.muted ? "Muted" : "Volume")
                    color: Theme.colFg
                    font.family: Theme.fontUi
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: root.audio.osdPercent + "%"
                    color: Theme.colMuted
                    font.family: Theme.fontUi
                    font.pixelSize: 13
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 6
                radius: 3
                color: Theme.colMeterBg

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.audio.osdPercent / 100))
                    height: parent.height
                    radius: parent.radius
                    color: root.audio.muted ? Theme.colMuted : Theme.colMeterFg

                    Behavior on width {
                        NumberAnimation {
                            duration: Config.animFast
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}
