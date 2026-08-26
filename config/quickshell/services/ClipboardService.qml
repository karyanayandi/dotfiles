import Quickshell.Io
import QtQuick

Item {
    id: root
    visible: false
    property var history: []
    property int maxSize: 100
    readonly property string storePath: "/home/karyana/.cache/quickshell/clipboard.json"

    FileView { id: store; path: root.storePath; blockLoading: true }
    Component.onCompleted: {
        store.reload();
        try {
            let v = JSON.parse(store.text() || "[]");
            if (Array.isArray(v)) root.history = v.slice().sort((a, b) => (b.time || 0) - (a.time || 0));
        } catch(e) {}
        pollTimer.start();
    }

    function save() {
        store.setText(JSON.stringify(root.history.slice(0, root.maxSize)));
        store.writeFile();
    }

    readonly property string imgDir: "/home/karyana/.cache/quickshell/clip-img"

    property string _lastHash: ""
    Timer { id: pollTimer; interval: 700; running: false; repeat: true; onTriggered: pastePoll.running = true }
    Process {
        id: pastePoll
        command: ["sh","-c",
            "mkdir -p " + root.imgDir + "; " +
            "if wl-paste --list-types 2>/dev/null | grep -qx 'image/png'; then " +
            "h=$(wl-paste -t image/png 2>/dev/null | sha256sum | cut -c1-12); f=" + root.imgDir + "/$h.png; " +
            "[ -s \"$f\" ] || wl-paste -t image/png > \"$f\"; echo \"IMG:$f\"; " +
            "else wl-paste 2>/dev/null | head -c 8000 | tr -d '\\0' | head -c 4000; fi"]
        stdout: SplitParser {
            onRead: data => {
                let raw = (data||"").trim();
                if (!raw) return;
                let isImg = raw.startsWith("IMG:");
                let t = isImg ? raw.slice(4) : raw;
                if (!t) return;
                let hash = (isImg?"I":"T") + t.length + ":" + t.slice(0,48);
                if (hash === root._lastHash) return;
                root._lastHash = hash;
                if (root.history.length && (isImg ? root.history[0].img === t : root.history[0].text === t)) return;
                let idx = root.history.findIndex(x => isImg ? x.img === t : x.text === t);
                if (idx !== -1) root.history.splice(idx,1);
                let entry = isImg
                    ? { img: t, text: "", time: Date.now(), preview: "\u{1f5bc} Image" }
                    : { text: t, time: Date.now(), preview: t.slice(0,120).replace(/\n/g," ") };
                root.history.unshift(entry);
                if (root.history.length > root.maxSize) root.history = root.history.slice(0, root.maxSize);
                root.historyChanged();
                root.save();
            }
        }
    }

    function copy(text) {
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ['sh','-c', 'printf %s "$1" | wl-copy 2>/dev/null', 'sh', text];
        p.running = true;
    }
    function copyFile(path) {
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ['sh','-c', 'wl-copy < "$1" 2>/dev/null', 'sh', path];
        p.running = true;
    }
    function autopaste(text) {
        copy(text);
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ['sh','-c', 'sleep 0.13; if command -v wtype >/dev/null 2>&1; then wl-paste 2>/dev/null | wtype - 2>/dev/null; elif command -v ydotool >/dev/null 2>&1; then ydotool type --key-delay 0 "$(wl-paste)" 2>/dev/null; else notify-send -t 1800 Copied "Install wtype for autopaste: pacman -S wtype" 2>/dev/null; fi'];
        p.running = true;
    }
    function removeAt(i) { if (i>=0 && i<root.history.length) { root.history.splice(i,1); root.historyChanged(); root.save(); } }
    function clear() { root.history = []; root.historyChanged(); root.save(); }
}
