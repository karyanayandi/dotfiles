#!/usr/bin/env python3
"""Exercise capture launcher controls in Qt and save reproducible UI artifacts."""

import json
import os
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
artifacts = Path("/tmp/quickshell-capture-launcher-check")
artifacts.mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix="capture-launcher-test-") as directory:
    shell = Path(directory) / "shell.qml"
    shell.write_text(
        '''import QtQuick
import QtTest
import Quickshell
import MODULES as Modules
ShellRoot {
    FloatingWindow {
        id: testWindow
        visible: true
        implicitWidth: 420
        implicitHeight: 420
        color: "#242424"
        QtObject {
            id: service
            property bool ready: true
            property bool busy: false
            property bool recording: false
            property bool windowSupported: true
            property bool hasResult: false
            property bool canUndo: false
            property int elapsed: 65
            property string preview: ""
            property string action: ""
            property string message: ""
            property var tools: ({slurp: true, grim: true, "wf-recorder": true})
            property var sources: [{name: "", description: "No audio"}, {name: "mic", description: "Microphone"}]
            property int stops: 0
            property string requestedAction: ""
            function request(action, options) { requestedAction = action; return true; }
            function beginSession() {}
            function stop() { stops++; }
            signal feedback(string text, bool failed)
        }
        Modules.CapturePanel {
            id: panel
            width: 360
            height: implicitHeight
            anchors.centerIn: parent
            service: service
        }
        SignalSpy { id: requests; target: panel; signalName: "captureRequested" }
        Timer {
            interval: 100
            running: true
            onTriggered: {
                try {
                    tests.test_workflow();
                } catch (error) {
                    console.error("FAIL capture launcher workflow", error);
                }
                Qt.quit();
            }
        }
        TestCase {
            id: tests
            name: "CaptureLauncher"
            when: false
            function button(name) {
                const item = findChild(panel, name);
                verify(item !== null, "Missing " + name);
                return item;
            }
            function snapshot(name) {
                let saved = false;
                verify(panel.grabToImage(function(result) {
                    saved = result.saveToFile(ARTIFACTS + "/" + name + ".png");
                }));
                tryVerify(() => saved);
            }
            function test_workflow() {
                panel.open("area");
                wait(100);
                verify(button("captureMode_area").checked);
                mouseClick(button("captureMode_area"));
                verify(button("captureMode_area").checked);
                mouseClick(button("capturePhoto"));
                verify(button("capturePhoto").checked);
                verify(panel.implicitHeight < 360);
                snapshot("screenshot");
                mouseClick(button("captureMode_screen"));
                mouseClick(button("captureStart"));
                compare(requests.count, 1);
                compare(requests.signalArguments[0][0], "screenshot");
                compare(requests.signalArguments[0][1].mode, "screen");
                mouseClick(button("captureMode_window"));
                verify(button("captureMode_window").checked);
                mouseClick(button("captureVideo"));
                verify(panel.video);
                compare(panel.selectedMode, "area");
                verify(!button("captureMode_window").enabled);
                const audio = button("captureAudio");
                audio.currentIndex = 1;
                snapshot("recording-launcher");
                mouseClick(button("captureStart"));
                compare(requests.count, 2);
                compare(requests.signalArguments[1][0], "record");
                compare(requests.signalArguments[1][1].audio, "mic");
                service.busy = true;
                verify(!button("captureStart").enabled);
                service.action = "record";
                service.recording = true;
                snapshot("recording-stop");
                mouseClick(button("captureStop"));
                compare(service.stops, 1);
                service.recording = false;
                service.busy = false;
                mouseClick(button("capturePhoto"));
                service.windowSupported = false;
                verify(!button("captureMode_window").enabled);
                service.tools = ({slurp: true, grim: false});
                verify(!button("captureStart").enabled);
                service.tools = ({slurp: true, grim: true});
                button("captureStart").forceActiveFocus();
                keyClick(Qt.Key_Escape);
                verify(!panel.opened);
                panel.open("record-area");
                verify(panel.opened && panel.video);
                mouseClick(button("captureClose"));
                verify(!panel.opened);
                panel.open("area");
                service.tools = ({slurp: true, grim: true, magick: true, "wl-copy": true});
                service.preview = "data:image/svg+xml," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="800" height="450"><rect width="800" height="450" fill="#abcdef"/></svg>');
                testWindow.implicitWidth = 1000;
                testWindow.implicitHeight = 800;
                panel.width = 960;
                panel.height = 760;
                wait(100);
                verify(panel.editing);
                mouseClick(button("annotationTool_marker"));
                mouseClick(button("annotationTool_marker"));
                verify(button("annotationTool_marker").checked);
                snapshot("screenshot-editor");
                mouseClick(button("captureCopy"));
                compare(service.requestedAction, "copy-image");
                mouseClick(button("captureSave"));
                compare(service.requestedAction, "save");
                mouseClick(button("captureStart"));
                verify(!panel.editing && service.preview !== "");
                mouseClick(button("captureBackToEditor"));
                verify(panel.editing);
                console.info("PASS capture launcher workflow");
                Qt.quit();
            }
        }
    }
}
'''.replace("MODULES", json.dumps((root / "modules").as_uri())).replace(
            "ARTIFACTS", json.dumps(str(artifacts))
        )
    )
    result = subprocess.run(
        ["qs", "-p", str(shell), "--no-color"],
        env={**os.environ, "QT_QPA_PLATFORM": "offscreen"},
        capture_output=True,
        text=True,
        timeout=20,
        check=False,
    )
    output = result.stdout + result.stderr
    (artifacts / "report.txt").write_text(output)
    assert result.returncode == 0 and "PASS capture launcher workflow" in output, output
    assert "FAIL" not in output and "ERROR" not in output, output
    for name in ("screenshot", "recording-launcher", "recording-stop", "screenshot-editor"):
        assert (artifacts / f"{name}.png").read_bytes().startswith(b"\x89PNG\r\n\x1a\n")
    print(f"PASS capture launcher workflow; artifacts: {artifacts}")
