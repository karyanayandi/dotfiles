import QtQuick
import QtTest

TestCase {
    name: "CaptureFeedback"

    CaptureFeedback {
        id: feedback
        width: 420
    }

    function test_autoDismiss() {
        feedback.show("Copied to clipboard", false);
        compare(feedback.shown, true);
        tryCompare(feedback, "shown", false, 4000);
        feedback.show("Copy failed", true);
        compare(feedback.failed, true);
        tryCompare(feedback, "shown", false, 7500);
    }

    function test_replacement() {
        feedback.show("Copy failed", true);
        feedback.show("Copied to clipboard", false);
        compare(feedback.message, "Copied to clipboard");
        compare(feedback.failed, false);
        compare(feedback.shown, true);
        tryCompare(feedback, "shown", false, 4000);
    }
}
