import ".."
import "../components"
import QtQuick
import Quickshell
import Quickshell.Wayland

Variants {
    id: root

    required property var wallpaper

    model: Quickshell.screens

    PanelWindow {
        required property var modelData

        screen: modelData
        exclusiveZone: 0
        color: Theme.colBg
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell-wallpaper"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WallpaperImage {
            anchors.fill: parent
            source: root.wallpaper.current ? "file://" + root.wallpaper.current : ""
        }

    }

}
