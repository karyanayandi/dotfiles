import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import ".."

Item {
    id: win

    required property var audio
    required property var notifs
    property bool opened: false
    property bool networkAvailable: false
    signal launcherRequested(string mode)

    visible: opened
    implicitWidth: 380
    implicitHeight: content.implicitHeight + 40

    Keys.onEscapePressed: win.opened = false

    onOpenedChanged: {
        if (opened) {
            notifs.controlCenterVisible = false;
            Qt.callLater(() => closeButton.forceActiveFocus());
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
        implicitHeight: 52
        font.family: Theme.fontUi
        font.pixelSize: 14
        Accessible.name: text
        background: Rectangle {
            radius: 14
            color: button.down ? Theme.g2 : button.checked ? Theme.colActionBg : button.hovered ? Theme.g2 : Theme.colBgAlt
            border.width: button.visualFocus ? 2 : 1
            border.color: button.visualFocus ? Theme.colFg : Theme.colBorder
        }
        contentItem: Text {
            text: button.text
            font: button.font
            color: button.enabled ? Theme.colFg : Theme.colFgDim
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
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
                        text: "×"
                        Accessible.name: "Close control center"
                        onClicked: win.opened = false
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 10

                    SettingButton {
                        text: win.networkAvailable ? "Network status ↗" : "Network · Unavailable"
                        enabled: win.networkAvailable
                        onClicked: {
                            Quickshell.execDetached(["ghostty", "--wait-after-command=true", "-e", "networkctl", "--no-pager", "status", "--all"]);
                            win.opened = false;
                        }
                    }
                    SettingButton {
                        text: "Bluetooth settings ↗"
                        onClicked: {
                            win.launcherRequested("bluetooth");
                        }
                    }
                    SettingButton {
                        text: win.notifs.doNotDisturb ? "Do not disturb · On" : "Do not disturb · Off"
                        checkable: true
                        checked: win.notifs.doNotDisturb
                        onClicked: win.notifs.toggleDnd()
                    }
                    SettingButton {
                        text: win.audio.muted ? "Sound · Muted" : "Sound · On"
                        enabled: !!win.audio.sink?.audio
                        checkable: true
                        checked: win.audio.muted
                        onClicked: win.audio.volMuteToggle()
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
                                width: 22
                                height: 22
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
                    text: "Audio devices and mixer ↗"
                    onClicked: {
                        Quickshell.execDetached(["ghostty", "-e", "wiremix"]);
                        win.opened = false;
                    }
                }
            }
        }
    }
}
