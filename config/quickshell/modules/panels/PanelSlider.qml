import "../.."
import QtQuick
import QtQuick.Controls

Slider {
    id: root

    implicitHeight: 40
    stepSize: 0.01

    background: Rectangle {
        x: root.leftPadding
        y: (root.height - height) / 2
        width: root.availableWidth
        height: 6
        radius: 3
        color: Theme.g2

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: 3
            color: Theme.colFg
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: (root.height - height) / 2
        width: 20
        height: 20
        radius: 10
        color: Theme.colFg
        border.width: root.visualFocus ? 3 : 0
        border.color: Theme.g10
    }
}
