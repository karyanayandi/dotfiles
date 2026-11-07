import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."
import "displaypolkit" as SystemPanels
import "../services" as Services

PanelWindow {
    id: win

    readonly property var activePanel: view === "polkit" ? auth : panels[view] || (view === "launcher" ? launcher : view === "controls" ? controls : view === "notifications" ? center : view === "volume" ? osd : null)
    required property var audio
    readonly property bool bluetoothPanel: view === "launcher" && launcher.mode === "bluetooth"
    readonly property bool centeredSearch: view === "launcher" && !bluetoothPanel
    property string captureAction: ""
    property bool captureHidden: false
    property var captureOptions: ({})
    readonly property bool captureSelecting: captureDelay.running || (captureService.busy && !captureService.recording && (captureService.action === "screenshot" || captureService.action === "record"))
    readonly property string extraView: Object.keys(panels).find(name => panels[name].opened) || ""
    readonly property bool interactive: auth.active || launcher.visibleLauncher || controls.opened || notifs.controlCenterVisible || extraView !== ""
    required property var notifs
    // Non-scrolling menus keep their natural height, even if content exceeds the screen.
    readonly property real panelHeight: {
        if (!activePanel)
            return 0;
        if (bluetoothPanel)
            return Math.max(0, Math.min(height - Config.barExclusiveZone - 40, center.implicitHeight));
        if (view === "launcher" || view === "notifications")
            return Math.max(0, Math.min(height - Config.barExclusiveZone - 40, activePanel.implicitHeight));
        return Math.max(0, activePanel.implicitHeight);
    }
    readonly property var panels: ({
            audio: mixer,
            media: media,
            calendar: calendar,
            displays: displays,
            color: colorPicker
        })
    property bool polkitAgentEnabled: Config.polkitAgentEnabled
    readonly property string view: auth.active ? "polkit" : extraView || (launcher.visibleLauncher ? "launcher" : controls.opened ? "controls" : notifs.controlCenterVisible ? "notifications" : audio.osdVisible ? "volume" : "")
    required property var wallpaper

    signal panelRequested(string panel)

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
    function openPanel(name) {
        if (auth.active)
            return;
        if (name === "capture") {
            if (captureService.recording)
                capture.video = true;
            capture.opened = true;
            return;
        }
        const panel = panels[name];
        if (panel) {
            panel.opened = true;
        }
    }
    function startCapture(action, options) {
        if (auth.active || !captureService.ready || captureService.busy || captureDelay.running)
            return;
        if (action === "screenshot" || action === "record") {
            captureService.beginSession();
            capture.video = action === "record";
        }
        capture.opened = false;
        if (action === "pick")
            activate("");
        captureAction = action;
        captureOptions = options;
        captureHidden = action === "pick";
        captureDelay.restart();
    }

    WlrLayershell.keyboardFocus: auth.active || (interactive && !capture.opened && !captureSelecting) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // Audio feedback must cover fullscreen clients without changing launcher/focus behavior.
    WlrLayershell.layer: interactive || view === "volume" ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.namespace: "quickshell"
    color: "transparent"
    exclusiveZone: Config.barExclusiveZone
    implicitHeight: screen ? screen.height : 800
    visible: !captureHidden

    mask: Region {
        item: auth.active ? backdrop : win.captureSelecting ? null : win.interactive && !capture.opened ? backdrop : menuBar

        Region {
            item: panelSurface.visible && !win.captureSelecting ? panelSurface : null
        }
        Region {
            item: feedback.visible && !win.captureSelecting ? feedback : null
        }
    }

    onPanelRequested: name => openPanel(name)

    Timer {
        id: captureDelay

        // Let the compositor unmap capture controls before sampling pixels.
        interval: 80

        onTriggered: {
            if (auth.active || !captureService.request(win.captureAction, win.captureOptions))
                win.captureHidden = false;
        }
    }
    Services.CaptureService {
        id: captureService

        onFeedback: (text, failed) => feedback.show(text, failed)
        onRecordingChanged: {
            if (recording)
                win.captureHidden = false;
        }
        onReveal: panel => {
            win.captureHidden = false;
            win.openPanel(panel);
        }
    }
    CaptureWindow {
        id: capture

        blocked: auth.active
        service: captureService

        onCaptureRequested: (action, options) => win.startCapture(action, options)
    }
    IpcHandler {
        function close() {
            capture.opened = false;
        }
        function open(mode: string) {
            if (!auth.active) {
                capture.open(mode);
                if (!captureService.busy)
                    captureService.request("capabilities");
            }
        }
        function start(action: string, mode: string) {
            if (action !== "screenshot" && action !== "record")
                return;
            if (!["screen", "area"].includes(mode) && !(action === "screenshot" && mode === "window"))
                return;
            win.startCapture(action, {
                "mode": mode
            });
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
        function stop() {
            captureDelay.stop();
            win.captureHidden = false;
            captureService.stop();
        }

        target: "capture"
    }
    IpcHandler {
        function close() {
            colorPicker.opened = false;
        }
        function open() {
            win.openPanel("color");
        }

        target: "colorPicker"
    }
    IpcHandler {
        function status(): string {
            return JSON.stringify({
                view: win.view || "bar",
                authentication: auth.active,
                captureHidden: win.captureHidden,
                focus: win.contentItem.Window.window?.activeFocusItem?.objectName || "",
                panels: Object.keys(win.panels).filter(name => win.panels[name].opened)
            });
        }

        target: "island"
    }
    IpcHandler {
        function close() {
            displays.opened = false;
        }
        function open() {
            win.openPanel("displays");
        }
        function toggle() {
            if (displays.opened)
                displays.opened = false;
            else
                win.openPanel("displays");
        }

        target: "displays"
    }
    anchors {
        top: true
        left: true
        right: true
    }
    MouseArea {
        id: backdrop

        anchors.fill: parent
        enabled: win.interactive && !auth.active && !capture.opened && !win.captureSelecting

        onClicked: win.dismiss()
    }
    Connections {
        function onControlCenterVisibleChanged() {
            if (win.notifs.controlCenterVisible) {
                win.activate("notifications");
                Qt.callLater(() => {
                    if (!auth.active && win.notifs.controlCenterVisible)
                        center.forceActiveFocus();
                });
            }
        }

        target: win.notifs
    }
    CaptureFeedback {
        id: feedback

        anchors.horizontalCenter: parent.horizontalCenter
        visible: opacity > 0 && !auth.active
        width: Math.min(420, win.width - 24)
        y: Config.barHeight + 20
        z: 2
    }
    Rectangle {
        id: panelSurface

        readonly property bool centered: win.centeredSearch || win.view === "polkit"
        readonly property bool feedbackOnly: win.view === "volume"
        x: feedbackOnly || centered ? (win.width - width) / 2 : win.width - width - 16
        y: feedbackOnly ? win.height - height - 64 : centered ? Math.max(Config.barHeight + 16, (win.height - height) / 2) : Config.barHeight + 12
        width: Math.min(win.width - 32, win.centeredSearch ? Config.launcherWidth : win.view === "volume" ? Config.osdWidth : win.bluetoothPanel || win.view === "controls" || win.view === "notifications" ? Config.centerWidth : Math.max(440, win.activePanel ? win.activePanel.implicitWidth : 440))
        height: win.panelHeight
        radius: Theme.radiusPanel
        color: Theme.colLauncherBg
        border.color: Theme.colBorderStrong
        border.width: 1
        clip: true
        visible: win.view !== "" && !win.captureSelecting
        opacity: visible ? 1 : 0

        Behavior on opacity {
            enabled: !Config.reducedMotion
            NumberAnimation {
                duration: Config.animFast
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
        }
        Item {
            id: content

            anchors.fill: parent
            clip: true
            height: win.panelHeight
            visible: win.view !== ""

            Keys.onEscapePressed: win.dismiss()

            Item {
                anchors.fill: parent
                enabled: !auth.active
                visible: !auth.active

                Launcher {
                    id: launcher

                    anchors.fill: parent
                    objectName: "islandLauncher"
                    wallpaper: win.wallpaper

                    onVisibleLauncherChanged: {
                        if (visibleLauncher)
                            win.activate("launcher");
                    }
                }
                ControlCenter {
                    id: controls

                    anchors.fill: parent
                    audio: win.audio
                    notifs: win.notifs
                    objectName: "islandControls"

                    onLauncherRequested: mode => launcher.open(mode)
                    onOpenedChanged: {
                        if (opened)
                            win.activate("controls");
                    }
                    onPanelRequested: panel => {
                        if (panel !== "capture")
                            win.dismiss();
                        win.panelRequested(panel);
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
                ColorPickerPanel {
                    id: colorPicker

                    anchors.fill: parent
                    service: captureService

                    onCloseRequested: opened = false
                    onOpenedChanged: if (opened)
                        win.activate("color")
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

                agentEnabled: win.polkitAgentEnabled
                anchors.fill: parent

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
    }
    Rectangle {
        id: menuBar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Config.barHeight
        color: Theme.colBgAlpha095

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Theme.colBorder
        }
        Bar {
            id: bar

            anchors.fill: parent
            audio: win.audio
            capture: captureService
            controls: controls
            enabled: !auth.active
            height: Config.barHeight
            notifs: win.notifs

            onLauncherRequested: mode => {
                if (launcher.visibleLauncher && launcher.mode === mode)
                    launcher.visibleLauncher = false;
                else
                    launcher.open(mode);
            }
            onPanelRequested: panel => {
                if (win.view === panel)
                    win.dismiss();
                else
                    win.panelRequested(panel);
            }
        }
    }
}
