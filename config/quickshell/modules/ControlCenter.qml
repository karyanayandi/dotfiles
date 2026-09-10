import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../services" as Services
import "../components" as Extras
import ".."

Item {
    id: win

    required property var audio
    required property var notifs
    property bool opened: false
    property bool networkAvailable: false
    property date now: new Date()
    property string cpuUsage: "CPU --"
    property string ramUsage: "RAM --"
    readonly property string bluetoothStatus: {
        const devices = bluetooth.devices.filter(device => device.connected).map(device => device.name);
        return devices.length ? devices.join(", ") : "No device connected";
    }

    Services.BluetoothService {
        id: bluetooth
    }

    Process {
        id: systemUsage
        command: ["sh", "-c", "{ awk '/^cpu / { idle=$5+$6; total=0; for (i=2; i<=NF; i++) total+=$i; print total, idle }' /proc/stat; sleep 0.1; awk '/^cpu / { idle=$5+$6; total=0; for (i=2; i<=NF; i++) total+=$i; print total, idle }' /proc/stat; } | awk 'NR==1 { total=$1; idle=$2; next } { printf \"CPU %d%%\\n\", 100 - 100 * ($2-idle) / ($1-total) }'; free -h | awk '/^Mem:/ { print \"RAM \" $3 \"/\" $2 }'"]
        stdout: SplitParser {
            onRead: data => {
                data = data.trim();
                if (data.startsWith("CPU"))
                    win.cpuUsage = data;
                else if (data.startsWith("RAM"))
                    win.ramUsage = data;
            }
        }
    }
    Timer {
        interval: 2000
        running: win.opened
        repeat: true
        triggeredOnStart: true
        onTriggered: systemUsage.running = true
    }

    Timer {
        interval: 1000
        running: win.opened
        repeat: true
        triggeredOnStart: true
        onTriggered: win.now = new Date()
    }
    signal launcherRequested(string mode)
    signal panelRequested(string panel)

    visible: opened
    implicitWidth: 380
    implicitHeight: content.implicitHeight + 40

    Keys.onEscapePressed: win.opened = false

    onOpenedChanged: {
        if (opened) {
            notifs.controlCenterVisible = false;
            Qt.callLater(() => {
                if (win.enabled && win.opened)
                    closeButton.forceActiveFocus();
            });
        }
    }

    Connections {
        target: win.notifs
        function onControlCenterVisibleChanged() {
            if (win.notifs.controlCenterVisible)
                win.opened = false;
        }
    }

    IpcHandler {
        target: "controls"
        function toggle() {
            if (win.enabled)
                win.opened = !win.opened;
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v networkctl >/dev/null && command -v ghostty >/dev/null"]
        onExited: exitCode => win.networkAvailable = exitCode === 0
    }

    PwObjectTracker {
        objects: [win.audio.sink]
    }

    component SettingButton: Button {
        id: button
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        property string detail: ""
        property string glyph: ""
        implicitHeight: Math.max(52, contentItem.implicitHeight + 24)
        font.family: Theme.fontUi
        font.pixelSize: 14
        Accessible.name: detail ? text + ", " + detail : text
        background: Rectangle {
            radius: 14
            color: button.down ? Theme.g2 : button.checked ? Theme.colActionBg : button.hovered ? Theme.g2 : Theme.colBgAlt
            border.width: button.visualFocus ? 2 : 1
            border.color: button.visualFocus ? Theme.colFg : Theme.colBorder
        }
        contentItem: ColumnLayout {
            spacing: 4
            Extras.IconLabel {
                Layout.fillWidth: true
                icon: button.glyph
                text: button.text
                font: button.font
                color: button.enabled ? Theme.colFg : Theme.colFgDim
                wrap: true
            }
            Text {
                Layout.fillWidth: true
                visible: button.detail !== ""
                text: button.detail
                Layout.preferredWidth: 0
                font.family: Theme.fontUi
                font.pixelSize: 12
                color: Theme.colFgDim
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
    }

    Item {
        anchors.fill: parent

        ScrollView {
            id: scroll
            anchors.fill: parent
            anchors.margins: 20
            contentWidth: availableWidth
            clip: true

            ColumnLayout {
                id: content
                width: scroll.availableWidth
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "\uf1de"
                        color: Theme.colFg
                        font.family: Theme.fontFamily
                        font.pixelSize: 22
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Control center"
                        color: Theme.colFg
                        font.family: Theme.fontUi
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        font.letterSpacing: -0.4
                    }
                    SettingButton {
                        id: closeButton
                        Layout.fillWidth: false
                        Layout.preferredWidth: 40
                        implicitHeight: 40
                        glyph: "\uf00d"
                        Accessible.name: "Close control center"
                        onClicked: win.opened = false
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: Qt.formatDateTime(win.now, "HH:mm · dddd, dd MMMM")
                    wrapMode: Text.WordWrap
                    color: Theme.colFgDim
                    font.family: Theme.fontUi
                    font.pixelSize: 13
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 10

                    SettingButton {
                        text: "Network"
                        glyph: "\uf1eb"
                        enabled: win.networkAvailable
                        onClicked: {
                            Quickshell.execDetached(["ghostty", "--wait-after-command=true", "-e", "networkctl", "--no-pager", "status", "--all"]);
                            win.opened = false;
                        }
                    }
                    SettingButton {
                        text: "Bluetooth"
                        glyph: "\uf293"
                        detail: win.bluetoothStatus
                        onClicked: {
                            win.launcherRequested("bluetooth");
                        }
                    }
                    SettingButton {
                        text: "Do not disturb"
                        glyph: "\uf1f6"
                        checkable: true
                        checked: win.notifs.doNotDisturb
                        onClicked: win.notifs.toggleDnd()
                    }
                    SettingButton {
                        text: win.audio.muted ? "Muted" : "Sound"
                        glyph: win.audio.muted ? "\uf026" : "\uf028"
                        enabled: !!win.audio.sink?.audio
                        checkable: true
                        checked: win.audio.muted
                        onClicked: win.audio.volMuteToggle()
                    }
                }

                SettingButton {
                    text: "System monitor"
                    glyph: "\uf085"
                    detail: win.cpuUsage + " · " + win.ramUsage
                    onClicked: {
                        Quickshell.execDetached(["ghostty", "-e", "btm"]);
                        win.opened = false;
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: sound.implicitHeight + 28
                    radius: 16
                    color: Theme.colBgAlt

                    ColumnLayout {
                        id: sound
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: "Volume"
                                color: Theme.colFg
                                font.family: Theme.fontUi
                                font.pixelSize: 14
                                font.weight: Font.Medium
                            }
                            Text {
                                text: Math.round(volume.value * 100) + "%"
                                color: Theme.colFgDim
                                font.family: Theme.fontUi
                                font.pixelSize: 13
                            }
                        }
                        Slider {
                            id: volume
                            implicitHeight: 36
                            Layout.fillWidth: true
                            from: 0
                            to: 1
                            stepSize: 0.01
                            enabled: !!win.audio.sink?.audio
                            Accessible.name: "Output volume"
                            onMoved: win.audio.sink.audio.volume = value
                            Binding {
                                target: volume
                                property: "value"
                                value: win.audio.vol
                                when: !volume.pressed
                            }
                            background: Rectangle {
                                x: volume.leftPadding
                                y: volume.topPadding + volume.availableHeight / 2 - height / 2
                                width: volume.availableWidth
                                height: 6
                                radius: 3
                                color: Theme.colMeterBg
                                Rectangle {
                                    width: volume.visualPosition * parent.width
                                    height: parent.height
                                    radius: 3
                                    color: Theme.colMeterFg
                                }
                            }
                            handle: Rectangle {
                                x: volume.leftPadding + volume.visualPosition * (volume.availableWidth - width)
                                y: volume.topPadding + volume.availableHeight / 2 - height / 2
                                implicitWidth: 22
                                implicitHeight: 22
                                radius: 11
                                color: volume.pressed ? Theme.g6 : Theme.colFg
                                border.width: volume.visualFocus ? 3 : 0
                                border.color: Theme.g7
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: win.audio.sink ? win.audio.sink.description : "No audio output available"
                            elide: Text.ElideRight
                            color: Theme.colFgDim
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                        }
                    }
                }

                SettingButton {
                    text: "Audio mixer"
                    glyph: "\uf1de"
                    onClicked: win.panelRequested("audio")
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 10

                    SettingButton {
                        text: "Capture"
                        glyph: "\uf030"
                        onClicked: win.panelRequested("capture")
                    }
                    SettingButton {
                        text: "Media"
                        glyph: "\uf001"
                        onClicked: win.panelRequested("media")
                    }
                    SettingButton {
                        text: "Displays"
                        glyph: "\uf108"
                        onClicked: win.panelRequested("displays")
                    }
                    SettingButton {
                        text: "Calendar"
                        glyph: "\uf073"
                        onClicked: win.panelRequested("calendar")
                    }
                    SettingButton {
                        text: "Color picker"
                        glyph: "\uf1fb"
                        onClicked: win.panelRequested("color")
                    }
                }

                Extras.RemovableDrives {
                    Layout.fillWidth: true
                    active: win.opened
                }
                Extras.CodexLimits {
                    Layout.fillWidth: true
                    active: win.opened
                }
            }
        }
    }
}
