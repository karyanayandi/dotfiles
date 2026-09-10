import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."
import "displaypolkit" as SystemPanels
import "../services" as Services

PanelWindow {
    id: win

    required property var audio
    required property var notifs
    required property var wallpaper
    property bool polkitAgentEnabled: Config.polkitAgentEnabled
    property bool captureHidden: false
    property string captureAction: ""
    property var captureOptions: ({})

    visible: !captureHidden

    signal panelRequested(string panel)

    readonly property var panels: ({
            audio: mixer,
            media: media,
            calendar: calendar,
            displays: displays,
            capture: capture,
            color: colorPicker
        })
    readonly property string extraView: Object.keys(panels).find(name => panels[name].opened) || ""
    readonly property bool interactive: auth.active || launcher.visibleLauncher || controls.opened || notifs.controlCenterVisible || extraView !== ""
    readonly property string view: auth.active ? "polkit" : extraView || (launcher.visibleLauncher ? "launcher" : controls.opened ? "controls" : notifs.controlCenterVisible ? "notifications" : audio.osdVisible ? "volume" : "")
    readonly property var activePanel: view === "polkit" ? auth : panels[view] || (view === "launcher" ? launcher : view === "controls" ? controls : view === "notifications" ? center : view === "volume" ? osd : null)
    readonly property real panelHeight: Math.max(0, Math.min(height - Config.barExclusiveZone - 16, activePanel ? activePanel.implicitHeight : 0))

    function openPanel(name) {
        if (auth.active)
            return;
        const panel = panels[name];
        if (panel) {
            if (name === "capture" && captureService.recording)
                capture.video = true;
            panel.opened = true;
        }
    }

    onPanelRequested: name => openPanel(name)

    function startCapture(action, options) {
        if (auth.active || !captureService.ready || captureService.busy)
            return;
        activate("");
        captureAction = action;
        captureOptions = options;
        captureHidden = true;
        captureDelay.restart();
    }

    Timer {
        id: captureDelay
        // Let the compositor unmap the entire island before sampling any pixels.
        interval: 80
        onTriggered: {
            if (auth.active || !captureService.request(win.captureAction, win.captureOptions))
                win.captureHidden = false;
        }
    }

    Services.CaptureService {
        id: captureService
        onReveal: panel => {
            win.captureHidden = false;
            win.openPanel(panel);
        }
        onRecordingChanged: {
            if (recording)
                win.captureHidden = false;
        }
    }

    IpcHandler {
        target: "capture"
        function open(mode: string) {
            if (!auth.active) {
                capture.open(mode);
                if (!captureService.busy)
                    captureService.request("capabilities");
            }
        }
        function stop() {
            captureDelay.stop();
            win.captureHidden = false;
            captureService.stop();
        }
        function status(): string {
            return JSON.stringify({
                ready: captureService.ready,
                busy: captureService.busy,
                recording: captureService.recording,
                elapsed: captureService.elapsed,
                message: captureService.message
            });
        }
        function close() {
            capture.opened = false;
        }
    }

    IpcHandler {
        target: "colorPicker"
        function open() {
            win.openPanel("color");
        }
        function close() {
            colorPicker.opened = false;
        }
    }

    function activate(view) {
        // IPC callers may have already opened themselves. Close them again during auth.
        if (auth.active)
            view = "polkit";
        if (view !== "launcher")
            launcher.visibleLauncher = false;
        if (view !== "controls")
            controls.opened = false;
        if (view !== "notifications")
            notifs.controlCenterVisible = false;
        audio.osdVisible = false;
        for (const name of Object.keys(panels)) {
            if (name !== view)
                panels[name].opened = false;
        }
    }

    function dismiss() {
        if (auth.active) {
            auth.cancel();
            return;
        }
        activate("");
    }

    IpcHandler {
        target: "island"
        function status(): string {
            return JSON.stringify({
                view: win.view || "bar",
                authentication: auth.active,
                captureHidden: win.captureHidden,
                focus: win.contentItem.Window.window?.activeFocusItem?.objectName || "",
                panels: Object.keys(win.panels).filter(name => win.panels[name].opened)
            });
        }
    }

    IpcHandler {
        target: "displays"
        function open() {
            win.openPanel("displays");
        }
        function toggle() {
            if (displays.opened)
                displays.opened = false;
            else
                win.openPanel("displays");
        }
        function close() {
            displays.opened = false;
        }
    }

    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: screen ? screen.height : 800
    exclusiveZone: Config.barExclusiveZone
    color: "transparent"
    WlrLayershell.layer: interactive ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.keyboardFocus: interactive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
        id: backdrop
        anchors.fill: parent
        enabled: win.interactive && !auth.active
        onClicked: win.dismiss()
    }

    Connections {
        target: win.notifs
        function onControlCenterVisibleChanged() {
            if (win.notifs.controlCenterVisible) {
                win.activate("notifications");
                Qt.callLater(() => {
                    if (!auth.active && win.notifs.controlCenterVisible)
                        center.forceActiveFocus();
                });
            }
        }
    }

    Rectangle {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Config.barBottomMargin
        width: Math.min(win.width - 24, Math.max(bar.implicitWidth, win.view === "launcher" ? Config.launcherWidth : win.activePanel ? Math.max(440, win.activePanel.implicitWidth) : 0))
        height: Config.barHeight + (win.view !== "" ? win.panelHeight + 8 : 0)
        radius: win.view === "" ? Config.barRadius : 26
        color: Theme.colBgAlpha095
        border.width: 1
        border.color: Theme.colBorderStrong
        clip: true

        Behavior on height {
            enabled: !Config.reducedMotion
            NumberAnimation {
                duration: Config.animNormal
                easing.type: Easing.OutCubic
            }
        }
        Behavior on width {
            enabled: !Config.reducedMotion
            NumberAnimation {
                duration: Config.animNormal
                easing.type: Easing.OutCubic
            }
        }
        Behavior on radius {
            enabled: !Config.reducedMotion
            NumberAnimation {
                duration: Config.animNormal
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: bar.top
            anchors.bottomMargin: 8
            height: win.panelHeight
            visible: win.view !== ""
            clip: true
            Keys.onEscapePressed: win.dismiss()

            Item {
                anchors.fill: parent
                enabled: !auth.active
                visible: !auth.active

                Launcher {
                    id: launcher
                    objectName: "islandLauncher"
                    anchors.fill: parent
                    wallpaper: win.wallpaper
                    onVisibleLauncherChanged: {
                        if (visibleLauncher)
                            win.activate("launcher");
                    }
                }
                ControlCenter {
                    id: controls
                    objectName: "islandControls"
                    anchors.fill: parent
                    audio: win.audio
                    notifs: win.notifs
                    onLauncherRequested: mode => launcher.open(mode)
                    onPanelRequested: panel => {
                        win.dismiss();
                        win.panelRequested(panel);
                    }
                    onOpenedChanged: {
                        if (opened)
                            win.activate("controls");
                    }
                }
                AudioMixer {
                    id: mixer
                    anchors.fill: parent
                    onOpenedChanged: if (opened)
                        win.activate("audio")
                }
                MediaPanel {
                    id: media
                    anchors.fill: parent
                    onOpenedChanged: if (opened)
                        win.activate("media")
                }
                CalendarPanel {
                    id: calendar
                    anchors.fill: parent
                    onOpenedChanged: if (opened)
                        win.activate("calendar")
                }
                CapturePanel {
                    id: capture
                    anchors.fill: parent
                    service: captureService
                    onOpenedChanged: if (opened)
                        win.activate("capture")
                    onCloseRequested: opened = false
                    onCaptureRequested: (action, options) => win.startCapture(action, options)
                }
                ColorPickerPanel {
                    id: colorPicker
                    anchors.fill: parent
                    service: captureService
                    onOpenedChanged: if (opened)
                        win.activate("color")
                    onCloseRequested: opened = false
                    onPickRequested: win.startCapture("pick", {})
                }
                SystemPanels.DisplayPanel {
                    id: displays
                    anchors.fill: parent
                    blocked: auth.active
                    onOpenedChanged: if (opened)
                        win.activate("displays")
                }
                NotificationCenter {
                    id: center
                    anchors.fill: parent
                    notifs: win.notifs
                }
                Osd {
                    id: osd
                    anchors.fill: parent
                    audio: win.audio
                    visible: win.view === "volume"
                }
            }

            SystemPanels.PolkitDialog {
                id: auth
                anchors.fill: parent
                agentEnabled: win.polkitAgentEnabled
                onActiveChanged: {
                    if (active && win.captureHidden) {
                        captureDelay.stop();
                        captureService.stop();
                    }
                    win.captureHidden = false;
                    win.activate(active ? "polkit" : "");
                }
            }
        }

        Bar {
            id: bar
            enabled: !auth.active
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Config.barHeight
            audio: win.audio
            notifs: win.notifs
            controls: controls
            capture: captureService
            onPanelRequested: panel => {
                win.dismiss();
                win.panelRequested(panel);
            }
            onLauncherRequested: mode => {
                if (launcher.visibleLauncher && launcher.mode === mode)
                    launcher.visibleLauncher = false;
                else
                    launcher.open(mode);
            }
        }
    }

    mask: Region {
        item: win.interactive ? backdrop : island
    }
}
