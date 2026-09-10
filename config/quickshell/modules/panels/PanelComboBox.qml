pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../.."

ComboBox {
    id: root

    property string leadingGlyph: ""

    implicitHeight: 44
    implicitWidth: 180
    leftPadding: leadingGlyph ? 42 : 14
    rightPadding: 38
    hoverEnabled: true
    onVisibleChanged: if (!visible)
        popup.close()
    onEnabledChanged: if (!enabled)
        popup.close()
    font.family: Theme.fontUi
    font.pixelSize: 14
    palette.window: Theme.colBg
    palette.windowText: Theme.colFg
    palette.text: Theme.colFg
    palette.buttonText: Theme.colFg
    palette.button: Theme.colBgAlt
    palette.base: Theme.colBgAlt
    palette.highlight: Theme.colChipActive
    palette.highlightedText: Theme.colBg

    contentItem: Text {
        text: root.displayText
        font: root.font
        color: root.enabled ? Theme.colFg : Theme.colFgDim
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    Text {
        visible: root.leadingGlyph !== ""
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.leadingGlyph
        font.family: Theme.fontFamily
        font.pixelSize: 17
        color: Theme.colFgDim
    }
    indicator: Text {
        x: root.width - width - 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.popup.visible ? "\uf106" : "\uf107"
        font.family: Theme.fontFamily
        font.pixelSize: 17
        color: root.enabled ? Theme.colFg : Theme.colFgDim
    }
    background: Rectangle {
        radius: 12
        color: root.down ? Theme.colActionBg : root.hovered ? Theme.colBgAlt : Theme.colInputBg
        border.width: root.visualFocus ? 2 : 1
        border.color: root.visualFocus ? Theme.colChipActive : Theme.colBorder
    }
    delegate: ItemDelegate {
        id: option
        required property int index
        text: root.textAt(index)
        Accessible.name: text
        width: ListView.view.width
        implicitHeight: 40
        highlighted: root.highlightedIndex === index
        contentItem: RowLayout {
            spacing: 10
            Text {
                text: "\uf00c"
                opacity: option.index === root.currentIndex ? 1 : 0
                font.family: Theme.fontFamily
                color: option.highlighted ? Theme.colBg : Theme.colFg
            }
            Text {
                Layout.fillWidth: true
                text: option.text
                font: root.font
                color: option.highlighted ? Theme.colBg : Theme.colFg
                elide: Text.ElideRight
            }
        }
        background: Rectangle {
            radius: 8
            color: option.highlighted ? Theme.colChipActive : option.hovered ? Theme.colHoverAlpha : "transparent"
        }
    }
    popup: Popup {
        y: root.height + 6
        width: root.width
        padding: 6
        implicitHeight: Math.min(options.contentHeight + 12, 260)
        popupType: Popup.Item
        contentItem: ListView {
            id: options
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {
                contentItem: Rectangle {
                    implicitWidth: 3
                    radius: 2
                    color: Theme.colFgDim
                }
            }
        }
        background: Rectangle {
            radius: 14
            color: Theme.colBg
            border.width: 1
            border.color: Theme.colBorderStrong
        }
    }
}
