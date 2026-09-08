import "../.."
import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var model: []
    property int selected: 0
    property string emptyText: "No results"
    readonly property bool wallpaperGrid: root.model.length > 0 && root.model[0].kind === "wallpaper"
    readonly property bool valueGrid: root.model.length > 0 && (root.model[0].kind === "emoji" || root.model[0].kind === "nerd" || root.wallpaperGrid)
    readonly property int gridColumns: Math.max(1, Math.floor(grid.width / grid.cellWidth))

    signal selectionRequested(int index)
    signal activated(int index, bool ctrl)

    implicitHeight: 360

    ListView {
        id: list

        anchors.fill: parent
        anchors.margins: 8
        spacing: 4
        visible: root.model.length > 0 && !root.valueGrid
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        // Keep JS objects out of Qt's QVariant delegate conversion path.
        model: root.valueGrid ? 0 : root.model.length
        currentIndex: root.selected
        highlightMoveDuration: 0
        highlightMoveVelocity: -1

        highlight: Rectangle {
            width: list.width
            radius: 10
            color: Theme.g1
            border.color: Theme.colBorder
            border.width: 1
        }

        delegate: ResultItem {
            modelData: root.model[index] || {}
            selectedIndex: root.selected
            onHovered: index => {
                return root.selectionRequested(index);
            }
            onActivated: (index, ctrl) => {
                return root.activated(index, ctrl);
            }
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
        model: root.valueGrid ? root.model.length : 0
        currentIndex: root.selected
        cellWidth: root.wallpaperGrid ? 160 : 64
        cellHeight: root.wallpaperGrid ? 108 : 56
        onCurrentIndexChanged: {
            if (currentIndex >= 0 && root.valueGrid) {
                positionViewAtIndex(currentIndex, GridView.Contain);
            }
        }

        delegate: Item {
            required property int index
            readonly property var modelData: root.model[index] || {}

            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 10
                color: index === root.selected ? Theme.colHoverAlpha : "transparent"
                border.color: index === root.selected ? Theme.g6 : Theme.colBorder
                border.width: index === root.selected ? 2 : 1
                clip: true

                Image {
                    anchors.fill: parent
                    visible: root.wallpaperGrid
                    source: visible ? "file://" + modelData.path : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                Rectangle {
                    visible: root.wallpaperGrid
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 28
                    color: Theme.colBgAlpha078

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        text: modelData.title || ""
                        color: Theme.colFg
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    visible: root.wallpaperGrid && index === root.selected
                    radius: parent.radius
                    color: "transparent"
                    border.color: Theme.g6
                    border.width: 3
                }
            }

            Text {
                anchors.fill: parent
                visible: !root.wallpaperGrid
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

        ScrollBar.vertical: ScrollBar {
            id: scrollBar
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 6
                implicitHeight: 24
                radius: 3
                color: scrollBar.pressed ? Theme.g7 : Theme.colMuted
                opacity: scrollBar.active ? 0.8 : 0.4
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.model.length === 0
        text: root.emptyText
        color: Theme.g19
        font.family: Theme.fontUi
        font.pixelSize: 14
    }
}
