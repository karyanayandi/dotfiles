#!/usr/bin/env python3
"""Exercise the shared scrollbars in an offscreen Qt window."""

import json
import os
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
artifacts = Path("/tmp/quickshell-scrollbar-check")
artifacts.mkdir(exist_ok=True)
for name in ("report.txt", "vertical.png", "horizontal.png", "focused.png"):
    (artifacts / name).unlink(missing_ok=True)

with tempfile.TemporaryDirectory(prefix="scrollbar-test-") as directory:
    shell = Path(directory) / "shell.qml"
    shell.write_text(
        '''import QtQuick
import QtQuick.Controls
import QtTest
import Quickshell
import ROOT as App
import COMPONENTS as Components
ShellRoot {
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 400
        implicitHeight: 360
        color: App.Theme.colBg
        Flickable {
            id: viewport
            x: 40; y: 40; width: 280; height: 240
            contentWidth: 840; contentHeight: 720
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Rectangle {
                width: 840; height: 720
                color: App.Theme.colBgAlt
                Text { x: 600; y: 500; text: "Scrollable content"; color: App.Theme.colFg }
            }
            ScrollBar.vertical: Components.ThemedScrollBar { id: vertical }
            ScrollBar.horizontal: Components.ThemedScrollBar { id: horizontal }
        }
        Timer {
            interval: 100; running: true
            onTriggered: {
                try { tests.test_workflow(); }
                catch (error) { console.error("FAIL scrollbar workflow", error, error.stack); }
                Qt.quit();
            }
        }
        TestCase {
            id: tests
            name: "Scrollbars"
            when: false
            function snapshot(name) {
                let saved = false;
                verify(viewport.grabToImage(function(result) {
                    saved = result.saveToFile(ARTIFACTS + "/" + name + ".png");
                }));
                tryVerify(() => saved);
            }
            function test_workflow() {
                wait(100);
                verify(vertical.visible && horizontal.visible);
                verify(vertical.width < vertical.height);
                verify(horizontal.height < horizontal.width);
                verify(vertical.contentItem.implicitWidth < vertical.contentItem.implicitHeight);
                verify(horizontal.contentItem.implicitHeight < horizontal.contentItem.implicitWidth);
                vertical.increase();
                tryVerify(() => viewport.contentY > 0);
                snapshot("vertical");
                horizontal.increase();
                tryVerify(() => viewport.contentX > 0);
                snapshot("horizontal");
                vertical.forceActiveFocus(Qt.TabFocusReason);
                verify(vertical.visualFocus);
                compare(vertical.contentItem.border.width, 2);
                const beforeKey = viewport.contentY;
                keyClick(Qt.Key_Down);
                tryVerify(() => viewport.contentY > beforeKey);
                snapshot("focused");
                const beforeDrag = viewport.contentX;
                mouseMove(horizontal, horizontal.width * horizontal.position + horizontal.contentItem.width / 2, horizontal.height / 2);
                tryVerify(() => horizontal.hovered);
                mousePress(horizontal, horizontal.width * horizontal.position + horizontal.contentItem.width / 2, horizontal.height / 2);
                verify(horizontal.pressed);
                mouseMove(horizontal, horizontal.width * 0.8, horizontal.height / 2, 30);
                mouseRelease(horizontal, horizontal.width * 0.8, horizontal.height / 2);
                tryVerify(() => viewport.contentX > beforeDrag);
                tryCompare(viewport, "moving", false);
                viewport.contentX = Math.round(viewport.contentX);
                wait(0);
                const enabledOpacity = horizontal.opacity;
                horizontal.enabled = false;
                verify(horizontal.opacity < enabledOpacity);
                const disabledPosition = horizontal.position;
                mouseClick(horizontal, horizontal.width / 2, horizontal.height / 2);
                compare(horizontal.position, disabledPosition);
                horizontal.enabled = true;
                App.Config.reducedMotion = true;
                horizontal.position = 0;
                const beforeReduced = viewport.contentX;
                horizontal.increase();
                verify(viewport.contentX > beforeReduced);
                App.Config.reducedMotion = false;
                viewport.contentWidth = viewport.width;
                viewport.contentHeight = viewport.height;
                tryVerify(() => !horizontal.visible && !vertical.visible);
                console.info("PASS scrollbar workflow");
            }
        }
    }
}
'''.replace("ROOT", json.dumps(root.as_uri()))
        .replace("COMPONENTS", json.dumps((root / "components").as_uri()))
        .replace("ARTIFACTS", json.dumps(str(artifacts)))
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
    assert result.returncode == 0 and "PASS scrollbar workflow" in output, output
    assert "FAIL" not in output and "ERROR" not in output, output
    for name in ("vertical", "horizontal", "focused"):
        assert (artifacts / f"{name}.png").read_bytes().startswith(b"\x89PNG\r\n\x1a\n")
    print(f"PASS scrollbar workflow; artifacts: {artifacts}")
