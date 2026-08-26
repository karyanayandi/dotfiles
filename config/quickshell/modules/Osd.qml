import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Window

PanelWindow {
    id: win
    required property var theme
    required property var audio

    property real _osdOpacity: audio.osdVisible ? 1 : 0
    Behavior on _osdOpacity {
        NumberAnimation {
            duration: win.audio.osdVisible ? 360 : 220
            easing.type: win.audio.osdVisible ? Easing.OutCubic : Easing.InCubic
        }
    }

    anchors.top: true
    margins.top: Math.round((Screen.height / 2) - 88)
    implicitWidth: 200
    implicitHeight: 176
    exclusiveZone: 0
    color: "transparent"
    visible: audio.osdVisible || _osdOpacity > 0.01
    mask: Region { item: cardWrap }

    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Item {
        id: cardWrap
        anchors.centerIn: parent
        width: 200
        height: 176
        opacity: win._osdOpacity
        scale: 0.86 + win._osdOpacity * 0.14
        transformOrigin: Item.Center
        Behavior on scale {
            NumberAnimation {
                duration: win.audio.osdVisible ? 420 : 200
                easing.type: win.audio.osdVisible ? Easing.OutBack : Easing.InCubic
                easing.overshoot: 1.12
            }
        }
        Behavior on opacity {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: card
            anchors.topMargin: 2
            radius: card.radius
            color: win.theme.colShadow
            z: -1
        }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: 18
            color: win.theme.colBgAlpha078
            border.color: win.theme.colBorder
            border.width: 1

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                radius: parent.radius
                color: win.theme.colBorderStrong
                opacity: 0.9
            }

            Column {
                anchors.centerIn: parent
                spacing: 0
                width: parent.width

                Text {
                    id: glyph
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: win.audio.osdIcon
                    color: win.theme.colFg
                    opacity: win.audio.muted && win.audio.osdKind === "sink" ? 0.55 : 1.0
                    font.family: win.theme.fontFamily
                    font.pixelSize: 56
                    font.weight: Font.Normal
                    horizontalAlignment: Text.AlignHCenter
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                Item { width: 1; height: 18 }

                Rectangle {
                    id: meter
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 144; height: 6; radius: 3
                    color: win.theme.colMeterBg
                    Rectangle {
                        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                        width: parent.width * Math.min(1, win.audio.osdPercent / 100)
                        radius: 3
                        color: win.audio.muted && win.audio.osdKind === "sink" ? win.theme.colMuted : win.theme.colMeterFg
                        Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    }
                }

                Item { width: 1; height: 10 }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        if (win.audio.osdKind === "mic") return win.audio.muted ? "Microphone muted" : "Microphone"
                        if (win.audio.muted) return "Muted"
                        return win.audio.osdPercent + "%"
                    }
                    color: win.theme.colMuted
                    font.family: win.theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    font.letterSpacing: 0.3
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
