import QtQuick

Rectangle {
    id: root
    property alias shadowColor: shadow.color
    property bool showShadow: true
    property bool showTopHighlight: false

    radius: Config.barRadius
    color: Theme.colBgAlpha095
    border.color: Theme.colBorder
    border.width: 1

    Rectangle {
        visible: root.showShadow
        anchors.fill: parent
        anchors.topMargin: 2
        radius: parent.radius
        color: Theme.colShadow
        z: -1
    }
    Rectangle {
        visible: root.showTopHighlight
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        radius: parent.radius
        color: Theme.colBorderStrong
        opacity: 0.9
    }

    Rectangle { id: shadow; visible: false }
}
