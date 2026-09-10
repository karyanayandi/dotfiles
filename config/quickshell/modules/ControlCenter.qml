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
    readonly property string bluetoothStatus: {
        const devices = bluetooth.devices.filter(device => device.connected).map(device => device.name);
        return devices.length ? devices.join(", ") : "No device connected";
    }
    property string cpuUsage: "CPU --"
    property bool networkAvailable: false
    required property var notifs
    property date now: new Date()
    property bool opened: false
    property string ramUsage: "RAM --"

    signal launcherRequested(string mode)
    signal panelRequested(string panel)

    implicitHeight: content.implicitHeight + 40
    implicitWidth: 380
    visible: opened

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
        repeat: true
        running: win.opened
        triggeredOnStart: true

        onTriggered: systemUsage.running = true
    }
    Timer {
        interval: 1000
        repeat: true
        running: win.opened
        triggeredOnStart: true

        onTriggered: win.now = new Date()
    }
    Connections {
        function onControlCenterVisibleChanged() {
            if (win.notifs.controlCenterVisible)
                win.opened = false;
        }

        target: win.notifs
    }
    IpcHandler {
        function toggle() {
            if (win.enabled)
                win.opened = !win.opened;
        }

        target: "controls"
    }
    Process {
        command: ["sh", "-c", "command -v networkctl >/dev/null && command -v ghostty >/dev/null"]
        running: true

        onExited: exitCode => win.networkAvailable = exitCode === 0
    }
    PwObjectTracker {
        objects: [win.audio.sink]
    }
    Item {
        anchors.fill: parent

        Pane {
            id: bodyPane

            anchors.fill: parent
            anchors.margins: 20
            padding: 0

            background: Item {
            }

            ColumnLayout {
                id: content

                spacing: 14
                width: bodyPane.availableWidth

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        color: Theme.colFg
                        font.family: Theme.fontFamily
                        font.pixelSize: 22
                        text: "\uf1de"
                    }
                    Text {
                        Layout.fillWidth: true
                        color: Theme.colFg
                        font.family: Theme.fontUi
                        font.letterSpacing: -0.4
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        text: "Control center"
                    }
                    SettingButton {
                        id: closeButton

                        Accessible.name: "Close control center"
                        Layout.fillWidth: false
                        Layout.preferredWidth: 40
                        glyph: "\uf00d"
                        implicitHeight: 40

                        onClicked: win.opened = false
                    }
                }
                Text {
                    Layout.fillWidth: true
                    color: Theme.colFgDim
                    font.family: Theme.fontUi
                    font.pixelSize: 13
                    text: Qt.formatDateTime(win.now, "HH:mm · dddd, dd MMMM")
                    wrapMode: Text.WordWrap
                }
                GridLayout {
                    Layout.fillWidth: true
                    columnSpacing: 10
                    columns: 2
                    rowSpacing: 10

                    SettingButton {
                        enabled: win.networkAvailable
                        glyph: "\uf1eb"
                        text: "Network"

                        onClicked: {
                            Quickshell.execDetached(["ghostty", "--wait-after-command=true", "-e", "networkctl", "--no-pager", "status", "--all"]);
                            win.opened = false;
                        }
                    }
                    SettingButton {
                        detail: win.bluetoothStatus
                        glyph: "\uf293"
                        text: "Bluetooth"

                        onClicked: {
                            win.launcherRequested("bluetooth");
                        }
                    }
                    SettingButton {
                        checkable: true
                        checked: win.notifs.doNotDisturb
                        glyph: "\uf1f6"
                        text: "Do not disturb"

                        onClicked: win.notifs.toggleDnd()
                    }
                    SettingButton {
                        checkable: true
                        checked: win.audio.muted
                        enabled: !!win.audio.sink?.audio
                        glyph: win.audio.muted ? "\uf026" : "\uf028"
                        text: win.audio.muted ? "Muted" : "Sound"

                        onClicked: win.audio.volMuteToggle()
                    }
                }
                SettingButton {
                    detail: win.cpuUsage + " · " + win.ramUsage
                    glyph: "\uf085"
                    text: "System monitor"

                    onClicked: {
                        Quickshell.execDetached(["ghostty", "-e", "btm"]);
                        win.opened = false;
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    color: Theme.colBgAlt
                    implicitHeight: sound.implicitHeight + 28
                    radius: 16

                    ColumnLayout {
                        id: sound

                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                Layout.fillWidth: true
                                color: Theme.colFg
                                font.family: Theme.fontUi
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                text: "Volume"
                            }
                            Text {
                                color: Theme.colFgDim
                                font.family: Theme.fontUi
                                font.pixelSize: 13
                                text: Math.round(volume.value * 100) + "%"
                            }
                        }
                        Slider {
                            id: volume

                            Accessible.name: "Output volume"
                            Layout.fillWidth: true
                            enabled: !!win.audio.sink?.audio
                            from: 0
                            implicitHeight: 36
                            stepSize: 0.01
                            to: 1

                            background: Rectangle {
                                color: Theme.colMeterBg
                                height: 6
                                radius: 3
                                width: volume.availableWidth
                                x: volume.leftPadding
                                y: volume.topPadding + volume.availableHeight / 2 - height / 2

                                Rectangle {
                                    color: Theme.colMeterFg
                                    height: parent.height
                                    radius: 3
                                    width: volume.visualPosition * parent.width
                                }
                            }
                            handle: Rectangle {
                                border.color: Theme.g7
                                border.width: volume.visualFocus ? 3 : 0
                                color: volume.pressed ? Theme.g6 : Theme.colFg
                                implicitHeight: 22
                                implicitWidth: 22
                                radius: 11
                                x: volume.leftPadding + volume.visualPosition * (volume.availableWidth - width)
                                y: volume.topPadding + volume.availableHeight / 2 - height / 2
                            }

                            onMoved: win.audio.sink.audio.volume = value

                            Binding {
                                property: "value"
                                target: volume
                                value: win.audio.vol
                                when: !volume.pressed
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            color: Theme.colFgDim
                            elide: Text.ElideRight
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                            text: win.audio.sink ? win.audio.sink.description : "No audio output available"
                        }
                    }
                }
                SettingButton {
                    glyph: "\uf1de"
                    text: "Audio mixer"

                    onClicked: win.panelRequested("audio")
                }
                GridLayout {
                    Layout.fillWidth: true
                    columnSpacing: 10
                    columns: 2
                    rowSpacing: 10

                    SettingButton {
                        glyph: "\uf030"
                        text: "Capture"

                        onClicked: win.panelRequested("capture")
                    }
                    SettingButton {
                        glyph: "\uf001"
                        text: "Media"

                        onClicked: win.panelRequested("media")
                    }
                    SettingButton {
                        glyph: "\uf108"
                        text: "Displays"

                        onClicked: win.panelRequested("displays")
                    }
                    SettingButton {
                        glyph: "\uf073"
                        text: "Calendar"

                        onClicked: win.panelRequested("calendar")
                    }
                    SettingButton {
                        glyph: "\uf1fb"
                        text: "Color picker"

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

    component SettingButton: Button {
        id: button

        property string detail: ""
        property string glyph: ""

        Accessible.name: detail ? text + ", " + detail : text
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        font.family: Theme.fontUi
        font.pixelSize: 14
        implicitHeight: Math.max(52, contentItem.implicitHeight + 24)

        background: Rectangle {
            border.color: button.visualFocus ? Theme.colFg : Theme.colBorder
            border.width: button.visualFocus ? 2 : 1
            color: button.down ? Theme.g2 : button.checked ? Theme.colActionBg : button.hovered ? Theme.g2 : Theme.colBgAlt
            radius: 14
        }
        contentItem: ColumnLayout {
            spacing: 4

            Extras.IconLabel {
                Layout.fillWidth: true
                color: button.enabled ? Theme.colFg : Theme.colFgDim
                font: button.font
                icon: button.glyph
                text: button.text
                wrap: true
            }
            Text {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: Theme.colFgDim
                font.family: Theme.fontUi
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                text: button.detail
                visible: button.detail !== ""
                wrapMode: Text.Wrap
            }
        }
    }
}
