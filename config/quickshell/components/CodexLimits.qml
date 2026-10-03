pragma ComponentBehavior: Bound
import ".."
import "../services" as Services
import QtQuick
import Quickshell
import QtQuick.Layouts

ColumnLayout {
    id: root

    property bool active: visible
    property string helperPath: decodeURIComponent(Qt.resolvedUrl("../scripts/codex-limits.py").toString().replace(/^file:\/\//, ""))
    readonly property double now: clock.date.getTime() / 1000
    readonly property var limits: source.result.data || null

    spacing: 8

    Services.ControlDataSource {
        id: source

        script: root.helperPath
        active: root.active
        interval: 60000
    }

    SystemClock {
        id: clock
        enabled: root.active
        precision: SystemClock.Seconds
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: "\uf121"
            color: Theme.colFg
            font.family: Theme.fontFamily
            font.pixelSize: 18
        }
        Text {
            Layout.fillWidth: true
            text: "Codex"
            color: Theme.colFg
            font.family: Theme.fontUi
            font.pixelSize: 16
        }
    }

    Text {
        Layout.fillWidth: true
        visible: !root.limits || root.limits.source !== "live"
        text: source.result.message || "Reading limits…"
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        color: Theme.colFgDim
        font.family: Theme.fontUi
        font.pixelSize: 12
    }

    Text {
        Layout.fillWidth: true
        visible: root.limits !== null
        text: !root.limits ? "" : (root.limits.source === "live" ? "Live" : "Cached") + (root.limits.observedAt - root.now > 2 ? " · clock mismatch" : " · updated " + Math.max(0, Math.floor((root.now - root.limits.observedAt) / 60)) + " min ago")
        wrapMode: Text.Wrap
        color: Theme.colFgDim
        font.family: Theme.fontUi
        font.pixelSize: 12
    }

    Repeater {
        model: root.limits ? root.limits.windows : []

        delegate: ColumnLayout {
            id: bucket

            required property var modelData
            readonly property double remainingSeconds: Math.max(0, Math.ceil(modelData.resetsAt - root.now))

            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: (bucket.modelData.windowMinutes === 10080 ? "Weekly" : bucket.modelData.windowMinutes === 300 ? "5-hour" : bucket.modelData.windowMinutes + " min") + " window · " + bucket.modelData.usedPercent + "% used"
                color: Theme.colFg
                font.family: Theme.fontUi
                font.pixelSize: 13
                wrapMode: Text.Wrap
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 5
                radius: 2
                color: Theme.colMeterBg

                Rectangle {
                    width: parent.width * bucket.modelData.usedPercent / 100
                    height: parent.height
                    radius: parent.radius
                    color: Theme.colMeterFg
                }
            }

            Text {
                Layout.fillWidth: true
                text: bucket.remainingSeconds === 0 ? "Reset passed; current usage unknown" : "Resets in " + Math.floor(bucket.remainingSeconds / 86400) + "d " + Math.floor(bucket.remainingSeconds % 86400 / 3600) + "h " + Math.floor(bucket.remainingSeconds % 3600 / 60) + "m " + bucket.remainingSeconds % 60 + "s · " + Qt.formatDateTime(new Date(bucket.modelData.resetsAt * 1000), "MMM d, HH:mm")
                color: Theme.colFgDim
                font.family: Theme.fontUi
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }
        }
    }
}
