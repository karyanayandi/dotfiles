"""Exercise palette file watching in a private HOME, without touching live wallpaper."""

import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory() as tmp:
    config = Path(tmp) / ".config/quickshell"
    config.mkdir(parents=True)
    for name in ("Theme.qml", "Config.qml", "qmldir"):
        shutil.copyfile(root / name, config / name)
    palette = config / "colors.json"

    def write(color, atomic=False):
        target = palette.with_suffix(".tmp") if atomic else palette
        target.write_text(json.dumps({f"g{i}": color for i in range(21)}))
        if atomic:
            target.replace(palette)

    write("#000000")
    (config / "shell.qml").write_text("""import QtQuick
import Quickshell
import "."
ShellRoot {
    property int stage: 0
    property bool intermediate: false
    property int ticks: 0
    Component.onCompleted: console.log("BOOT", Theme.g0)
    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            ticks++;
            if (stage === -1 && ticks > 10) {
                stage = 2;
                console.log("WRITE black atomic");
                return;
            }
            if (stage === 0 && ticks > 10) {
                if (!Qt.colorEqual(Theme.g0, "black")) throw new Error("Startup faded");
                stage = 1;
                console.log("WRITE white");
                return;
            }
            if (stage < 1) return;
            const target = stage === 2 ? 0 : 1;
            if (Theme.g0.r > 0 && Theme.g0.r < 1) {
                if (stage === 3) throw new Error("Reduced motion animated");
                intermediate = true;
                for (let i = 0; i < 21; i++)
                    if (Math.abs(Theme["g" + i].r - Theme.g0.r) > 0.005)
                        throw new Error("Palette frames differ");
                if (!Qt.colorEqual(Theme.colBg, Theme.g0)
                    || Math.abs(Theme.colBgAlpha085.r - Theme.g0.r) > 0.005)
                    throw new Error("Semantic color lag");
            }
            if (Theme.g0.r !== target) return;
            if (stage !== 3 && !intermediate) throw new Error("File update did not animate");
            console.log("PASS stage", stage);
            intermediate = false;
            stage++;
            if (stage === 2) console.log("WRITE black atomic");
            else if (stage === 3) {
                Config.reducedMotion = true;
                console.log("WRITE white atomic");
            } else { console.log("RELOAD"); stop(); }
        }
    }
}
""")
    with subprocess.Popen(
        ["timeout", "8", "qs", "-p", str(config)],
        env=dict(os.environ, HOME=tmp, QT_QPA_PLATFORM="offscreen", NO_COLOR="1"),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    ) as process:
        output = []
        for line in process.stdout:
            print(line, end="", flush=True)
            output.append(line)
            if "RELOAD" in line:
                shell = config / "shell.qml"
                shell.write_text(
                    shell.read_text()
                    .replace("property int stage: 0", "property int stage: -1")
                    .replace('console.log("RELOAD"); stop();', "Qt.quit();")
                )
            if "WRITE white" in line:
                write("#ffffff", "atomic" in line)
            elif "WRITE black" in line:
                write("#000000", True)
        assert process.wait() == 0, "Palette file-write test timed out or failed"
        log = "".join(output)
        assert "Error:" not in log
        assert log.count("BOOT") == 2, "Unexpected QML engine reload"
        assert "PASS stage 3" in log
