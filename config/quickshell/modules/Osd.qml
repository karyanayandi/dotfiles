import ".."
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var audio
    readonly property bool sinkMuted: audio.osdKind !== "mic" && audio.osdIcon === "󰸈"

    implicitWidth: Config.osdWidth
    implicitHeight: Config.osdHeight

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        Rectangle {
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            radius: Theme.radiusCard
            color: Theme.colBgAlt

            Text {
                objectName: "osdIcon"
                anchors.centerIn: parent
                text: root.audio.osdIcon
                color: root.sinkMuted ? Theme.colMuted : Theme.colFg
                font.family: Theme.fontFamily
                font.pixelSize: 24
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 9

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    objectName: "osdLabel"
                    text: root.audio.osdKind === "mic" ? "Microphone" : root.sinkMuted ? "Muted" : "Volume"
                    color: Theme.colFg
                    font.family: Theme.fontUi
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    objectName: "osdPercent"
                    text: root.audio.osdPercent + "%"
                    color: Theme.colMuted
                    font.family: Theme.fontUi
                    font.pixelSize: 13
                }
            }

            Rectangle {
                objectName: "osdMeter"
                Layout.fillWidth: true
                implicitHeight: 8
                radius: height / 2
                color: Theme.colMeterBg

                Rectangle {
                    objectName: "osdFill"
                    width: parent.width * Math.max(0, Math.min(1, root.audio.osdPercent / 100))
                    height: parent.height
                    radius: parent.radius
                    color: root.sinkMuted ? Theme.colMuted : Theme.colMeterFg
                }
            }
        }
    }
}
