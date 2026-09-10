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
    property string captureAction: ""
    property bool captureHidden: false
    property var captureOptions: ({})
    readonly property string extraView: Object.keys(panels).find(name => panels[name].opened) || ""
    readonly property bool interactive: auth.active || launcher.visibleLauncher || controls.opened || notifs.controlCenterVisible || extraView !== ""
    required property var notifs
    // Non-scrolling menus keep their natural height, even if content exceeds the screen.
    readonly property real panelHeight: {
        if (!activePanel)
            return 0;
        if (view === "launcher" || view === "notifications")
            return Math.max(0, Math.min(height - Config.barExclusiveZone - 16, activePanel.implicitHeight));
        return Math.max(0, activePanel.implicitHeight);
    }
    readonly property var panels: ({
            audio: mixer,
            media: media,
            calendar: calendar,
            displays: displays,
            capture: capture,
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
        const panel = panels[name];
        if (panel) {
            if (name === "capture" && captureService.recording)
                capture.video = true;
            panel.opened = true;
        }
    }
    function startCapture(action, options) {
        if (auth.active || !captureService.ready || captureService.busy)
            return;
        activate("");
        captureAction = action;
        captureOptions = options;
        captureHidden = true;
        captureDelay.restart();
    }

    WlrLayershell.keyboardFocus: interactive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.layer: interactive ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.namespace: "quickshell"
    color: "transparent"
    exclusiveZone: Config.barExclusiveZone
    implicitHeight: screen ? screen.height : 800
    visible: !captureHidden

    mask: Region {
        item: win.interactive ? backdrop : island
        Region {
            item: feedback.visible ? feedback : null
        }
    }

    onPanelRequested: name => openPanel(name)

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
        bottom: true
        left: true
        right: true
    }
    MouseArea {
        id: backdrop

        anchors.fill: parent
        enabled: win.interactive && !auth.active

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
        y: Math.max(12, island.y - height - 12)
        width: Math.min(420, win.width - 24)
        z: 2
        visible: opacity > 0 && !auth.active
    }
    Rectangle {
        id: island

        anchors.bottom: parent.bottom
        anchors.bottomMargin: Config.barBottomMargin
        anchors.horizontalCenter: parent.horizontalCenter
        border.color: Theme.colBorderStrong
        border.width: 1
        clip: true
        color: Theme.colBgAlpha095
        height: Config.barHeight + (win.view !== "" ? win.panelHeight + 8 : 0)
        radius: win.view === "" ? Config.barRadius : 26
        width: Math.min(win.width - 24, Math.max(bar.implicitWidth, win.view === "launcher" ? Config.launcherWidth : win.activePanel ? Math.max(440, win.activePanel.implicitWidth) : 0))

        Behavior on height {
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
        Behavior on width {
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

            anchors.bottom: bar.top
            anchors.bottomMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
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
                CapturePanel {
                    id: capture

                    anchors.fill: parent
                    service: captureService

                    onCaptureRequested: (action, options) => win.startCapture(action, options)
                    onCloseRequested: opened = false
                    onOpenedChanged: if (opened)
                        win.activate("capture")
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
        Bar {
            id: bar

            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
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
                win.dismiss();
                win.panelRequested(panel);
            }
        }
    }
}
