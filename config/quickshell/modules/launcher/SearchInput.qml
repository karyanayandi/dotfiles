import QtQuick
import QtQuick.Layouts
import "../.."

RowLayout {
    id: root
    property string mode: "all"
    signal queryChanged(string query)
    signal escapePressed()
    signal selectionMoved(string direction)
    signal selected(bool ctrl)

    function focusInput() { input.forceActiveFocus() }
    function clear() { input.text = "" }

    Layout.fillWidth: true
    Layout.preferredHeight: Config.launcherInputHeight
    Layout.leftMargin: 16
    Layout.rightMargin: 16
    spacing: 12

    Text {
        text: "\u{f0349}"
        color: Theme.colMuted
        font.family: Theme.fontFamily
        font.pixelSize: 18
        Layout.alignment: Qt.AlignVCenter
    }

    TextInput {
        id: input
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        color: Theme.colFg
        selectionColor: Theme.colSelected
        selectedTextColor: Theme.colBg
        font.family: Theme.fontFamily
        font.pixelSize: 17
        font.weight: Font.Normal
        clip: true
        focus: true
        onTextChanged: root.queryChanged(text)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) root.escapePressed()
            else if (event.key === Qt.Key_Down) root.selectionMoved("down")
            else if (event.key === Qt.Key_Up) root.selectionMoved("up")
            else if ((event.key === Qt.Key_Left || event.key === Qt.Key_Right) && (root.mode === "emoji" || root.mode === "nerd" || root.mode === "wallpaper")) root.selectionMoved(event.key === Qt.Key_Left ? "left" : "right")
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.selected(!!(event.modifiers & Qt.ControlModifier))
            else return
            event.accepted = true
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !parent.text.length
            text: {
                if (root.mode === "clipboard") return "Search clipboard\u2026  (autopaste on Enter, copy on Ctrl+Enter)"
                if (root.mode === "emoji") return "Search emoji\u2026  (e.g. fire, heart)"
                if (root.mode === "nerd") return "Search Nerd Fonts\u2026"
                if (root.mode === "bluetooth") return "Bluetooth devices\u2026"
                if (root.mode === "power") return "Search power actions\u2026"
                if (root.mode === "wallpaper") return "Search wallpapers\u2026"
                return "Search apps, clipboard, emoji, wallpapers\u2026"
            }
            color: Theme.g19
            font.pixelSize: root.mode === "emoji" ? 18 : 15
        }
    }

    Text {
        visible: input.text.length > 0
        text: "\u2715"
        color: Theme.colMuted
        font.family: Theme.fontFamily
        font.pixelSize: 14
        Layout.alignment: Qt.AlignVCenter
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.clear()
                root.focusInput()
            }
        }
    }

    Text {
        visible: !input.text.length
        text: "esc"
        color: Qt.rgba(0x7c / 255, 0x6f / 255, 0x64 / 255, 0.9)
        font.family: Theme.fontFamily
        font.pixelSize: 10
        Layout.alignment: Qt.AlignVCenter
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 10
            height: parent.height + 6
            radius: 6
            color: Theme.colChipBg
            z: -1
            border.color: Theme.colBorder
            border.width: 1
        }
    }
}
