import QtQuick
import QtQuick.Controls
import "../.."

Item {
    id: root
    property var model: []
    property int selected: 0
    property string emptyText: "No results"
    readonly property bool valueGrid: root.model.length > 0 && (root.model[0].kind === "emoji" || root.model[0].kind === "nerd")
    readonly property int gridColumns: Math.max(1, Math.floor(grid.width / grid.cellWidth))
    signal selectionRequested(int index)
    signal activated(int index, bool ctrl)

    implicitHeight: 360

    ListView {
        id: list
        anchors.fill: parent
        visible: root.model.length > 0 && !root.valueGrid
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

    GridView {
        id: grid
        width: Math.floor(parent.width / cellWidth) * cellWidth
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        visible: root.valueGrid
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.model
        currentIndex: root.selected
        cellWidth: 64
        cellHeight: 56
        onCurrentIndexChanged: if (currentIndex >= 0 && root.valueGrid) positionViewAtIndex(currentIndex, GridView.Contain)
        delegate: Item {
            required property var modelData
            required property int index
            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 10
                color: index === root.selected ? Theme.colHoverAlpha : "transparent"
                border.color: index === root.selected ? Theme.colBorder : "transparent"
                border.width: 1
            }

            Text {
                anchors.fill: parent
                text: modelData.text || modelData.icon || ""
                color: Theme.colFg
                font.family: modelData.kind === "emoji" ? "Noto Color Emoji" : Theme.fontFamily
                font.pixelSize: modelData.kind === "emoji" ? 26 : 24
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.selectionRequested(index)
                onClicked: root.activated(index, !!(mouse.modifiers & Qt.ControlModifier))
            }
        }
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
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
