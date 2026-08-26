import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
    id: root

    property color colFg: "#d4be98"
    property color colBg: "#1d2021"
    property color colAccent: "#45403d"
    property color colUrgent: "#fb4934"
    property string fontFamily: "JetBrainsMono NF"
    property int fontSize: 15

    property string submap: ""
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "submap") root.submap = event.data
        }
    }

    // Audio — Pipewire as source of truth, wpctl for control + OSD
    property var sink: Pipewire.defaultAudioSink
    property real pollVol: 0.3
    property bool pollMuted: false
    property real prevPollVol: 0.3
    property bool prevPollMuted: false

    // OSD state
    property bool osdVisible: false
    property string osdKind: "sink"
    property string osdIcon: ""
    property int osdPercent: 30
    Timer {
        id: osdHide
        interval: 1800
        onTriggered: root.osdVisible = false
    }
    function showOsd(kind) {
        root.osdKind = kind || "sink"
        var muted = root.pollMuted
        var v = root.pollVol
        if (root.sink && root.sink.audio && root.sink.audio.muted) muted = true
        root.osdPercent = Math.round(v * 100)
        if (kind === "mic") {
            root.osdIcon = muted ? "" : ""
        } else {
            if (muted) root.osdIcon = "󰸈"
            else if (v <= 0.01) root.osdIcon = ""
            else if (v < 0.34) root.osdIcon = ""
            else if (v < 0.67) root.osdIcon = "󰕾"
            else root.osdIcon = ""
        }
        root.osdVisible = true
        osdHide.restart()
    }

    Process { id: volRaiseProc;  command: ["wpctl","set-volume","@DEFAULT_AUDIO_SINK@","5%+","-l","1.0"] }
    Process { id: volLowerProc;  command: ["wpctl","set-volume","@DEFAULT_AUDIO_SINK@","5%-"] }
    Process { id: volMuteProc;   command: ["wpctl","set-mute","@DEFAULT_AUDIO_SINK@","toggle"] }
    Process { id: micMuteProc;   command: ["wpctl","set-mute","@DEFAULT_AUDIO_SOURCE@","toggle"] }
    Process {
        id: micPoll
        command: ["sh","-c","pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -q 'yes' && echo mute || echo unmute"]
        stdout: SplitParser {
            onRead: data => {
                data = data.trim()
                if (data === "mute") root.pollMuted = true
            }
        }
    }

    Process {
        id: volPoll
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | cut -d' ' -f2; pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q 'yes' && echo mute || echo unmute"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                data = data.trim()
                if (data === "mute") root.pollMuted = true
                else if (data === "unmute") root.pollMuted = false
                else {
                    var v = parseFloat(data)
                    if (!isNaN(v)) root.pollVol = v
                }
                if (Math.abs(root.pollVol - root.prevPollVol) > 0.005 || root.pollMuted !== root.prevPollMuted) {
                    root.prevPollVol = root.pollVol
                    root.prevPollMuted = root.pollMuted
                    if (root.osdVisible || Math.abs(root.pollVol - 0.3) > 0.001) root.showOsd("sink")
                }
            }
        }
    }
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: volPoll.running = true
        Component.onCompleted: volPoll.running = true
    }

    function volRaise() { volRaiseProc.running = true; volPoll.running = true; showOsd("sink"); Qt.callLater(() => volPoll.running = true) }
    function volLower() { volLowerProc.running = true; volPoll.running = true; showOsd("sink"); Qt.callLater(() => volPoll.running = true) }
    function volMuteToggle() { volMuteProc.running = true; showOsd("sink"); Qt.callLater(() => volPoll.running = true) }
    function micMuteToggle() { micMuteProc.running = true; showOsd("mic") }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        function onVolumeChanged() {
            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio)
                root.pollVol = Pipewire.defaultAudioSink.audio.volume
        }
        function onMutedChanged() {
            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio)
                root.pollMuted = Pipewire.defaultAudioSink.audio.muted
        }
    }

    property bool notifDnd: false
    property bool notifHasDot: false
    Process {
        id: notifProc
        command: ["sh", "-c", "swaync-client -swb 2>/dev/null || echo '{\"count\":0}'"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                try {
                    const j = JSON.parse(data.trim())
                    const alt = (j.alt || "").toString().toLowerCase()
                    const clazz = (j.class || "").toString().toLowerCase()
                    const text = (j.text || "").toString()
                    let count = 0
                    if (j.count !== undefined) count = parseInt(j.count) || 0
                    else if (j.notification_count !== undefined) count = parseInt(j.notification_count) || 0
                    else count = parseInt(text) || 0
                    const hasNotif = count > 0 || alt.indexOf("notification") !== -1 || clazz.indexOf("notification") !== -1
                    const isDnd = !!(j.dnd || j.doNotDisturb || j.inhibited || alt.indexOf("dnd") !== -1 || clazz.indexOf("dnd") !== -1)
                    root.notifHasDot = hasNotif
                    root.notifDnd = isDnd
                } catch(e) {}
            }
        }
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: notifProc.running = true
        Component.onCompleted: notifProc.running = true
    }
    Process { id: notifClickProc }
    Process { id: notifRightProc }

    // ── Bar ──────────────────────────────────────────────
    PanelWindow {
        id: barWin
        anchors { bottom: true; left: true; right: true }
        implicitHeight: 48
        exclusiveZone: 48
        color: "transparent"
        WlrLayershell.namespace: "quickshell"
        WlrLayershell.layer: WlrLayer.Top

    Rectangle {
        id: bar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        implicitWidth: Math.max(400, Math.min(900, barContent.implicitWidth + 32))
        width: implicitWidth
        height: 38
        radius: 10
        color: root.colBg

        RowLayout {
            id: barContent
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            spacing: 4

            RowLayout {
                Layout.leftMargin: 15
                Layout.rightMargin: 15
                spacing: 0
                Layout.alignment: Qt.AlignVCenter
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: wheel => {
                        if (wheel.angleDelta.y > 0) Hyprland.dispatch("workspace e-1")
                        else if (wheel.angleDelta.y < 0) Hyprland.dispatch("workspace e+1")
                    }
                }
                Repeater {
                    model: Hyprland.workspaces
                    delegate: Rectangle {
                        required property var modelData
                        property bool isActive: modelData.active === true
                        property bool isFocused: modelData.focused === true
                        property bool isUrgent: modelData.urgent === true
                        Layout.preferredHeight: 30
                        Layout.preferredWidth: wsText.implicitWidth + 20
                        color: isUrgent ? root.colUrgent : (wsMouse.containsMouse ? root.colAccent : "transparent")
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: isFocused || isActive ? 3 : 0
                            color: root.colFg
                            visible: isFocused || isActive
                        }
                        Text {
                            id: wsText
                            anchors.centerIn: parent
                            text: modelData.name
                            color: root.colFg
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize
                        }
                        MouseArea {
                            id: wsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.activate()
                        }
                    }
                }
            }

            Text {
                visible: root.submap !== "" && root.submap !== "default"
                text: root.submap
                color: root.colFg
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                font.italic: true
                leftPadding: 10
                rightPadding: 10
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Text {
                text: ""
                color: root.colFg
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                Layout.alignment: Qt.AlignVCenter
                leftPadding: 10
                rightPadding: 10
                topPadding: 0
                bottomPadding: 0
                MouseArea {
                    id: diskMouse
                    hoverEnabled: true
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { let p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent); p.command = ["ghostty","-e","yazi"]; p.running = true }
                }
            }

            Text {
                text: "󰍛"
                color: root.colFg
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                Layout.alignment: Qt.AlignVCenter
                leftPadding: 10
                rightPadding: 10
                topPadding: 0
                bottomPadding: 0
                MouseArea {
                    id: memMouse
                    hoverEnabled: true
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { let p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent); p.command = ["ghostty","-e","btm"]; p.running = true }
                }
            }

            Text {
                text: ""
                color: root.colFg
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                Layout.alignment: Qt.AlignVCenter
                leftPadding: 10
                rightPadding: 10
                topPadding: 0
                bottomPadding: 0
                MouseArea {
                    id: btMouse
                    hoverEnabled: true
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { let p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent); p.command = ["ghostty","-e","bluetui"]; p.running = true }
                }
            }

            Text {
                id: volText
                text: {
                    var sink = Pipewire.defaultAudioSink
                    var muted = root.pollMuted
                    var v = root.pollVol
                    if (sink && sink.audio) {
                        if (sink.audio.muted) muted = true
                        if (sink.audio.volume !== undefined) v = sink.audio.volume
                    }
                    if (muted) return "󰸈"
                    var d = sink && sink.description ? sink.description : ""
                    var n = sink && sink.properties ? (sink.properties["node.name"] || "") : ""
                    if (d.toLowerCase().indexOf("headphone") !== -1 || n.toLowerCase().indexOf("headphone") !== -1) return "󰋋"
                    if (v <= 0.01) return ""
                    if (v < 0.2) return ""
                    if (v < 0.4) return ""
                    if (v < 0.8) return "󰕾"
                    return ""
                }
                color: root.colFg
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                Layout.alignment: Qt.AlignVCenter
                leftPadding: 10
                rightPadding: 10
                topPadding: 0
                bottomPadding: 0
                MouseArea {
                    id: volMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) root.volMuteToggle()
                        else { let p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent); p.command = ["ghostty","-e","wiremix"]; p.running = true }
                    }
                    onWheel: wheel => {
                        if (wheel.angleDelta.y > 0) root.volRaise()
                        else if (wheel.angleDelta.y < 0) root.volLower()
                    }
                }
            }

            Item {
                Layout.preferredHeight: 30
                Layout.preferredWidth: notifText.implicitWidth + 20
                Layout.rightMargin: 20
                Text {
                    id: notifText
                    anchors.centerIn: parent
                    text: root.notifDnd ? "" : ""
                    color: root.colFg
                    font.family: root.fontFamily
                    font.pixelSize: root.fontSize
                }
                Text {
                    visible: root.notifHasDot
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 4
                    anchors.rightMargin: 2
                    text: ""
                    color: root.colUrgent
                    font.family: root.fontFamily
                    font.pixelSize: 8
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) { notifRightProc.command = ["swaync-client","-d","-sw"]; notifRightProc.running = true }
                        else { notifClickProc.command = ["swaync-client","-t","-sw"]; notifClickProc.running = true }
                    }
                }
            }

            Text {
                id: clock
                color: root.colFg
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 10
                leftPadding: 10
                rightPadding: 10
                topPadding: 0
                bottomPadding: 0
                text: Qt.formatDateTime(new Date(), "HH:mm")
                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm")
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
        }
    }
    }

    // ── Volume / Mic OSD (replaces swayosd) ──────────────
    PanelWindow {
        id: osdWin
        visible: root.osdVisible
        anchors.top: true
        margins.top: 80
        implicitWidth: 380
        implicitHeight: 56
        exclusiveZone: 0
        color: "transparent"
        mask: Region { item: osdBg }
        WlrLayershell.namespace: "quickshell-osd"
        WlrLayershell.layer: WlrLayer.Overlay

        Rectangle {
            id: osdBg
            anchors.centerIn: parent
            width: 360
            height: 44
            radius: 10
            color: root.colBg
            border.color: root.colAccent
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 12

                Text {
                    text: root.osdIcon
                    color: root.colFg
                    font.family: root.fontFamily
                    font.pixelSize: 18
                    Layout.alignment: Qt.AlignVCenter
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    Layout.alignment: Qt.AlignVCenter
                    radius: 4
                    color: root.colAccent
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.min(1, root.osdPercent / 100)
                        radius: 4
                        color: root.pollMuted && root.osdKind === "sink" ? root.colUrgent : root.colFg
                        Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }
                }
                Text {
                    text: root.osdKind === "mic" ? (root.pollMuted ? "muted" : "mic") : (root.pollMuted ? "muted" : root.osdPercent + "%")
                    color: root.colFg
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 52
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
