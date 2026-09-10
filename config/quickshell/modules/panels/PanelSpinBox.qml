import QtQuick
import QtQuick.Controls.Basic
import "../.."

SpinBox {
    id: root

    implicitWidth: 180
    implicitHeight: 44
    leftPadding: 14
    rightPadding: 82
    editable: true
    hoverEnabled: true
    wheelEnabled: false
    font.family: Theme.fontUi
    font.pixelSize: 14

    contentItem: TextInput {
        id: editor
        text: root.displayText
        font: root.font
        color: root.enabled ? Theme.colFg : Theme.colFgDim
        selectionColor: Theme.colChipActive
        selectedTextColor: Theme.colBg
        verticalAlignment: Text.AlignVCenter
        readOnly: !root.editable
        validator: root.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        selectByMouse: true
        clip: true
        onEditingFinished: {
            if (acceptableInput)
                root.value = root.valueFromText(text, root.locale);
            text = Qt.binding(() => root.displayText);
        }
    }

    down.indicator: Rectangle {
        x: root.width - 76
        y: 6
        width: 34
        height: root.height - 12
        radius: 8
        color: root.down.pressed ? Theme.colActionBg : root.down.hovered ? Theme.colHoverAlpha : "transparent"
        opacity: root.enabled && root.value > root.from ? 1 : 0.35
        Accessible.role: Accessible.Button
        Accessible.name: "Decrease " + root.Accessible.name
        Accessible.onPressAction: if (root.enabled)
            root.decrease()
        Text {
            anchors.centerIn: parent
            text: "\uf068"
            font.family: Theme.fontFamily
            font.pixelSize: 13
            color: Theme.colFg
        }
    }
    up.indicator: Rectangle {
        x: root.width - 38
        y: 6
        width: 34
        height: root.height - 12
        radius: 8
        color: root.up.pressed ? Theme.colActionBg : root.up.hovered ? Theme.colHoverAlpha : "transparent"
        opacity: root.enabled && root.value < root.to ? 1 : 0.35
        Accessible.role: Accessible.Button
        Accessible.name: "Increase " + root.Accessible.name
        Accessible.onPressAction: if (root.enabled)
            root.increase()
        Text {
            anchors.centerIn: parent
            text: "\uf067"
            font.family: Theme.fontFamily
            font.pixelSize: 13
            color: Theme.colFg
        }
    }
    background: Rectangle {
        radius: 12
        color: root.hovered ? Theme.colBgAlt : Theme.colInputBg
        border.width: root.activeFocus || editor.activeFocus ? 2 : 1
        border.color: root.activeFocus || editor.activeFocus ? Theme.colChipActive : Theme.colBorder
    }
}
