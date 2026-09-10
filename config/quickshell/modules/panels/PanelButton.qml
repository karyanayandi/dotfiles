import "../.."
import QtQuick
import QtQuick.Controls
import "../../components" as Components

Button {
    id: root

    property string glyph: ""
    property string tone: "neutral"
    readonly property bool emphasized: checked || tone !== "neutral"

    implicitHeight: 40
    implicitWidth: Math.max(40, contentItem.implicitWidth + leftPadding + rightPadding)
    leftPadding: 12
    rightPadding: 12
    hoverEnabled: true
    opacity: !enabled ? 0.5 : down ? 0.85 : 1
    font.family: Theme.fontUi
    font.pixelSize: 14
    palette.toolTipBase: Theme.colBg
    palette.toolTipText: Theme.colFg
    Accessible.name: text
    ToolTip.visible: hovered && text === "" && Accessible.name !== ""
    ToolTip.text: Accessible.name
    ToolTip.delay: 400

    background: Rectangle {
        radius: 12
        color: root.tone === "danger" ? Theme.colUrgent : root.emphasized ? Theme.colChipActive : root.down ? Theme.colActionBg : root.hovered ? Theme.colHoverAlpha : Theme.colBgAlt
        border.width: root.visualFocus ? 2 : 1
        border.color: root.visualFocus ? Theme.colFg : Theme.colBorder
    }

    contentItem: Components.IconLabel {
        icon: root.glyph
        text: root.text
        font: root.font
        color: root.emphasized ? Theme.colBg : root.enabled ? Theme.colFg : Theme.colFgDim
    }
}
