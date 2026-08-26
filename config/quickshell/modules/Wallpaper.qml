import Quickshell
import Quickshell.Wayland
import QtQuick

Variants {
    id: root
    required property var wallpaper
    model: Quickshell.screens

    PanelWindow {
        required property var modelData
        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "black"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell-wallpaper"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Image {
            anchors.fill: parent
            source: root.wallpaper.current ? "file://" + root.wallpaper.current : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }
    }
}
