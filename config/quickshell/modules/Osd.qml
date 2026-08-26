import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: win
    required property var theme
    required property var audio

    property real _osdOpacity: audio.osdVisible ? 1 : 0
    Behavior on _osdOpacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
    visible: audio.osdVisible || _osdOpacity > 0.01
    anchors.top: true
    margins.top: 80
    implicitWidth: 380
    implicitHeight: 56
    exclusiveZone: 0
    color: "transparent"
    mask: Region { item: osdWrap }
    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.layer: WlrLayer.Overlay

    Item {
        id: osdWrap
        anchors.centerIn: parent
        width: 360; height: 44
        opacity: win._osdOpacity
        scale: 0.96 + win._osdOpacity * 0.04
        transformOrigin: Item.Center
        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    Rectangle {
        id: osdBg
        anchors.fill: parent
        radius: 10
        color: win.theme.colBgAlpha095
        border.color: Qt.rgba(1,1,1,0.10); border.width: 1
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
}
