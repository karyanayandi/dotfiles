import Quickshell.Io
import QtQuick

Item {
    id: root
    visible: false
    property var devices: [] // {addr,name,connected,paired,icon}
    property bool powered: false
    property bool scanning: false

    Timer { interval: 3000; running: true; repeat: true; onTriggered: refresh() }
    Component.onCompleted: refresh()

    function refresh() {
        powerProc.running = true;
        devices = [];
        devProc._inConnected = false;
        devProc.running = true;
    }

    Process {
        id: powerProc
        command: ["sh","-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off"]
        stdout: SplitParser { onRead: d => { root.powered = (d.trim()==="on"); } }
    }
    Process {
        id: devProc
        command: ["sh","-c", "bluetoothctl devices 2>/dev/null; echo '---'; bluetoothctl devices Connected 2>/dev/null"]
        property bool _inConnected: false
        stdout: SplitParser {
            onRead: data => {
                let l = data.trim();
                if (l === "---") { devProc._inConnected = true; return; }
                let m = l.match(/^Device ([0-9A-F:]+) (.+)$/);
                if (!m) return;
                if (!devProc._inConnected) {
                    for (let x of root.devices) if (x.addr === m[1]) return;
                    root.devices.push({ addr: m[1], name: m[2], connected: false, paired: true });
                } else {
                    for (let x of root.devices) if (x.addr === m[1]) { x.connected = true; }
                }
                root.devicesChanged();
            }
        }
    }
    Process { id: connProc; stdout: SplitParser {} }

    function togglePower() {
        let cmd = root.powered ? "bluetoothctl power off" : "bluetoothctl power on";
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ["sh","-c", cmd + " 2>/dev/null; sleep 0.3"];
        p.running = true;
        Qt.callLater(()=> root.refresh());
    }
    function connect(addr) {
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ["sh","-c", "bluetoothctl connect " + addr + " 2>/dev/null &"];
        p.running = true;
    }
    function disconnect(addr) {
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ["sh","-c", "bluetoothctl disconnect " + addr + " 2>/dev/null &"];
        p.running = true;
    }
    function scan() {
        if (root.scanning) return;
        root.scanning = true;
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ["sh","-c", "timeout 8 bluetoothctl --timeout 8 scan on 2>/dev/null; bluetoothctl scan off 2>/dev/null; echo done"];
        p.running = true;
        p.exited.connect(()=> { root.scanning=false; root.refresh(); });
        // auto-stop
        scanTimer.restart();
    }
    Timer { id: scanTimer; interval: 8500; onTriggered: { root.scanning=false; root.refresh(); } }
}
