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

    function togglePower() {
        let cmd = root.powered ? "bluetoothctl power off" : "bluetoothctl power on";
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ["sh", "-c", cmd + " 2>/dev/null; sleep 0.3"];
        p.running = true;
        Qt.callLater(() => {
            return root.refresh();
        });
    }

    function connect(addr) {
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ["sh", "-c", "bluetoothctl connect " + addr + " 2>/dev/null &"];
        p.running = true;
    }

    function disconnect(addr) {
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ["sh", "-c", "bluetoothctl disconnect " + addr + " 2>/dev/null &"];
        p.running = true;
    }

    function scan() {
        if (root.scanning)
            return ;

        root.scanning = true;
        let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ["sh", "-c", "timeout 8 bluetoothctl --timeout 8 scan on 2>/dev/null; bluetoothctl scan off 2>/dev/null; echo done"];
        p.running = true;
        p.exited.connect(() => {
            root.scanning = false;
            root.refresh();
        });
        // auto-stop
        scanTimer.restart();
    }

    visible: false
    Component.onCompleted: refresh()

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: refresh()
    }

    Process {
        id: powerProc

        command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off"]

        stdout: SplitParser {
            onRead: (d) => {
                root.powered = (d.trim() === "on");
            }
        }

    }

    Process {
        id: devProc

        command: ["sh", "-c", "bluetoothctl devices 2>/dev/null; echo '---'; bluetoothctl devices Connected 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: {
                const next = [];
                let connected = false;
                for (const line of text.trim().split("\n")) {
                    if (line === "---") {
                        connected = true;
                        continue;
                    }
                    const match = line.match(/^Device ([0-9A-F:]+) (.+)$/);
                    if (!match)
                        continue;

                    const device = next.find((device) => {
                        return device.addr === match[1];
                    });
                    if (device) {
                        if (connected)
                            device.connected = true;

                    } else {
                        next.push({
                            "addr": match[1],
                            "name": match[2],
                            "connected": connected,
                            "paired": true
                        });
                    }
                }
                next.sort((a, b) => {
                    return a.addr.localeCompare(b.addr);
                });
                if (JSON.stringify(next) !== JSON.stringify(root.devices))
                    root.devices = next;

            }
        }

    }

    Process {
        id: connProc

        stdout: SplitParser {
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
