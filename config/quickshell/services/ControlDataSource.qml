import QtQuick
import Quickshell.Io

Item {
    id: root

    required property string script
    property bool active: false
    property int interval: 15000
    property var result: ({})
    readonly property bool busy: process.running

    function request(args) {
        if (process.running)
            return;

        process.command = ["/usr/bin/python3", root.script].concat(args || []);
        process.running = true;
    }

    visible: false

    Timer {
        interval: root.interval
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.request([])
    }

    Process {
        id: process

        onExited: exitCode => {
            if (exitCode !== 0)
                root.result = {
                    "ok": false,
                    "message": "Helper unavailable"
                };
        }

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.result = JSON.parse(text);
                } catch (_) {
                    root.result = {
                        "ok": false,
                        "message": "Helper returned no valid data"
                    };
                }
            }
        }
        // Consume stderr without forwarding it into shell logs.

        stderr: StdioCollector {}
    }
}
