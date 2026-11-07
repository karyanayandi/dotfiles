#!/usr/bin/env python3
"""Check wallpaper grid width, selection, and scrolling at desktop and narrow sizes."""
import json
import os
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
artifacts = Path('/tmp/quickshell-wallpaper-layout-check')
artifacts.mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix='wallpaper-layout-check-') as directory:
    work = Path(directory)
    image = work / 'preview.svg'
    image.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="320" height="180"><rect width="320" height="180" fill="#456789"/><circle cx="240" cy="60" r="45" fill="#abcabc"/></svg>')
    shell = work / 'shell.qml'
    shell.write_text('''import QtQuick
import QtTest
import Quickshell
import LAUNCHER as Launcher
ShellRoot {
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 1000
        implicitHeight: 700
        Launcher.Results {
            id: results
            width: 920
            height: 500
            anchors.horizontalCenter: parent.horizontalCenter
            y: 16
            model: Array.from({length: 30}, (_, index) => ({kind: "wallpaper", title: "Wallpaper " + index, path: IMAGE}))
            onSelectionRequested: index => selected = index
            onActivated: (index, ctrl) => {
                tests.activated = index;
                tests.controlPressed = ctrl;
            }
        }
        Timer {
            interval: 100
            running: true
            onTriggered: {
                try { tests.test_workflow(); }
                catch (error) { console.error("FAIL wallpaper layout", error); }
                Qt.quit();
            }
        }
        TestCase {
            id: tests
            name: "WallpaperLayout"
            when: false
            property int activated: -1
            property bool controlPressed: false
            function screenshot(name) {
                let saved = false;
                verify(results.grabToImage(result => { saved = result.saveToFile(ARTIFACTS + "/" + name + ".png"); }));
                tryVerify(() => saved);
            }
            function test_workflow() {
                const grid = findChild(results, "launcherGrid");
                verify(grid !== null);
                for (const size of [920, 680, 390, 220]) {
                    results.width = size;
                    results.selected = 0;
                    wait(60);
                    verify(grid.width >= results.width - 24, "Grid must use the available width");
                    verify(Math.abs(grid.x - (results.width - grid.width) / 2) < 1);
                    verify(grid.x <= 12, "No wide empty side gutters");
                    verify(Math.abs(grid.width - grid.cellWidth * results.gridColumns) < 0.1);
                    const last = grid.itemAtIndex(results.gridColumns - 1);
                    verify(last !== null);
                    compare(last.y, 0, "All columns must fit on the first row");
                    verify(last.x + last.width <= grid.width + 1);
                    mouseClick(last, last.width / 2, last.height / 2, Qt.LeftButton, Qt.ControlModifier);
                    compare(activated, results.gridColumns - 1);
                    verify(controlPressed);
                    results.selected = 29;
                    wait(50);
                    verify(grid.contentY > 0, "Selection must stay reachable by scrolling");
                    results.selected = 0;
                    wait(50);
                    screenshot("wallpaper-" + size);
                }
                results.width = 920;
                results.model = Array.from({length: 40}, () => ({kind: "emoji", text: "A"}));
                wait(50);
                compare(grid.cellWidth, 64, "Emoji cells retain their size");
                compare(results.gridColumns, Math.floor(results.width / 64));
                results.model = [];
                wait(30);
                compare(grid.count, 0);
                console.info("PASS wallpaper width, responsive rows, selection, scrolling, emoji, and empty model");
            }
        }
    }
}
'''.replace('LAUNCHER', json.dumps((root / 'modules/launcher').as_uri())).replace('ARTIFACTS', json.dumps(str(artifacts))).replace('IMAGE', json.dumps(str(image))))
    result = subprocess.run(['quickshell', '-p', str(shell), '--no-color'], capture_output=True, text=True, env={**os.environ, 'QT_QPA_PLATFORM': 'offscreen'}, timeout=20)
    output = result.stdout + result.stderr
    (artifacts / 'report.txt').write_text(output)
    assert result.returncode == 0 and 'PASS wallpaper width' in output, output
    assert 'FAIL' not in output and 'ERROR' not in output, output
    for size in [920, 680, 390, 220]:
        assert (artifacts / f'wallpaper-{size}.png').read_bytes().startswith(b'\x89PNG\r\n\x1a\n')
    print(f'PASS wallpaper layout; artifacts: {artifacts}')
