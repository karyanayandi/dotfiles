import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: win

    required property var audio
    required property var notifs
    required property var wallpaper

    readonly property bool interactive: launcher.visibleLauncher || controls.opened || notifs.controlCenterVisible
    readonly property string view: launcher.visibleLauncher ? "launcher" : controls.opened ? "controls" : notifs.controlCenterVisible ? "notifications" : audio.osdVisible ? "volume" : ""
    readonly property real panelHeight: Math.max(0, Math.min(height - Config.barExclusiveZone - 16, view === "launcher" ? launcher.implicitHeight : view === "controls" ? controls.implicitHeight : view === "notifications" ? center.implicitHeight : view === "volume" ? osd.implicitHeight : 0))

    function activate(view) {
        if (view !== "launcher")
            launcher.visibleLauncher = false;
        if (view !== "controls")
            controls.opened = false;
        if (view !== "notifications")
            notifs.controlCenterVisible = false;
        audio.osdVisible = false;
    }

    function dismiss() {
        activate("");
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
        enabled: win.interactive
        onClicked: win.dismiss()
    }

    Connections {
        target: win.notifs
        function onControlCenterVisibleChanged() {
            if (win.notifs.controlCenterVisible) {
                win.activate("notifications");
                Qt.callLater(() => center.forceActiveFocus());
            }
        }
    }

    Rectangle {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Config.barBottomMargin
        width: Math.min(win.width - 24, Math.max(bar.implicitWidth, win.view === "launcher" ? Config.launcherWidth : win.view !== "" ? 440 : 0))
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
                onOpenedChanged: {
                    if (opened)
                        win.activate("controls");
                }
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

        Bar {
            id: bar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Config.barHeight
            audio: win.audio
            notifs: win.notifs
            controls: controls
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
