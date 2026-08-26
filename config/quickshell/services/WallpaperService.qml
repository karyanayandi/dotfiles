import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    visible: false

    readonly property string folder: Quickshell.env("HOME") + "/.config/dotfiles/wallpapers"
    readonly property string storePath: Quickshell.env("HOME") + "/.cache/quickshell/wallpaper"
    property var wallpapers: []
    property string current: ""

    FileView { id: store; path: root.storePath; blockLoading: true }

    Component.onCompleted: {
        store.reload()
        root.current = (store.text() || "").trim()
        scan.running = true
    }

    function setWallpaper(path) {
        if (!path) return
        root.current = path
        store.setText(path)
        store.writeFile()
        rotation.restart()
    }

    function randomize() {
        if (!root.wallpapers.length) return
        const choices = root.wallpapers.filter(path => path !== root.current)
        root.setWallpaper((choices.length ? choices : root.wallpapers)[Math.floor(Math.random() * (choices.length || root.wallpapers.length))])
    }

    Process {
        id: scan
        command: ["sh", "-c", "find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -print | sort", "sh", root.folder]
        stdout: SplitParser {
            onRead: data => {
                const path = (data || "").trim()
                if (path) root.wallpapers = root.wallpapers.concat([path])
            }
        }
        onExited: {
            if (!root.wallpapers.includes(root.current)) root.randomize()
        }
    }

    Timer {
        id: rotation
        interval: 10800000
        running: root.wallpapers.length > 1
        repeat: true
        onTriggered: root.randomize()
    }
}
