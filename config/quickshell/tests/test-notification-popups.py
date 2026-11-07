#!/usr/bin/env python3
"""Exercise popup layout and lifetime in an offscreen Quickshell session."""
import json
import os
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
artifacts = Path('/tmp/quickshell-notification-popup-check')
artifacts.mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix='notification-popups-') as directory:
    shell = Path(directory) / 'shell.qml'
    shell.write_text('''import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.Notifications
import MODULES as Notifications
ShellRoot {
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 440
        implicitHeight: 700
        Item {
            id: service
            property var popups: []
            property bool controlCenterVisible: false
            property var removed: []
            function removePopup(n) {
                removed = removed.concat([n.summary]);
                popups = popups.filter(item => item !== n);
            }
        }
        Notifications.Popups {
            id: popup
            width: 360
            height: implicitHeight
            maxHeight: 320
            notifs: service
        }
        Timer {
            interval: 100
            running: true
            onTriggered: {
                try { tests.test_workflow(); }
                catch (e) { console.error('FAIL notification popups', e); }
                Qt.quit();
            }
        }
        TestCase {
            id: tests
            name: 'NotificationPopups'
            when: false
            function notif(name, timeout, urgency) {
                const n = Qt.createQmlObject('import QtQuick; QtObject { property string summary; property string body: ""; property string appName: "Test"; property var actions: []; property int urgency; property int expireTimeout }', service);
                n.summary = name;
                n.urgency = urgency === undefined ? NotificationUrgency.Normal : urgency;
                n.expireTimeout = timeout === undefined ? 10000 : timeout;
                return n;
            }
            function add(n) { service.popups = service.popups.concat([n]); wait(30); }
            function card(name) { return findChild(popup, 'popup-' + name); }
            function screenshot(name) {
                let saved = false;
                verify(popup.grabToImage(result => { saved = result.saveToFile(ARTIFACTS + '/' + name + '.png'); }));
                tryVerify(() => saved);
            }
            function test_workflow() {
                compare(popup.implicitHeight, 0);
                const a = notif('a'), b = notif('b'), c = notif('c'), d = notif('d');
                add(a); add(b); add(c); add(d);
                wait(100);
                verify(popup.implicitHeight <= popup.maxHeight);
                verify(popup.visibleCount >= 2);
                verify(popup.overflowCount > 0);
                verify(card('d').opacity > 0);
                verify(card('d').y < card('c').y);
                screenshot('overflow');
                const overflow = findChild(popup, 'popupOverflow');
                verify(overflow !== null && overflow.visible);
                verify(overflow.text.indexOf('more notification') !== -1);
                const stackLayer = findChild(popup, 'popupStackLayer1');
                verify(stackLayer !== null && stackLayer.visible);
                verify(stackLayer.y > 0 && stackLayer.width < overflow.width);
                screenshot('overflow-stack');
                mouseClick(overflow);
                verify(service.controlCenterVisible);
                service.controlCenterVisible = false;
                mouseClick(card('d'), card('d').width - 36, 36);
                verify(service.popups.indexOf(d) === -1);
                verify(service.popups.indexOf(c) !== -1);
                service.popups = [];
                wait(30);
                compare(popup.implicitHeight, 0);
                popup.maxHeight = 20;
                add(a); add(b);
                verify(popup.implicitHeight <= 20);
                verify(popup.overflowCount > 0);
                service.popups = [];
                popup.maxHeight = 500;
                const tall = notif('tall');
                let action = -1;
                tall.actions = Array.from({length: 12}, (_, index) => ({identifier: 'action-' + index, text: 'Action ' + index, invoke: () => { action = index; }}));
                add(tall);
                verify(card('tall').contentHeight > card('tall').height, 'tall cards must scroll instead of cutting off actions');
                card('tall').contentY = card('tall').contentHeight - card('tall').height;
                wait(30);
                mouseClick(card('tall'), card('tall').width / 2, card('tall').height - 38);
                compare(action, 11);
                screenshot('tall-card-actions');
                service.popups = [];
                mouseMove(window.contentItem, 400, 650);
                const old = notif('old', 10000, NotificationUrgency.Critical);
                add(old);
                wait(2200);
                const newer = notif('newer');
                add(newer);
                wait(2000);
                verify(service.popups.indexOf(old) === -1, 'critical timeout must be capped and not reset');
                verify(service.popups.indexOf(newer) !== -1);
                wait(2200);
                compare(service.popups.length, 0);
                const hidden = notif('hidden'), top = notif('top');
                popup.maxHeight = 130;
                add(hidden); add(top);
                verify(popup.overflowCount > 0);
                mouseMove(card('top'), 20, 20);
                wait(4300);
                verify(service.popups.indexOf(hidden) === -1, 'overflow must expire');
                verify(service.popups.indexOf(top) !== -1, 'hover must pause visible card');
                mouseMove(window.contentItem, 400, 650);
                wait(4200);
                compare(service.popups.length, 0);
                console.info('PASS notification popup workflow');
            }
        }
    }
}
'''.replace('MODULES', json.dumps((root / 'modules/notifications').as_uri())).replace('ARTIFACTS', json.dumps(str(artifacts))))
    result = subprocess.run(['qs', '-p', str(shell), '--no-color'], env={**os.environ, 'QT_QPA_PLATFORM': 'offscreen'}, capture_output=True, text=True, timeout=25, check=False)
    output = result.stdout + result.stderr
    (artifacts / 'report.txt').write_text(output)
    assert result.returncode == 0 and 'PASS notification popup workflow' in output, output
    assert 'FAIL' not in output and 'ERROR' not in output, output
    assert (artifacts / 'overflow.png').read_bytes().startswith(b'\x89PNG\r\n\x1a\n')
    print(f'PASS notification popup workflow; artifacts: {artifacts}')
