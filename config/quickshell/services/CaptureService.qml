import ".."
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool ready: false
    property bool busy: false
    property bool recording: false
    property string action: ""
    property string message: "Starting capture service…"
    property string preview: ""
    property bool canUndo: false
    property string savedPath: ""
    property string hex: ""
    property var tools: ({})
    property bool windowSupported: false
    property var sources: [
        {
            "name": "",
            "description": "No audio"
        }
    ]
    property double startedAt: 0
    property int elapsed: 0

    signal reveal(string panel)

    function request(action, options) {
        if (!ready || busy)
            return false;

        const payload = Object.assign({}, options || {}, {
            "action": action
        });
        payload.background = Theme.colBg.toString() + "99";
        payload.border = Theme.colFg.toString();
        payload.selection = Theme.colAccent.toString() + "55";
        root.action = action;
        busy = true;
        message = action === "capabilities" ? "Checking tools…" : "Working…";
        worker.write(JSON.stringify(payload) + "\n");
        return true;
    }

    function stop() {
        if (!busy)
            return;

        message = recording ? "Stopping and finalizing video…" : "Cancelling…";
        worker.write('{"action":"stop"}\n');
    }

    function receive(data) {
        switch (data.event) {
        case "ready":
            ready = true;
            request("capabilities");
            break;
        case "capabilities":
            tools = data.tools;
            windowSupported = data.window;
            sources = data.sources;
            message = "";
            break;
        case "recording":
            recording = true;
            startedAt = Date.now();
            elapsed = 0;
            message = "Recording. Use the stop shortcut or reopen this panel to stop.";
            break;
        case "preview":
            preview = data.url;
            canUndo = data.canUndo === true;
            message = "";
            break;
        case "color":
            hex = data.hex;
            message = "";
            break;
        case "saved":
            savedPath = data.path;
            message = "Saved " + data.path.split("/").pop();
            break;
        case "copied":
            message = "Copied to clipboard.";
            break;
        case "cancelled":
            message = "Selection cancelled.";
            break;
        case "error":
            message = "Error: " + data.message;
            break;
        case "idle":
            busy = false;
            recording = false;
            if (action !== "capabilities")
                reveal(action === "pick" || action === "copy-color" ? "color" : "capture");

            break;
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.elapsed = Math.floor((Date.now() - root.startedAt) / 1000)
    }

    Process {
        id: worker

        command: ["python3", Quickshell.shellPath("scripts/capture.py")]
        running: true
        stdinEnabled: true
        onExited: (code, status) => {
            root.ready = false;
            root.busy = false;
            root.recording = false;
            root.message = "Capture service exited (" + code + "). Reload the shell to restart.";
            root.reveal("capture");
        }

        stdout: SplitParser {
            onRead: data => {
                try {
                    root.receive(JSON.parse(data));
                } catch (error) {
                    root.message = "Capture protocol error: " + error;
                }
            }
        }

        stderr: SplitParser {
            onRead: data => {
                return console.warn("capture:", data);
            }
        }
    }
}
