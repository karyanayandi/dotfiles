import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "launcher" as LauncherParts

Item {
    id: win

    property bool visibleLauncher: false
    readonly property string mode: model.mode
    required property var wallpaper
    implicitWidth: Config.launcherWidth
    implicitHeight: 480

    function open(mode) {
        if (!enabled)
            return;
        const selectedMode = mode || "all";
        model.mode = selectedMode === "apps" ? "all" : selectedMode;
        model.pinnedMode = selectedMode !== "apps" && selectedMode !== "all";
        model.query = "";
        model.selected = 0;
        visibleLauncher = true;
        input.clear();
        Qt.callLater(() => {
            if (!win.enabled || !win.visibleLauncher)
                return;
            if (model.mode === "wallpaper") {
                const current = model.results.findIndex(item => {
                    return item.path === win.wallpaper.current;
                });
                if (current >= 0)
                    model.selected = current;
            }
            input.focusInput();
        });
    }

    visible: visibleLauncher
    onVisibleLauncherChanged: {
        if (visibleLauncher) {
            Qt.callLater(() => {
                if (win.enabled && win.visibleLauncher)
                    input.focusInput();
            });
            model.refreshApps();
            if (model.mode === "bluetooth")
                model.refreshBluetooth();
        }
    }

    IpcHandler {
        function toggle(arg: string) {
            if (win.visibleLauncher)
                win.visibleLauncher = false;
            else
                win.open(arg || "all");
        }

        function open(arg: string) {
            win.open(arg);
        }

        function close() {
            win.visibleLauncher = false;
        }

        target: "launcher"
    }

    LauncherParts.LauncherModel {
        id: model

        wallpaper: win.wallpaper
        onCloseRequested: win.visibleLauncher = false
        onSourceOpened: {
            input.clear();
            input.focusInput();
        }
    }

    Item {
        id: cardWrap

        anchors.fill: parent

        Rectangle {
            id: card

            anchors.fill: parent
            color: "transparent"

            ColumnLayout {
                id: column

                anchors.fill: parent
                spacing: 0

                LauncherParts.SearchInput {
                    id: input

                    mode: model.mode
                    onQueryChanged: query => {
                        model.query = query;
                        model.selected = 0;
                    }
                    onEscapePressed: {
                        if (model.mode !== "all" && !model.pinnedMode) {
                            model.mode = "all";
                            model.query = "";
                            model.selected = 0;
                            input.clear();
                        } else {
                            win.visibleLauncher = false;
                        }
                    }
                    onSelectionMoved: direction => {
                        const count = model.results.length;
                        const gridMode = model.mode === "emoji" || model.mode === "nerd" || model.mode === "wallpaper";
                        if (!gridMode) {
                            model.selected = Math.max(0, Math.min(model.selected + (direction === "up" ? -1 : 1), count - 1));
                            return;
                        }
                        const columns = results.gridColumns;
                        const selected = model.selected;
                        let next = selected;
                        if (direction === "left" && selected % columns > 0)
                            next--;
                        else if (direction === "right" && selected % columns < columns - 1 && selected + 1 < count)
                            next++;
                        else if (direction === "up" && selected >= columns)
                            next -= columns;
                        else if (direction === "down" && selected + columns < count)
                            next += columns;
                        model.selected = next;
                    }
                    onSelected: ctrl => {
                        return model.triggerSelected(ctrl);
                    }
                    onCycleWallpaperInterval: win.wallpaper.cycleInterval()
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.colBorder
                    opacity: 0.9
                }

                LauncherParts.Results {
                    id: results

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: model.results
                    selected: model.selected
                    emptyText: model.mode === "clipboard" ? "No clipboard history yet — copy something" : model.mode === "bluetooth" ? "No devices — press Scan" : "No results"
                    onSelectionRequested: index => {
                        return model.selected = index;
                    }
                    onActivated: (index, ctrl) => {
                        model.selected = index;
                        model.triggerSelected(ctrl);
                    }
                }

                LauncherParts.Footer {
                    id: footer
                    mode: model.mode
                    bluetooth: model.bluetooth
                    clipboard: model.clipboard
                    wallpaper: win.wallpaper
                }
            }
        }
    }
}
