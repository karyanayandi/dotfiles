#!/bin/sh
# Headless regression check for palette loading and live updates.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
mkdir -p "$tmp/.config/quickshell"
cp "$root/Theme.qml" "$root/Config.qml" "$root/qmldir" "$tmp/.config/quickshell/"
printf '%s\n' '{"g0":"#123456"}' > "$tmp/.config/quickshell/colors.json"
cat > "$tmp/.config/quickshell/shell.qml" <<'QML'
import QtQuick
import Quickshell
import Quickshell.Io
import "."

ShellRoot {
    property color initial: Theme.g0
    FileView {
        id: writer
        path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
    }
    Timer {
        interval: 500
        running: true
        onTriggered: {
            if (Theme.g0.toString() !== "#123456") {
                console.error("Initial palette load failed");
                Qt.exit(1);
                return;
            }
            writer.setText('{"g0":"#654321"}');
        }
    }
    Timer {
        interval: 1500
        running: true
        onTriggered: {
            if (Theme.g0.toString() !== "#654321") {
                console.error("Palette hot reload failed");
                Qt.exit(1);
                return;
            }
            console.log("PASS palette load and hot reload");
            Qt.quit();
        }
    }
}
QML
HOME="$tmp" QT_QPA_PLATFORM=offscreen timeout 5 qs -p "$tmp/.config/quickshell"
