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
    property int rotationInterval: 10800000
    readonly property var intervalOptions: [0, 1800000, 3600000, 10800000, 21600000, 43200000]
    readonly property string rotationLabel: {
        if (root.rotationInterval === 0) return "Off"
        if (root.rotationInterval < 3600000) return root.rotationInterval / 60000 + "m"
        return root.rotationInterval / 3600000 + "h"
    }

    FileView { id: store; path: root.storePath; blockLoading: true }

    Component.onCompleted: {
        store.reload()
        const saved = (store.text() || "").trim()
        try {
            const state = JSON.parse(saved)
            root.current = state.wallpaper || ""
            if (root.intervalOptions.includes(state.interval)) root.rotationInterval = state.interval
        } catch (error) {
            root.current = saved
        }
        scan.running = true
    }

    function save() {
        store.setText(JSON.stringify({ wallpaper: root.current, interval: root.rotationInterval }))
        store.writeFile()
    }

    function setWallpaper(path) {
        if (!path) return
        root.current = path
        root.save()
        if (root.rotationInterval > 0) rotation.restart()
    }

    function cycleInterval() {
        const currentIndex = root.intervalOptions.indexOf(root.rotationInterval)
        root.rotationInterval = root.intervalOptions[(currentIndex + 1) % root.intervalOptions.length]
        root.save()
        if (root.rotationInterval > 0) rotation.restart()
        else rotation.stop()
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
        interval: Math.max(1000, root.rotationInterval)
        running: root.wallpapers.length > 1 && root.rotationInterval > 0
        repeat: true
        onTriggered: root.randomize()
    }
}
