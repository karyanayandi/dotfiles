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
    implicitWidth: Math.min(screen ? screen.width - 48 : 1200, panel.editing ? (panel.expanded ? (screen ? screen.width - 48 : 1200) : 960) : 600)
    implicitHeight: panel.editing ? Math.min(screen ? screen.height - 48 : 800, panel.expanded ? (screen ? screen.height - 48 : 800) : 760) : Math.min(screen ? screen.height - 40 : 760, panel.implicitHeight)
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
            id: viewport

            anchors.fill: parent
            contentHeight: panel.editing ? height : panel.implicitHeight
            interactive: !panel.editing
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            CapturePanel {
                id: panel

                width: parent.width
                height: editing ? viewport.height : implicitHeight
                service: root.service
                onCaptureRequested: (action, options) => {
                    return root.captureRequested(action, options);
                }
            }
        }
    }
}
