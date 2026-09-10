pragma ComponentBehavior: Bound
import ".."
import "../services" as Services
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property bool active: visible
    property string helperPath: decodeURIComponent(Qt.resolvedUrl("../scripts/codex-limits.py").toString().replace(/^file:\/\//, ""))
    property double now: Date.now() / 1000
    readonly property var limits: source.result.data || null

    spacing: 8

    Services.ControlDataSource {
        id: source

        script: root.helperPath
        active: root.active
        interval: 60000
    }

    Timer {
        interval: 1000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = Date.now() / 1000
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
        text: !root.limits ? "" : (root.limits.source === "live" ? "Live" : "Cached") + (root.now < root.limits.observedAt ? " · clock mismatch" : " · updated " + Math.floor((root.now - root.limits.observedAt) / 60) + " min ago")
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
                text: root.now >= bucket.modelData.resetsAt ? "Reset passed; current usage unknown" : "Resets " + Qt.formatDateTime(new Date(bucket.modelData.resetsAt * 1000), "MMM d, HH:mm")
                color: Theme.colFgDim
                font.family: Theme.fontUi
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }
        }
    }
}
