#!/usr/bin/env python3
"""Exercise notification-center actions with keyboard input, without desktop changes."""
import json
import os
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
artifacts = Path('/tmp/quickshell-notification-controls-check')
artifacts.mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix='notification-controls-check-') as directory:
    shell = Path(directory) / 'shell.qml'
    shell.write_text('''import QtQuick
import QtTest
import Quickshell
import NOTIFICATIONS as Notifications
ShellRoot {
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 420
        implicitHeight: 700
        QtObject {
            id: service
            property bool controlCenterVisible: true
            property bool doNotDisturb: false
            property int notifCount: 1
            property int clears: 0
            property int groupDismissals: 0
            property var items: [{appName: "Test", summary: "Message", body: "Keyboard action check", urgency: 1, actions: [], dismiss: function() {}}]
            function grouped() { return notifCount ? [{appName: "Test", notifications: items}] : []; }
            function dismissAll() { ++clears; notifCount = 0; }
            function dismissGroup(group) { ++groupDismissals; notifCount = 0; }
            function toggleDnd() { doNotDisturb = !doNotDisturb; }
        }
        Notifications.Center {
            id: center
            anchors.fill: parent
            notifs: service
        }
        Timer {
            interval: 100
            running: true
            onTriggered: {
                try { tests.test_workflow(); }
                catch (error) { console.error("FAIL notification controls", error); }
                Qt.quit();
            }
        }
        TestCase {
            id: tests
            name: "NotificationControls"
            when: false
            function activate(name) {
                const button = findChild(center, name);
                verify(button !== null, "Missing " + name);
                button.forceActiveFocus(Qt.TabFocusReason);
                verify(button.activeFocus);
                keyClick(Qt.Key_Space);
                wait(30);
            }
            function test_workflow() {
                activate("notificationClearAll");
                compare(service.clears, 1);
                compare(service.notifCount, 0);
                service.notifCount = 1;
                wait(30);
                activate("notificationDismissGroup_Test");
                compare(service.groupDismissals, 1);
                compare(service.notifCount, 0);
                service.notifCount = 1;
                wait(30);
                activate("notificationDndSwitch");
                compare(service.doNotDisturb, true);
                activate("notificationDndSwitch");
                compare(service.doNotDisturb, false);
                let saved = false;
                verify(center.grabToImage(result => { saved = result.saveToFile(ARTIFACTS + "/controls.png"); }));
                tryVerify(() => saved);
                console.info("PASS keyboard clear-all, group dismiss, and DND controls");
            }
        }
    }
}
'''.replace('NOTIFICATIONS', json.dumps((root / 'modules/notifications').as_uri())).replace('ARTIFACTS', json.dumps(str(artifacts))))
    result = subprocess.run(['quickshell', '-p', str(shell), '--no-color'], capture_output=True, text=True, env={**os.environ, 'QT_QPA_PLATFORM': 'offscreen'}, timeout=15)
    output = result.stdout + result.stderr
    (artifacts / 'report.txt').write_text(output)
    assert result.returncode == 0 and 'PASS keyboard' in output, output
    assert 'FAIL' not in output and 'ERROR' not in output, output
    assert (artifacts / 'controls.png').read_bytes().startswith(b'\x89PNG\r\n\x1a\n')
    print(f'PASS notification controls; artifacts: {artifacts}')
