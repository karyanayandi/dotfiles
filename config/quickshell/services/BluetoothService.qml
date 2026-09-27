import QtQuick
import Quickshell.Io

Item {
    id: root

    property var devices: [] // {addr,name,connected,paired,icon}
    property bool powered: false
    property bool scanning: false

    function refresh() {
        powerProc.running = true;
        devProc.running = true;
    }

    function isValidAddr(addr) {
        return /^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/.test(addr || "");
    }

    function spawnOnce(argv, onDone) {
        let p = Qt.createQmlObject('import Quickshell.Io; Process { destroyOnExited: true }', root);
        p.command = argv;
        if (onDone)
            p.exited.connect(onDone);
        p.running = true;
    }

    function togglePower() {
        let argv = root.powered ? ["bluetoothctl", "power", "off"] : ["bluetoothctl", "power", "on"];
        spawnOnce(argv, () => Qt.callLater(() => root.refresh()));
    }

    function connect(addr) {
        if (!isValidAddr(addr)) {
            console.warn("Bluetooth: invalid addr", addr);
            return ;
        }
        spawnOnce(["bluetoothctl", "connect", addr]);
    }

    function disconnect(addr) {
        if (!isValidAddr(addr)) {
            console.warn("Bluetooth: invalid addr", addr);
            return ;
        }
        spawnOnce(["bluetoothctl", "disconnect", addr]);
    }

    function scan() {
        if (root.scanning)
            return ;
        root.scanning = true;
        let p = Qt.createQmlObject('import Quickshell.Io; Process { destroyOnExited: true }', root);
        p.command = ["timeout", "8", "bluetoothctl", "--timeout", "8", "scan", "on"];
        p.exited.connect(() => {
            root.scanning = false;
            root.refresh();
        });
        p.running = true;
        scanTimer.restart();
    }

    visible: false
    Component.onCompleted: refresh()

    property bool pollingActive: true
    property var _pendingDevices: []
    Timer {
        interval: 10000
        running: root.pollingActive
        repeat: true
        onTriggered: refresh()
    }

    Process {
        id: powerProc

        command: ["bluetoothctl", "show"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.powered = /Powered:\s*yes/m.test(text);
            }
        }

    }

    Process {
        id: devProc

        command: ["bluetoothctl", "devices"]

        stdout: StdioCollector {
            onStreamFinished: {
                const base = [];
                for (const line of text.trim().split("\n")) {
                    const match = line.match(/^Device ([0-9A-Fa-f:]+) (.+)$/);
                    if (!match)
                        continue;

                    if (!base.find((d) => d.addr === match[1])) {
                        base.push({
                            "addr": match[1],
                            "name": match[2],
                            "connected": false,
                            "paired": true
                        });
                    }
                }
                base.sort((a, b) => {
                    return a.addr.localeCompare(b.addr);
                });
                root._pendingDevices = base;
                devConnectedProc.running = true;
            }
        }

    }

    Process {
        id: devConnectedProc

        command: ["bluetoothctl", "devices", "Connected"]

        stdout: StdioCollector {
            onStreamFinished: {
                const linked = {
                };
                for (const line of text.trim().split("\n")) {
                    const match = line.match(/^Device ([0-9A-Fa-f:]+)(?:\s+.*)?$/);
                    if (match)
                        linked[match[1]] = true;

                }
                const next = root._pendingDevices.map((d) => ({
                    "addr": d.addr,
                    "name": d.name,
                    "connected": !!linked[d.addr],
                    "paired": d.paired
                }));
                if (JSON.stringify(next) !== JSON.stringify(root.devices))
                    root.devices = next;

            }
        }

    }

    Timer {
        id: scanTimer

        interval: 8500
        onTriggered: {
            root.scanning = false;
            root.refresh();
        }
    }

}
