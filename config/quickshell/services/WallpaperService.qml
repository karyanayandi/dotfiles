import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property string folder: Quickshell.env("HOME") + "/.config/dotfiles/wallpapers"
    readonly property string storePath: Quickshell.env("HOME") + "/.cache/quickshell/wallpaper"
    property var wallpapers: []
    property string current: ""
    property string pendingTheme: ""
    property int rotationInterval: 1.08e+07
    readonly property var intervalOptions: [0, 1.8e+06, 3.6e+06, 1.08e+07, 2.16e+07, 4.32e+07]
    readonly property string rotationLabel: {
        if (root.rotationInterval === 0)
            return "Off";

        if (root.rotationInterval < 3.6e+06)
            return root.rotationInterval / 60000 + "m";

        return root.rotationInterval / 3.6e+06 + "h";
    }

    function save() {
        store.setText(JSON.stringify({
            "wallpaper": root.current,
            "interval": root.rotationInterval
        }));
    }

    function setWallpaper(path) {
        if (!path)
            return ;

        root.current = path;
        root.save();
        if (root.rotationInterval > 0)
            rotation.restart();

    }

    function cycleInterval() {
        const currentIndex = root.intervalOptions.indexOf(root.rotationInterval);
        root.rotationInterval = root.intervalOptions[(currentIndex + 1) % root.intervalOptions.length];
        root.save();
        if (root.rotationInterval > 0)
            rotation.restart();
        else
            rotation.stop();
    }

    function randomize() {
        if (!root.wallpapers.length)
            return ;

        const choices = root.wallpapers.filter((path) => {
            return path !== root.current;
        });
        root.setWallpaper((choices.length ? choices : root.wallpapers)[Math.floor(Math.random() * (choices.length || root.wallpapers.length))]);
    }

    visible: false
    onCurrentChanged: {
        if (root.current) {
            root.pendingTheme = root.current;
            themeDelay.restart();
        }
    }
    Component.onCompleted: {
        store.reload();
        const saved = (store.text() || "").trim();
        try {
            const state = JSON.parse(saved);
            root.current = state.wallpaper || "";
            if (root.intervalOptions.includes(state.interval))
                root.rotationInterval = state.interval;

        } catch (error) {
            root.current = saved;
        }
        scan.running = true;
    }

    FileView {
        id: store

        path: root.storePath
        blockLoading: true
    }

    Process {
        id: scan

        command: ["sh", "-c", "find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -print | sort", "sh", root.folder]
        onExited: {
            if (!root.wallpapers.includes(root.current))
                root.randomize();

        }

        stdout: SplitParser {
            onRead: (data) => {
                const path = (data || "").trim();
                if (path)
                    root.wallpapers = root.wallpapers.concat([path]);

            }
        }

    }

    // Coalesce fast selections; finish each render before starting the newest one.
    Timer {
        id: themeDelay

        interval: 150
        onTriggered: {
            if (!themeProcess.running && root.pendingTheme) {
                themeProcess.command = [Quickshell.env("HOME") + "/.local/bin/wallpaper-theme", root.pendingTheme];
                root.pendingTheme = "";
                themeProcess.running = true;
            }
        }
    }

    Process {
        id: themeProcess

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("Wallpaper theme generation failed; run wallpaper-theme in a terminal for details.");

            if (root.pendingTheme)
                themeDelay.restart();

        }
    }

    Timer {
        id: rotation

        interval: Math.max(1000, root.rotationInterval)
        running: root.wallpapers.length > 1 && root.rotationInterval > 0
        repeat: true
        onTriggered: root.randomize()
    }

}
