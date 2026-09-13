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
    (config / "colors.json").write_text(
        json.dumps({f"g{i}": "#000000" for i in range(21)})
    )
    (config / "shell.qml").write_text("""import QtQuick
import Quickshell
import "."
ShellRoot {
    property int stage: -1
    property real previous: 0
    function check(ok, message) { if (!ok) throw new Error(message); }
    function setColors(color) { for (let i = 0; i < 21; i++) Theme["g" + i] = color; }
    Component.onCompleted: { console.log("Initial palette", Theme.g0); tick.start(); }
    Timer {
        id: tick
        interval: 60
        repeat: true
        onTriggered: {
            if (stage === -1) {
                check(Qt.colorEqual(Theme.g0, "black"), "Startup must not fade");
                setColors("white");
            } else if (stage === 0) {
                for (let i = 0; i < 21; i++)
                    check(Theme["g" + i].r > 0 && Theme["g" + i].r < 1, "Missing intermediate g" + i);
                check(Qt.colorEqual(Theme.colBg, Theme.g0), "Semantic color lag");
                check(Math.abs(Theme.colBgAlpha085.r - Theme.g0.r) < 0.005, "Alpha color lag");
                previous = Theme.g0.r;
                setColors("black");
                check(Math.abs(Theme.g0.r - previous) < 0.005, "Retarget jumped");
                console.log("PASS interpolation, derived colors, continuous retarget");
            } else if (stage === 1) {
                check(Theme.g0.r > 0 && Theme.g0.r < previous, "Retarget not progressing");
                interval = 300;
            } else if (stage === 2) {
                check(Qt.colorEqual(Theme.g0, "black"), "Retarget did not settle");
                Config.reducedMotion = true;
                setColors("white");
                for (let i = 0; i < 21; i++)
                    check(Qt.colorEqual(Theme["g" + i], "white"), "Reduced motion animated g" + i);
                console.log("PASS settle and reduced motion for all 21 colors");
                Qt.quit();
            }
            stage++;
        }
    }
}
""")
    result = subprocess.run(
        ["timeout", "5", "quickshell", "-p", str(config)],
        env=dict(os.environ, HOME=tmp, QT_QPA_PLATFORM="offscreen"),
        check=False,
        capture_output=True,
        text=True,
    )
    print(result.stdout + result.stderr)
    assert "Error:" not in result.stdout + result.stderr
    assert result.returncode == 0
    assert "PASS settle and reduced motion" in result.stdout + result.stderr
