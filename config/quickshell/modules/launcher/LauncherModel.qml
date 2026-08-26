import Quickshell
import Quickshell.Io
import QtQuick
import "../.."
import "../../services" as Services

Item {
    id: root
    visible: false
    property bool pinnedMode: false
    property string query: ""
    property int selected: 0
    property string mode: "all"
    property var apps: []
    readonly property var clipboard: clipSvc
    readonly property var bluetooth: btSvc
    readonly property var results: {
        const query = root.query.toLowerCase().trim()
        const mode = root.mode
        const score = (text, needle) => {
            if (!needle) return 1
            text = text.toLowerCase()
            if (text === needle) return 100
            if (text.startsWith(needle)) return 50
            if (text.includes(needle)) return 10
            let position = 0
            for (const character of needle) {
                position = text.indexOf(character, position)
                if (position === -1) return 0
                position++
            }
            return 1
        }
        let results = []

        if (mode === "all" || mode === "apps") {
            results = results.concat(root.apps.map(app => {
                app.kind = "app"
                app._score = score(app.title, query) + score(app.subtitle, query) * 0.5
                return app
            }).filter(app => !query || app._score > 0))
        }
        if (mode === "all") {
            const switchers = [
                { title: "Emoji Picker", subtitle: "search + paste emoji", icon: "\u{1f600}", go: "emoji" },
                { title: "Nerd Fonts", subtitle: "search + paste icons", icon: "\u{f0b10}", go: "nerd" },
                { title: "Clipboard History", subtitle: "paste recent clips", icon: "\u{f0147}", go: "clipboard" },
                { title: "Bluetooth", subtitle: "manage devices", icon: "\u{f00af}", go: "bluetooth" },
                { title: "Power", subtitle: "lock, reboot, shutdown\u2026", icon: "\u{f0425}", go: "power" }
            ]
            results = results.concat(switchers.map(item => {
                item.kind = "switch"
                item._score = score(item.title + " " + item.subtitle, query)
                return item
            }).filter(item => item._score > 0))
        }
        if (mode === "power") {
            results = results.concat([
                { title: "Lock", subtitle: "hyprlock", icon: "\u{f023}", cmd: "hyprlock" },
                { title: "Logout", subtitle: "exit Hyprland", icon: "\u{f08b}", cmd: "hyprctl dispatch exit" },
                { title: "Suspend", subtitle: "systemctl suspend", icon: "\u{f186}", cmd: "systemctl suspend" },
                { title: "Reboot", subtitle: "systemctl reboot", icon: "\u{f021}", cmd: "systemctl reboot" },
                { title: "Shutdown", subtitle: "systemctl poweroff", icon: "\u{f0425}", cmd: "systemctl poweroff" }
            ].map(item => {
                item.kind = "power"
                item._score = score(item.title + " " + item.subtitle, query) * 0.5 + (query ? 0 : 0.4)
                return item
            }).filter(item => item._score > 0))
        }
        if (mode === "clipboard") {
            results = results.concat(clipSvc.history.map((entry, index) => ({
                kind: "clip",
                img: entry.img || "",
                title: entry.img ? "\u{1f5bc} Image" : (entry.preview || entry.text).slice(0, 72) + (entry.text.length > 72 ? "\u2026" : ""),
                subtitle: new Date(entry.time).toLocaleTimeString() + " \u00b7 " + (entry.img ? "image" : entry.text.length + " chars"),
                icon: entry.img ? "" : "\u{f0147}",
                text: entry.text,
                time: entry.time,
                index,
                actionHint: "\u21b5 paste",
                _score: score(entry.img ? "image" : entry.text, query) * 0.9
            })).filter(item => item._score > 0))
        }
        if (mode === "emoji") {
            results = results.concat(emojiSvc.emojis.map(entry => ({ kind: "emoji", title: entry.e + "  " + entry.n, subtitle: entry.n, icon: entry.e, text: entry.e, actionHint: "\u21b5 paste", _score: score(entry.n, query) * 0.8 })).filter(item => item._score > 0))
        }
        if (mode === "nerd") {
            results = results.concat(nerdSvc.icons.map(entry => ({ kind: "nerd", title: entry.c + "  " + entry.n, subtitle: entry.k + " \u00b7 " + entry.n, icon: entry.c, text: entry.c, actionHint: "\u21b5 paste", _score: score(entry.n, query) * 0.7 })).filter(item => item._score > 0))
        }
        if (mode === "bluetooth") {
            let devices = btSvc.devices.map(device => ({
                kind: "bt",
                title: device.name,
                subtitle: device.addr + (device.connected ? " \u00b7 connected" : ""),
                icon: "\u{f00af}",
                addr: device.addr,
                connected: device.connected,
                _score: score(device.name, query),
                actionHint: device.connected ? "disconnect" : "connect"
            }))
            if (query) devices = devices.filter(item => item._score > 0)
            devices.sort((left, right) => (right.connected ? 1 : 0) - (left.connected ? 1 : 0))
            if (!query) devices.unshift({ kind: "bt", title: btSvc.powered ? "Bluetooth On" : "Bluetooth Off", subtitle: "Toggle power", icon: "\u{f00af}", _action: "power", actionHint: "toggle" })
            results = results.concat(devices)
        }

        results.sort((left, right) => mode === "clipboard"
            ? (right.time || 0) - (left.time || 0)
            : right._score - left._score)
        return results.slice(0, 200)
    }

    signal closeRequested()
    signal sourceOpened()

    Services.ClipboardService { id: clipSvc }
    Services.BluetoothService { id: btSvc }
    Services.EmojiService { id: emojiSvc }
    Services.NerdFontService { id: nerdSvc }

    function refreshApps() {
        root.apps = DesktopEntries.applications.values.filter(entry => !entry.noDisplay && entry.execString).map(entry => ({
            title: entry.name || entry.id,
            subtitle: (entry.execString || "").split(" ")[0].replace(/^.*\//, ""),
            icon: entry.icon || "",
            entry,
            actionHint: "\u21b5"
        }))
    }

    function refreshBluetooth() { btSvc.refresh() }

    function triggerSelected(ctrl) {
        const item = root.results[root.selected]
        if (!item) return

        if (item.kind === "app") {
            if (item.entry && item.entry.execute) item.entry.execute()
            else run((item.exec || "") + " >/dev/null 2>&1 & disown")
            root.closeRequested()
        } else if (item.kind === "clip") {
            if (item.img) clipSvc.copyFile(item.img)
            else if (ctrl) clipSvc.copy(item.text)
            else clipSvc.autopaste(item.text)
            root.closeRequested()
        } else if (item.kind === "emoji" || item.kind === "nerd") {
            const text = item.text.replace(/'/g, "'\\''")
            run(ctrl ? "printf %s '" + text + "' | wl-copy" : "printf %s '" + text + "' | wl-copy; sleep 0.12; if command -v wtype >/dev/null 2>&1; then wtype -- '" + text + "' 2>/dev/null; fi")
            root.closeRequested()
        } else if (item.kind === "switch") {
            root.mode = item.go
            root.pinnedMode = false
            root.query = ""
            root.selected = 0
            if (item.go === "bluetooth") btSvc.refresh()
            root.sourceOpened()
        } else if (item.kind === "bt") {
            if (item._action === "power") btSvc.togglePower()
            else if (item.connected) btSvc.disconnect(item.addr)
            else btSvc.connect(item.addr)
        } else if (item.kind === "power") {
            run(item.cmd + " >/dev/null 2>&1")
            root.closeRequested()
        }
    }

    function run(command) {
        const process = Qt.createQmlObject("import Quickshell.Io; Process {}", root)
        process.command = ["sh", "-c", command]
        process.running = true
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: if (root.apps.length === 0) root.refreshApps()
    }
}
