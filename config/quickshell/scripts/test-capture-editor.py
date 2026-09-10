#!/usr/bin/env python3
"""Run QtTest gestures inside qs, which provides Quickshell's built-in plugins."""

import json
import os
import subprocess
import tempfile
from pathlib import Path

source = Path(__file__).resolve().parents[1] / "modules/capture/tst_captureeditor.qml"
with tempfile.TemporaryDirectory(prefix="capture-editor-test-") as directory:
    shell = Path(directory) / "shell.qml"
    shell.write_text(
        """import QtQuick
import Quickshell
ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 640
        implicitHeight: 900
        Loader { id: tests; source: SOURCE }
    }
    Timer {
        interval: 100
        running: true
        onTriggered: {
            try {
                const t = tests.item;
                for (const tool of ["marker", "arrow"]) {
                    t.init();
                    t.test_draw({tool: tool});
                }
                for (const name of ["test_text", "test_busyBlocksDrawing", "test_failureClearsStroke"]) {
                    t.init();
                    t[name]();
                }
                console.log("PASS native annotation UI");
            } catch (error) {
                console.error("FAIL native annotation UI", error);
            }
            Qt.quit();
        }
    }
}
""".replace("SOURCE", json.dumps(source.as_uri()))
    )
    result = subprocess.run(
        ["qs", "-p", str(shell), "--no-color"],
        env={**os.environ, "QT_QPA_PLATFORM": "offscreen"},
        capture_output=True,
        check=False,
        text=True,
        timeout=20,
    )
    output = result.stdout + result.stderr
    assert result.returncode == 0 and "PASS native annotation UI" in output, output
    assert "FAIL" not in output and "ERROR" not in output, output
    print("PASS native annotation UI: marker, arrow, text, busy guard, failed edit")
