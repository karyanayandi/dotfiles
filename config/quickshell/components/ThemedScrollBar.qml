import ".."
import QtQuick
import QtQuick.Controls

ScrollBar {
    id: root

    policy: ScrollBar.AsNeeded
    visible: policy === ScrollBar.AlwaysOn || (policy === ScrollBar.AsNeeded && size < 1)
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : 0.5

    Keys.onPressed: event => {
        if ((orientation === Qt.Vertical && event.key === Qt.Key_Up) || (orientation === Qt.Horizontal && event.key === Qt.Key_Left)) {
            decrease();
            event.accepted = true;
        } else if ((orientation === Qt.Vertical && event.key === Qt.Key_Down) || (orientation === Qt.Horizontal && event.key === Qt.Key_Right)) {
            increase();
            event.accepted = true;
        }
    }

    contentItem: Rectangle {
        implicitWidth: root.orientation === Qt.Vertical ? 6 : 24
        implicitHeight: root.orientation === Qt.Vertical ? 24 : 6
        radius: 3
        color: root.pressed ? Theme.g7 : Theme.colMuted
        opacity: root.active || root.hovered || root.visualFocus ? 0.8 : 0.4
        border.width: root.visualFocus ? 2 : 0
        border.color: Theme.colFg
    }
}
