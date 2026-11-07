import Quickshell
import Quickshell.Wayland
import "notifications" as Notifications
import ".."

PanelWindow {
    id: win

    required property var notifs

    anchors.top: true
    anchors.right: true
    margins.top: Config.barHeight + 12
    margins.right: 20
    implicitWidth: Math.max(0, Math.min(Config.popupWidth, screen ? screen.width - 40 : Config.popupWidth))
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
        maxHeight: Math.max(0, win.screen ? win.screen.height - win.margins.top - 20 : 500)
        visible: win.visible
    }
}
