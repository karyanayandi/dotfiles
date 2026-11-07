#!/usr/bin/env python3
"""Check the volume OSD in an offscreen Qt window."""

import json
import os
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
artifacts = Path('/tmp/quickshell-volume-ui-check')
artifacts.mkdir(exist_ok=True)
names = ('volume', 'muted', 'microphone', 'narrow')
for name in names:
    (artifacts / f'{name}.png').unlink(missing_ok=True)

with tempfile.TemporaryDirectory(prefix='volume-ui-test-') as directory:
    shell = Path(directory) / 'shell.qml'
    shell.write_text('''import QtQuick
import QtTest
import Quickshell
import ROOT as App
import MODULES as Modules
ShellRoot {
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 400
        implicitHeight: 140
        color: "#222222"
        QtObject {
            id: audio
            property string osdIcon: ""
            property string osdKind: "sink"
            property bool muted: false
            property int osdPercent: 50
        }
        Rectangle {
            id: surface
            x: 20; y: 20
            width: osd.width
            height: osd.height
            radius: App.Theme.radiusPanel
            color: App.Theme.colLauncherBg
            Modules.Osd {
                id: osd
                width: App.Config.osdWidth
                height: implicitHeight
                audio: audio
            }
        }
        Timer {
            interval: 100; running: true
            onTriggered: {
                try { tests.test_workflow(); }
                catch (error) { console.error("FAIL volume UI workflow", error, error.stack); }
                Qt.quit();
            }
        }
        TestCase {
            id: tests
            name: "VolumeUI"
            when: false
            function part(name) {
                const item = findChild(osd, name);
                verify(item !== null, "Missing " + name);
                return item;
            }
            function snapshot(name) {
                let saved = false;
                verify(surface.grabToImage(function(result) {
                    saved = result.saveToFile(ARTIFACTS + "/" + name + ".png");
                }));
                tryVerify(() => saved);
            }
            function test_workflow() {
                App.Config.reducedMotion = true;
                compare(osd.width, App.Config.osdWidth);
                verify(osd.width >= 320 && osd.width <= 360);
                verify(osd.height >= 80 && osd.height <= 88);
                const label = part("osdLabel");
                const percent = part("osdPercent");
                const icon = part("osdIcon");
                const meter = part("osdMeter");
                const fill = part("osdFill");
                compare(label.text, "Volume");
                compare(icon.text, audio.osdIcon);
                compare(percent.text, "50%");
                compare(fill.width, meter.width * 0.5);
                snapshot("volume");
                audio.osdPercent = 55;
                compare(fill.width, meter.width * 0.55);
                audio.osdPercent = 45;
                compare(fill.width, meter.width * 0.45);
                audio.osdPercent = 80;
                audio.osdPercent = 20;
                compare(percent.text, "20%");
                compare(fill.width, meter.width * 0.2);
                App.Config.reducedMotion = false;
                audio.osdPercent = 75;
                audio.osdPercent = 25;
                compare(fill.width, meter.width * 0.25);
                App.Config.reducedMotion = true;
                audio.osdPercent = 0;
                compare(fill.width, 0);
                audio.osdPercent = 100;
                compare(fill.width, meter.width);
                audio.osdPercent = 140;
                compare(percent.text, "140%");
                compare(fill.width, meter.width);
                audio.muted = true;
                audio.osdIcon = "󰸈";
                compare(label.text, "Muted");
                compare(icon.text, audio.osdIcon);
                snapshot("muted");
                audio.osdIcon = "";
                audio.muted = false;
                compare(label.text, "Volume");
                audio.osdKind = "mic";
                audio.muted = true;
                audio.osdIcon = "";
                compare(label.text, "Microphone");
                compare(icon.text, audio.osdIcon);
                snapshot("microphone");
                osd.width = 240;
                wait(0);
                verify(label.contentWidth <= label.width);
                verify(percent.contentWidth <= percent.width);
                verify(meter.width > 0);
                snapshot("narrow");
                console.info("PASS volume UI workflow");
            }
        }
    }
}
'''.replace('ROOT', json.dumps(root.as_uri())).replace('MODULES', json.dumps((root / 'modules').as_uri())).replace('ARTIFACTS', json.dumps(str(artifacts))))
    result = subprocess.run(['qs', '-p', str(shell), '--no-color'], env={**os.environ, 'QT_QPA_PLATFORM': 'offscreen'}, capture_output=True, text=True, timeout=20, check=False)
    output = result.stdout + result.stderr
    (artifacts / 'report.txt').write_text(output)
    assert result.returncode == 0 and 'PASS volume UI workflow' in output, output
    assert 'FAIL' not in output and 'ERROR' not in output, output
    for name in names:
        assert (artifacts / f'{name}.png').read_bytes().startswith(b'\x89PNG\r\n\x1a\n')
    print(f'PASS volume UI workflow; artifacts: {artifacts}')
