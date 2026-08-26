import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "launcher" as LauncherParts
import ".."

PanelWindow {
    id: win
    property bool visibleLauncher: false
    required property var wallpaper

    function open(mode) {
        const selectedMode = mode || "all"
        model.mode = selectedMode === "apps" ? "all" : selectedMode
        model.pinnedMode = selectedMode !== "apps" && selectedMode !== "all"
        model.query = ""
        model.selected = 0
        visibleLauncher = true
        input.clear()
        Qt.callLater(() => input.focusInput())
    }

    IpcHandler {
        target: "launcher"
        function toggle(arg: string) {
            if (win.visibleLauncher) win.visibleLauncher = false
            else win.open(arg || "all")
        }
        function open(arg: string) { win.open(arg) }
        function close() { win.visibleLauncher = false }
    }

    LauncherParts.LauncherModel {
        id: model
        wallpaper: win.wallpaper
        onCloseRequested: win.visibleLauncher = false
        onSourceOpened: {
            input.clear()
            input.focusInput()
        }
    }

    visible: visibleLauncher || _opacity > 0.01
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: visibleLauncher ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: cardWrap }

    property real _opacity: visibleLauncher ? 1 : 0
    Behavior on _opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0x1d / 255, 0x20 / 255, 0x21 / 255, visibleLauncher ? 0.34 : 0)
        opacity: win._opacity
        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
        MouseArea {
            anchors.fill: parent
            enabled: win.visibleLauncher
            onClicked: win.visibleLauncher = false
        }
    }

    Item {
        id: cardWrap
        width: Math.min(Config.launcherWidth, parent.width - 48)
        scale: 0.96 + win._opacity * 0.04
        opacity: win._opacity
        implicitHeight: card.implicitHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Rectangle {
            id: card
            width: parent.width
            implicitHeight: column.implicitHeight + 2
            radius: Config.launcherRadius
            color: Theme.colLauncherBg
            border.color: Theme.colLauncherBorder
            border.width: 1

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 6
                radius: parent.radius
                color: Theme.colShadow
                opacity: 0.55
                z: -1
            }

            ColumnLayout {
                id: column
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 0

                LauncherParts.SearchInput {
                    id: input
                    mode: model.mode
                    onQueryChanged: query => {
                        model.query = query
                        model.selected = 0
                    }
                    onEscapePressed: {
                        if (model.mode !== "all" && !model.pinnedMode) {
                            model.mode = "all"
                            model.query = ""
                            model.selected = 0
                            input.clear()
                        } else {
                            win.visibleLauncher = false
                        }
                    }
                    onSelectionMoved: direction => {
                        const count = model.results.length
                        const gridMode = model.mode === "emoji" || model.mode === "nerd" || model.mode === "wallpaper"
                        if (!gridMode) {
                            model.selected = Math.max(0, Math.min(model.selected + (direction === "up" ? -1 : 1), count - 1))
                            return
                        }

                        const columns = results.gridColumns
                        const selected = model.selected
                        let next = selected
                        if (direction === "left" && selected % columns > 0) next--
                        else if (direction === "right" && selected % columns < columns - 1 && selected + 1 < count) next++
                        else if (direction === "up" && selected >= columns) next -= columns
                        else if (direction === "down" && selected + columns < count) next += columns
                        model.selected = next
                    }
                    onSelected: ctrl => model.triggerSelected(ctrl)
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.colBorder; opacity: 0.9 }

                LauncherParts.Results {
                    id: results
                    Layout.fillWidth: true
                    Layout.preferredHeight: 360
                    model: model.results
                    selected: model.selected
                    emptyText: model.mode === "clipboard" ? "No clipboard history yet — copy something" : model.mode === "bluetooth" ? "No devices — press Scan" : "No results"
                    onSelectionRequested: index => model.selected = index
                    onActivated: (index, ctrl) => {
                        model.selected = index
                        model.triggerSelected(ctrl)
                    }
                }

                LauncherParts.Footer {
                    mode: model.mode
                    bluetooth: model.bluetooth
                    clipboard: model.clipboard
                }
            }
        }
    }

    onVisibleLauncherChanged: if (visibleLauncher) {
        Qt.callLater(() => input.focusInput())
        model.refreshApps()
        if (model.mode === "bluetooth") model.refreshBluetooth()
    }
}
