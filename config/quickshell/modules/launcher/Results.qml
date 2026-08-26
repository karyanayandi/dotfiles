import QtQuick
import QtQuick.Controls
import "../.."

Item {
    id: root
    property var model: []
    property int selected: 0
    property string emptyText: "No results"
    signal selectionRequested(int index)
    signal activated(int index, bool ctrl)

    implicitHeight: 360

    ListView {
        id: list
        anchors.fill: parent
        visible: root.model.length > 0
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.model
        currentIndex: root.selected
        highlightMoveDuration: 140
        highlightMoveVelocity: -1
        highlight: Rectangle {
            radius: 10
            color: Theme.colHoverAlpha
            border.color: Theme.colBorder
            border.width: 1
        }
        delegate: ResultItem {
            selectedIndex: root.selected
            onHovered: index => root.selectionRequested(index)
            onActivated: (index, ctrl) => root.activated(index, ctrl)
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.model.length === 0
        text: root.emptyText
        color: Theme.g19
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }
}
