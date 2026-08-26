import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: win
    required property var theme
    required property var audio

    visible: audio.osdVisible
    anchors.top: true
    margins.top: 80
    implicitWidth: 380
    implicitHeight: 56
    exclusiveZone: 0
    color: "transparent"
    mask: Region { item: osdBg }
    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.layer: WlrLayer.Overlay

    Rectangle {
        id: osdBg
        anchors.centerIn: parent
        width: 360; height: 44; radius: 10
        color: win.theme.colBg
        border.color: win.theme.colAccent; border.width: 1
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 12
            Text { text: win.audio.osdIcon; color: win.theme.colFg; font.family: win.theme.fontFamily; font.pixelSize: 18; Layout.alignment: Qt.AlignVCenter }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 8; Layout.alignment: Qt.AlignVCenter; radius: 4; color: win.theme.colAccent
                Rectangle {
                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                    width: parent.width * Math.min(1, win.audio.osdPercent / 100)
                    radius: 4; color: win.audio.muted && win.audio.osdKind === "sink" ? win.theme.colUrgent : win.theme.colFg
                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }
            }
            Text {
                text: win.audio.osdKind === "mic" ? (win.audio.muted ? "muted" : "mic") : (win.audio.muted ? "muted" : win.audio.osdPercent + "%")
                color: win.theme.colFg; font.family: win.theme.fontFamily; font.pixelSize: 13
                Layout.alignment: Qt.AlignVCenter; Layout.preferredWidth: 52; horizontalAlignment: Text.AlignRight
            }
        }
    }
}
