import Quickshell
import Quickshell.Wayland
import "notifications" as Notifications
import ".."

PanelWindow {
    id: win

    required property var notifs

    anchors.bottom: true
    anchors.right: true
    margins.bottom: 18
    margins.right: 18
    implicitWidth: Math.min(Config.popupWidth, screen ? screen.width - 36 : Config.popupWidth)
    implicitHeight: popups.implicitHeight
    exclusiveZone: 0
    color: "transparent"
    visible: notifs.popups.length > 0 && !notifs.controlCenterVisible
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifs"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    Notifications.Popups {
        id: popups
        anchors.fill: parent
        notifs: win.notifs
        visible: win.visible
    }
}
