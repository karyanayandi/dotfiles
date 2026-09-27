#!/bin/sh
# Exercise real matugen writes and external replacements, never FileView.setText().
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
python3 - "$root" <<'PY'
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(sys.argv[1])
with tempfile.TemporaryDirectory() as tmp:
    home = Path(tmp)
    config = home / ".config/quickshell"
    config.mkdir(parents=True)
    for name in ("Theme.qml", "Config.qml", "qmldir"):
        shutil.copyfile(root / name, config / name)
    (config / "modules/panels").mkdir(parents=True)
    for name in ("PanelButton.qml", "PanelTextField.qml", "PanelComboBox.qml", "PanelSpinBox.qml"):
        shutil.copyfile(root / "modules/panels" / name, config / "modules/panels" / name)
    (config / "components").mkdir()
    shutil.copyfile(root / "components/IconLabel.qml", config / "components/IconLabel.qml")
    (config / "components/qmldir").write_text("IconLabel 1.0 IconLabel.qml\n")
    (config / "services").mkdir()
    shutil.copyfile(root / "services/WallpaperService.qml", config / "services/WallpaperService.qml")
    (home / ".config/dotfiles/wallpapers").mkdir(parents=True)
    store = home / ".cache/quickshell/wallpaper"
    store.parent.mkdir(parents=True)
    store.write_text('{"wallpaper":"","interval":0}')
    runner = home / ".local/bin/wallpaper-theme"
    runner.parent.mkdir(parents=True)
    runner.write_text("#!/bin/sh\nexit 0\n")  # Never call the user's live theme runner.
    runner.chmod(0o755)
    palette = config / "colors.json"
    matugen_config = home / "matugen.toml"
    matugen_config.write_text(
        '[config]\n[templates.quickshell]\n'
        f'input_path = "{root.parent / "theme/templates/quickshell.json"}"\n'
        f'output_path = "{palette}"\n'
    )

    def render(color):
        subprocess.run(
            ["matugen", "-c", str(matugen_config), "color", "hex", color],
            check=True, capture_output=True, text=True,
        )
        return palette.read_text()

    blue = render("#0000ff")
    red = render("#ff0000")
    palette.write_text(blue)
    expected = [json.loads(text) for text in (blue, red, blue, red, blue)]
    assert expected[0]["g0"] != expected[1]["g0"]
    qml = '''import QtQuick
import Quickshell
import "."
import "services"
import "modules/panels" as Panels

ShellRoot {
    id: root
    property int stage: 0
    property bool saved: false
    WallpaperService { id: wallpaper }
    Component.onCompleted: Qt.callLater(() => {
        wallpaper.setWallpaper("/test-wallpaper.png");
        wallpaper.cycleInterval();
        stepper.value = 2;
        stepper.increase();
        if (stepper.value !== 3) throw new Error("Stepper increment failed");
        stepper.decrease();
        if (stepper.value !== 2) throw new Error("Stepper decrement failed");
        stepper.value = 0;
        stepper.decrease();
        if (stepper.value !== 0) throw new Error("Stepper lower bound failed");
        stepper.value = 10;
        stepper.increase();
        if (stepper.value !== 10) throw new Error("Stepper upper bound failed");
        stepper.contentItem.text = "4";
        stepper.contentItem.editingFinished();
        if (stepper.value !== 4) throw new Error("Stepper typed input failed");
        stepper.contentItem.text = "";
        stepper.contentItem.editingFinished();
        if (stepper.value !== 4 || stepper.contentItem.text !== stepper.displayText)
            throw new Error("Stepper invalid input was not restored");
        stepper.increase();
        if (stepper.value !== 5 || stepper.contentItem.text !== stepper.displayText)
            throw new Error("Stepper display did not follow buttons after editing");
        console.log("PASS stepper editing and bounds");
        root.saved = true;
    })
    readonly property var expected: EXPECTED

    // Same bindings as Launcher.qml and its result/chip consumers.
    Rectangle {
        id: card
        color: Theme.colLauncherBg
        border.color: Theme.colLauncherBorder
    }
    Rectangle {
        id: selection
        color: Theme.colHoverAlpha
        border.color: Theme.colBorder
    }
    Rectangle {
        id: chip
        color: Theme.colChipBg
    }
    Text {
        id: label
        color: Theme.colFg
    }
    Panels.PanelTextField { id: field; leadingGlyph: "X" }
    Panels.PanelComboBox { id: select; model: ["Test"] }
    Panels.PanelButton { id: button; text: "Test" }
    Panels.PanelButton { id: primary; text: "Capture"; tone: "primary" }
    Panels.PanelSpinBox { id: stepper; from: 0; to: 10 }

    function alpha(hex, opacity) {
        const color = Qt.color(hex);
        return Qt.rgba(color.r, color.g, color.b, opacity);
    }

    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: {
            if (!root.saved)
                return;
            const p = root.expected[root.stage];
            if (!Qt.colorEqual(card.color, root.alpha(p.g0, 0.98))
                || !Qt.colorEqual(card.border.color, root.alpha(p.g17, 0.35))
                || !Qt.colorEqual(selection.color, root.alpha(p.g3, 0.8))
                || !Qt.colorEqual(selection.border.color, root.alpha(p.g3, 0.45))
                || !Qt.colorEqual(chip.color, root.alpha(p.g2, 0.9))
                || !Qt.colorEqual(label.color, p.g5)
                || !Qt.colorEqual(Theme.colChipActive, p.g6)
                || !Qt.colorEqual(Theme.colInputBg, root.alpha(p.g1, 0.65))
                || !Qt.colorEqual(field.color, p.g5)
                || !Qt.colorEqual(field.background.color, root.alpha(p.g1, 0.65))
                || !Qt.colorEqual(select.background.color, root.alpha(p.g1, 0.65))
                || !Qt.colorEqual(button.contentItem.color, p.g5)
                || !Qt.colorEqual(primary.background.color, p.g6)
                || !Qt.colorEqual(primary.contentItem.color, p.g0)
                || !Qt.colorEqual(stepper.background.color, root.alpha(p.g1, 0.65))
                || !Qt.colorEqual(stepper.contentItem.color, p.g5))
                return;
            console.log("PASS stage " + root.stage + " launcher=" + card.color
                + " border=" + card.border.color + " selection=" + selection.color);
            root.stage++;
            if (root.stage === root.expected.length) {
                stop();
                Qt.quit();
            }
        }
    }
}
'''.replace("EXPECTED", json.dumps(expected))
    (config / "shell.qml").write_text(qml)
    env = dict(os.environ, HOME=tmp, QT_QPA_PLATFORM="offscreen", NO_COLOR="1")
    with subprocess.Popen(
        ["timeout", "15", "qs", "-p", str(config)], env=env,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
    ) as process:
        stages = 0
        for line in process.stdout:
            print(line, end="", flush=True)
            if f"PASS stage {stages} " not in line:
                continue
            stages += 1
            inode = palette.stat().st_ino
            if stages == 1:
                render("#ff0000")  # Actual matugen renderer while shell is running.
                print(f"matugen replaced inode: {palette.stat().st_ino != inode}", flush=True)
            elif stages == 2:
                palette.write_text(blue)  # External in-place overwrite.
                assert palette.stat().st_ino == inode
            elif stages in (3, 4):
                replacement = palette.with_suffix(".tmp")
                replacement.write_text(red if stages == 3 else blue)
                replacement.replace(palette)  # Atomic rename, twice to check re-arming.
                assert palette.stat().st_ino != inode
        assert process.wait() == 0, "Quickshell failed or timed out waiting for colors"
        assert stages == len(expected), f"Only {stages} palette stages completed"
    assert json.loads(store.read_text()) == {"wallpaper": "/test-wallpaper.png", "interval": 1800000}
    print("PASS wallpaper save, matugen render, external overwrite, repeated atomic replacement")
PY
