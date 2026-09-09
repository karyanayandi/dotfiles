import ".."
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

Scope {
    id: root

    property string wallpaper: ""
    property string status: ""
    property int pendingAcknowledgments: 0
    property bool preparingSleep: false

    signal clearInput()

    function lock() {
        session.locked = true;
        root.acknowledgeLock();
    }

    function acknowledgeLock() {
        if (!session.secure || !bridge.running)
            return ;

        while (root.pendingAcknowledgments > 0) {
            bridge.write("secured\n");
            root.pendingAcknowledgments--;
        }
    }

    function powerDisplays(on) {
        if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE"))
            Quickshell.execDetached(["hyprctl", "dispatch", "dpms", on ? "on" : "off"]);
        else if (Quickshell.env("NIRI_SOCKET"))
            Quickshell.execDetached(["niri", "msg", "action", on ? "power-on-monitors" : "power-off-monitors"]);
    }

    function applyIdleActions() {
        if (!session.secure)
            return ;

        if (displayIdle.isIdle)
            root.powerDisplays(false);

        if (suspendIdle.isIdle && !root.preparingSleep && !suspendCommand.running)
            suspendCommand.running = true;

    }

    function authenticate(response) {
        if (root.preparingSleep || !session.secure || !pam.responseRequired)
            return ;

        pam.respond(response);
        root.clearInput();
    }

    IpcHandler {
        function lock() {
            root.lock();
        }

        target: "lockscreen"
    }

    IdleMonitor {
        timeout: Config.lockTimeout
        enabled: Config.lockTimeout > 0
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                root.lock();

        }
    }

    IdleMonitor {
        id: displayIdle

        timeout: Config.lockDisplayOffTimeout
        enabled: Config.lockDisplayOffTimeout > 0
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle) {
                root.lock();
                root.applyIdleActions();
            } else {
                root.powerDisplays(true);
            }
        }
    }

    IdleMonitor {
        id: suspendIdle

        timeout: Config.lockSuspendTimeout
        enabled: Config.lockSuspendTimeout > 0
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle) {
                root.lock();
                root.applyIdleActions();
            }
        }
    }

    Process {
        id: suspendCommand

        command: ["systemctl", "suspend"]
    }

    Process {
        id: bridge

        command: ["/usr/bin/python3", Quickshell.shellPath("scripts/lock-session.py")]
        running: true
        stdinEnabled: true
        onExited: {
            console.error("Lock session bridge stopped. Sleep locking unavailable; locking now.");
            root.pendingAcknowledgments = 0;
            root.lock();
            bridgeRestart.restart();
        }

        stdout: SplitParser {
            onRead: (data) => {
                if (data === "lock" || data === "sleep") {
                    if (data === "sleep") {
                        // Invalidate authentication before releasing the sleep inhibitor.
                        root.preparingSleep = true;
                        retry.stop();
                        pam.abort();
                        root.clearInput();
                    }
                    root.pendingAcknowledgments++;
                    root.lock();
                } else if (data === "resume") {
                    root.preparingSleep = false;
                    root.powerDisplays(true);
                    if (session.secure && !pam.active)
                        pam.start();

                }
            }
        }

    }

    Timer {
        id: bridgeRestart

        interval: 5000
        onTriggered: bridge.running = true
    }

    PamContext {
        id: pam

        config: Config.lockPamService
        user: Quickshell.env("USER")
        onPamMessage: root.status = message
        onCompleted: (result) => {
            root.clearInput();
            if (root.preparingSleep)
                return ;

            if (result === PamResult.Success) {
                root.status = "";
                session.locked = false;
            } else {
                root.status = "Authentication failed. Try again.";
                retry.restart();
            }
        }
        onError: {
            root.clearInput();
            root.status = "Authentication unavailable. Check PAM configuration.";
            retry.restart();
        }
    }

    Timer {
        id: retry

        interval: 1000
        onTriggered: {
            if (session.secure && !root.preparingSleep && !pam.active)
                pam.start();

        }
    }

    WlSessionLock {
        id: session

        onSecureChanged: {
            if (secure) {
                root.acknowledgeLock();
                root.status = "";
                if (!root.preparingSleep)
                    pam.start();

                root.applyIdleActions();
            } else {
                pam.abort();
                root.clearInput();
            }
        }

        WlSessionLockSurface {
            color: Theme.colBg

            Image {
                anchors.fill: parent
                source: root.wallpaper
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.colBg
                opacity: 0.86
            }

            Column {
                anchors.centerIn: parent
                width: Math.min(360, parent.width - 48)
                spacing: 20

                SystemClock {
                    id: clock

                    precision: SystemClock.Minutes
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Theme.colFg
                    font.family: Theme.fontUi
                    font.pixelSize: 80
                    font.weight: Font.Light
                    font.letterSpacing: -2
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                    color: Theme.colFg
                    font.family: Theme.fontUi
                    font.pixelSize: 18
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: pam.user
                    color: Theme.colFg
                    font.family: Theme.fontUi
                    font.pixelSize: 20
                    font.weight: Font.Medium
                }

                TextField {
                    id: password

                    width: parent.width
                    height: 52
                    focus: true
                    enabled: pam.responseRequired && session.secure
                    echoMode: pam.responseVisible ? TextInput.Normal : TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                    placeholderText: pam.responseVisible ? "Response" : "Password"
                    color: Theme.colFg
                    placeholderTextColor: Theme.colFgDim
                    selectionColor: Theme.colSelected
                    selectedTextColor: Theme.colBg
                    font.family: Theme.fontUi
                    font.pixelSize: 16
                    leftPadding: 16
                    rightPadding: 16
                    Accessible.name: placeholderText
                    onAccepted: root.authenticate(text)
                    onEnabledChanged: {
                        if (enabled)
                            forceActiveFocus();

                    }
                    Keys.onEscapePressed: clear()

                    Connections {
                        function onClearInput() {
                            password.clear();
                        }

                        target: root
                    }

                    background: Rectangle {
                        radius: 14
                        color: Theme.colBgAlt
                        border.width: password.activeFocus ? 2 : 1
                        border.color: password.activeFocus ? Theme.colSelected : Theme.colBorderStrong
                    }

                }

                Button {
                    id: submit

                    width: parent.width
                    height: 48
                    text: "Unlock"
                    enabled: pam.responseRequired && session.secure
                    onClicked: root.authenticate(password.text)
                    Accessible.name: text

                    contentItem: Text {
                        text: submit.text
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: Theme.colBg
                        font.family: Theme.fontUi
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }

                    background: Rectangle {
                        radius: 14
                        color: Theme.colSelected
                        opacity: submit.down ? 0.7 : submit.enabled ? 1 : 0.5
                        border.width: submit.visualFocus ? 2 : 0
                        border.color: Theme.colFg
                    }

                }

                Text {
                    width: parent.width
                    text: root.status
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.colFg
                    font.family: Theme.fontUi
                    font.pixelSize: 14
                    Accessible.role: Accessible.StaticText
                    Accessible.name: text
                }

            }

        }

    }

}
