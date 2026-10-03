import QtQuick
import Quickshell
import "components" as Components

ShellRoot {
    id: test

    property int step: 0
    property double startedAt: 0

    function dataSource() {
        for (const child of widget.children) {
            if (child.script !== undefined)
                return child;

        }
        throw new Error("Limits data source missing");
    }

    function hasText(item, text) {
        if (item.text !== undefined && item.text.includes(text))
            return true;

        for (const child of item.children || []) {
            if (hasText(child, text))
                return true;

        }
        return false;
    }

    function check(condition, message) {
        if (!condition)
            throw new Error(message);

    }

    function setLimits(observedAt, resetsAt) {
        dataSource().result = {
            "data": {
                "source": "live",
                "observedAt": observedAt,
                "windows": [{
                    "windowMinutes": 300,
                    "usedPercent": 23,
                    "resetsAt": resetsAt
                }]
            }
        };
    }

    Components.CodexLimits {
        id: widget

        width: 420
        active: false
    }

    Timer {
        interval: 1200
        running: true
        repeat: true
        onTriggered: {
            try {
                if (test.step === 0) {
                    test.dataSource().active = false;
                    widget.active = true;
                    test.startedAt = Date.now() / 1000;
                    test.setLimits(test.startedAt + 0.5, test.startedAt + 3);
                } else if (test.step === 1) {
                    test.check(test.hasText(widget, "updated 0 min ago"), "Fresh sample age incorrect");
                    test.check(!test.hasText(widget, "clock mismatch"), "False clock mismatch");
                    test.check(test.hasText(widget, "23% used"), "Usage missing");
                    test.check(test.hasText(widget, "Resets in"), "Countdown missing");
                } else if (test.step === 4) {
                    test.check(widget.now > test.startedAt + 2, "Clock stopped");
                    test.check(test.hasText(widget, "Reset passed; current usage unknown"), "Countdown failed to expire");
                    test.check(test.hasText(widget, "23% used"), "Expired quota was fabricated");
                    test.setLimits(Date.now() / 1000 + 120, Date.now() / 1000 + 3600);
                } else if (test.step === 5) {
                    test.check(test.hasText(widget, "clock mismatch"), "Real clock skew hidden");
                    console.info("PASS: Codex usage, countdown, sample age, clock skew");
                    Qt.quit();
                }
                test.step++;
            } catch (error) {
                console.error("FAIL: " + error.message);
                Qt.quit();
            }
        }
    }

}
