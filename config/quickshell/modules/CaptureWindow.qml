import ".."
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var service
    property bool blocked: false
    property alias opened: panel.opened
    property alias video: panel.video

    signal captureRequested(string action, var options)

    function open(mode) {
        panel.open(mode);
    }

    visible: opened && !blocked
    color: "transparent"
    implicitWidth: 640
    implicitHeight: Math.min(screen ? screen.height - 40 : 760, panel.implicitHeight)
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-capture"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    onBlockedChanged: {
        if (blocked)
            opened = false;
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.colBgAlpha095
        radius: 26
        border.color: Theme.colBorderStrong
        border.width: 1

        Flickable {
            anchors.fill: parent
            contentHeight: panel.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            CapturePanel {
                id: panel

                width: parent.width
                height: implicitHeight
                service: root.service
                onCaptureRequested: (action, options) => {
                    return root.captureRequested(action, options);
                }
            }
        }
    }
}
