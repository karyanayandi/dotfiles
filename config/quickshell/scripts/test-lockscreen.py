#!/usr/bin/python3
"""Run actual lockscreen JavaScript in QtTest, without locking the desktop.

Requires Qt 6 qmltestrunner and QtTest QML. Only handlers are extracted; compositor,
PAM and process objects are test doubles. This is not a PAM/compositor test.
"""

import os
import re
import subprocess
import tempfile
from pathlib import Path

source = (Path(__file__).resolve().parents[1] / "modules/LockScreen.qml").read_text()


def extract(header, indent):
    match = re.search(
        rf"^{' ' * indent}{re.escape(header)}(.*?)^{' ' * indent}\}}",
        source,
        re.MULTILINE | re.DOTALL,
    )
    if match is None:
        raise AssertionError(f"QML handler missing or reformatted: {header}")
    return match[1]


methods = "\n".join(
    f"function {name}({args}) {{{extract(f'function {name}({args}) {{', 4)}}}"
    for name, args in (
        ("lock", ""),
        ("acknowledgeLock", ""),
        ("authenticate", "response"),
    )
)
read_handler = extract("onRead: (data) => {", 12)
completed_handler = extract("onCompleted: (result) => {", 8)

qml = """
import QtQuick
import QtTest

TestCase {
    id: root
    name: "LockscreenSleepRace"
    property bool preparingSleep: false
    property int pendingAcknowledgments: 0
    property string status: ""
    property var events: []
    property var session: ({ secure: true, locked: true })
    property var bridge: ({ running: true, write: function(line) { root.events.push(line); } })
    property var retry: ({ stop: function() {}, restart: function() {} })
    property var pam: ({
        active: true,
        responseRequired: true,
        abort: function() { this.active = false; root.events.push("abort"); },
        start: function() { this.active = true; root.events.push("start"); },
        respond: function(response) { root.events.push("respond"); }
    })
    // Matches only the enum name used by the extracted production handler.
    QtObject { id: results; readonly property int success: 0 }
    function clearInput() { events.push("clear"); }
    function powerDisplays(on) { events.push("display"); }
    __METHODS__
    function receive(data) { __READ__ }
    function complete(result) { __COMPLETE__ }

    function init() {
        preparingSleep = false;
        pendingAcknowledgments = 0;
        session.secure = true;
        session.locked = true;
        pam.active = true;
        events = [];
    }
    function test_sleep_blocks_late_success() {
        receive("sleep");
        compare(events.indexOf("abort") < events.indexOf("secured\\n"), true);
        compare(preparingSleep, true);
        complete(results.success); // Result arrives after inhibitor release.
        compare(session.locked, true);
        authenticate("ignored");
        compare(events.indexOf("respond"), -1);
        receive("resume");
        compare(session.locked, true);
        compare(events.indexOf("start") >= 0, true);
        complete(results.success); // New authentication after resume.
        compare(session.locked, false);
    }
    function test_waits_for_compositor() {
        session.secure = false;
        receive("sleep");
        compare(events.indexOf("secured\\n"), -1);
        compare(pendingAcknowledgments, 1);
        session.secure = true;
        acknowledgeLock();
        compare(events.filter(x => x === "secured\\n").length, 1);
        acknowledgeLock();
        compare(events.filter(x => x === "secured\\n").length, 1);
    }
    function test_acknowledges_each_request_only() {
        lock(); // Manual IPC does not owe a bridge acknowledgment.
        compare(events.length, 0);
        receive("lock");
        receive("sleep");
        compare(events.filter(x => x === "secured\\n").length, 2);
        compare(pendingAcknowledgments, 0);
        receive("unlock"); // Untrusted unlock command is ignored.
        compare(session.locked, true);
    }
    function test_failed_auth_stays_locked() {
        complete(1);
        compare(session.locked, true);
    }
}
"""
qml = (
    qml.replace("__METHODS__", methods)
    .replace("__READ__", read_handler)
    .replace(
        "__COMPLETE__",
        completed_handler.replace("PamResult.Success", "results.success"),
    )
)
with tempfile.TemporaryDirectory(prefix="lockscreen-test-") as directory:
    test = Path(directory) / "tst_lockscreen.qml"
    test.write_text(qml)
    subprocess.run(
        ["/usr/lib/qt6/bin/qmltestrunner", "-input", str(test)],
        env={**os.environ, "QT_QPA_PLATFORM": "offscreen"},
        check=True,
    )
