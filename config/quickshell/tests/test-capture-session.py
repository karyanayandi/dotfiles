#!/usr/bin/env python3
"""Exercise real capture QML session state without capturing or copying pixels."""

import json
import os
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
bindings = (root.parent / "hypr/bind.lua").read_text()
assert (
    'hl.bind("SHIFT + Print", hl.dsp.exec_cmd "qs ipc call capture start screenshot area")'
    in bindings
)
assert (
    'hl.bind(mainMod .. " + CTRL + G", hl.dsp.exec_cmd "qs ipc call capture start record screen")'
    in bindings
)
island = (root / "modules/Island.qml").read_text()
assert "function start(action: string, mode: string)" in island
assert (
    'win.startCapture(action, {\n                "mode": mode\n            });'
    in island
)
assert 'capture.video = action === "record"' in island
assert "captureService.busy || captureDelay.running" in island
with tempfile.TemporaryDirectory(prefix="capture-session-test-") as directory:
    directory = Path(directory)
    (directory / "scripts").symlink_to(root / "scripts", target_is_directory=True)
    shell = directory / "shell.qml"
    shell.write_text(
        """import QtQuick
import Quickshell
import SERVICES as Services
import MODULES as Modules
ShellRoot {
    Services.CaptureService { id: service }
    Modules.CapturePanel { id: panel; service: service; width: 600; height: 760 }
    Timer {
        interval: 50
        repeat: true
        running: true
        onTriggered: {
            if (!service.ready || service.busy) return;
            stop();
            function check(value, message) {
                if (!value) throw new Error(message);
            }
            function preview() {
                service.receive({event: "preview", url: "", canUndo: true});
                // Nonempty URL enables editor/footer state. No pixels are captured.
                service.preview = "file:///unused-test-preview.png";
            }
            function reopen() {
                panel.opened = false;
                panel.open("area");
            }
            try {
                panel.open("area");
                for (const action of ["save", "copy-image"]) {
                    preview();
                    service.action = action;
                    service.receive(action === "save"
                        ? {event: "saved", path: "/tmp/saved.png", kind: "screenshot"}
                        : {event: "copied"});
                    check(service.preview !== "", "export must keep current editor");
                    // Capabilities refresh must not erase export tracking.
                    service.hasResult = false;
                    reopen();
                    check(service.preview === "" && !service.canUndo && !service.previewExported,
                          "reopen retained exported screenshot");
                    check(service.savedPath === "" && !service.hasResult && service.message === "",
                          "reopen retained result metadata");
                    check(!panel.editing, "reopen retained editor");
                }
                preview();
                reopen();
                check(service.preview !== "", "unsaved preview lost");
                service.action = "save";
                service.receive({event: "error", message: "save failed"});
                reopen();
                check(service.preview !== "", "failed save lost preview");
                service.receive({event: "saved", path: "/tmp/video.mp4", kind: "recording"});
                service.action = "copy-color";
                service.receive({event: "copied"});
                reopen();
                check(service.preview !== "", "non-image export cleared preview");
                service.action = "copy-image";
                service.receive({event: "copied"});
                preview();
                reopen();
                check(service.preview !== "", "new edit inherited exported state");
                service.previewExported = true;
                service.busy = true;
                reopen();
                check(service.preview !== "", "busy operation lost preview");
                service.busy = false;
                // Control-center and worker reveal use opened directly, not open().
                panel.opened = false;
                panel.opened = true;
                check(service.preview === "", "direct reopen retained exported preview");
                console.log("PASS capture session regression");
            } catch (error) {
                console.error("FAIL capture session regression", error);
            }
            Qt.quit();
        }
    }
}
""".replace("SERVICES", json.dumps((root / "services").as_uri())).replace(
            "MODULES", json.dumps((root / "modules").as_uri())
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
    assert result.returncode == 0 and "PASS capture session regression" in output, (
        output
    )
    assert "FAIL" not in output and "ERROR" not in output, output
    print(
        "PASS capture session: save/copy reopen, unsaved/edit/error/busy preservation"
    )
