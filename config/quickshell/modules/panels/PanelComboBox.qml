pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../.."

ComboBox {
    id: root

    property string leadingGlyph: ""

    font.family: Theme.fontUi
    font.pixelSize: 14
    hoverEnabled: true
    implicitHeight: 44
    implicitWidth: 180
    leftPadding: leadingGlyph ? 42 : 14
    palette.base: Theme.colBgAlt
    palette.button: Theme.colBgAlt
    palette.buttonText: Theme.colFg
    palette.highlight: Theme.colChipActive
    palette.highlightedText: Theme.colBg
    palette.text: Theme.colFg
    palette.window: Theme.colBg
    palette.windowText: Theme.colFg
    rightPadding: 38

    background: Rectangle {
        border.color: root.visualFocus ? Theme.colChipActive : Theme.colBorder
        border.width: root.visualFocus ? 2 : 1
        color: root.down ? Theme.colActionBg : root.hovered ? Theme.colBgAlt : Theme.colInputBg
        radius: 12
    }
    contentItem: Text {
        color: root.enabled ? Theme.colFg : Theme.colFgDim
        elide: Text.ElideRight
        font: root.font
        text: root.displayText
        verticalAlignment: Text.AlignVCenter
    }
    delegate: ItemDelegate {
        id: option

        required property int index

        Accessible.name: text
        highlighted: root.highlightedIndex === index
        implicitHeight: 40
        text: root.textAt(index)
        width: ListView.view.width

        background: Rectangle {
            color: option.highlighted ? Theme.colChipActive : option.hovered ? Theme.colHoverAlpha : "transparent"
            radius: 8
        }
        contentItem: RowLayout {
            spacing: 10

            Text {
                color: option.highlighted ? Theme.colBg : Theme.colFg
                font.family: Theme.fontFamily
                opacity: option.index === root.currentIndex ? 1 : 0
                text: "\uf00c"
            }
            Text {
                Layout.fillWidth: true
                color: option.highlighted ? Theme.colBg : Theme.colFg
                elide: Text.ElideRight
                font: root.font
                text: option.text
            }
        }
    }
    indicator: Text {
        anchors.verticalCenter: parent.verticalCenter
        color: root.enabled ? Theme.colFg : Theme.colFgDim
        font.family: Theme.fontFamily
        font.pixelSize: 17
        text: root.popup.visible ? "\uf106" : "\uf107"
        x: root.width - width - 14
    }
    popup: Popup {
        implicitHeight: options.contentHeight + 12
        padding: 6
        popupType: Popup.Item
        width: root.width
        y: root.height + 6

        background: Rectangle {
            border.color: Theme.colBorderStrong
            border.width: 1
            color: Theme.colBg
            radius: 14
        }
        contentItem: ListView {
            id: options

            currentIndex: root.highlightedIndex
            implicitHeight: contentHeight
            interactive: false
            model: root.popup.visible ? root.delegateModel : null
        }
    }

    onEnabledChanged: if (!enabled)
        popup.close()
    onVisibleChanged: if (!visible)
        popup.close()

    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.colFgDim
        font.family: Theme.fontFamily
        font.pixelSize: 17
        text: root.leadingGlyph
        visible: root.leadingGlyph !== ""
        x: 14
    }
}
