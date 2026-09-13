"""Run the real service, Matugen and wallpaper item offscreen in a private HOME."""

import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory() as tmp:
    home = Path(tmp)
    config = home / ".config/quickshell"
    config.mkdir(parents=True)
    for name in (
        "Theme.qml",
        "Config.qml",
        "qmldir",
        "services/WallpaperService.qml",
        "components/WallpaperImage.qml",
    ):
        target = config / name
        target.parent.mkdir(exist_ok=True)
        shutil.copyfile(root / name, target)
    folder = home / ".config/dotfiles/wallpapers"
    folder.mkdir(parents=True)
    for name, color in (("blue", "blue"), ("red", "red"), ("green", "lime")):
        subprocess.run(
            ["magick", "-size", "16x16", f"xc:{color}", str(folder / f"{name}.png")],
            check=True,
        )
    store = home / ".cache/quickshell/wallpaper"
    store.parent.mkdir(parents=True)
    store.write_text(json.dumps({"wallpaper": str(folder / "blue.png"), "interval": 0}))
    matugen = home / "matugen.toml"
    matugen.write_text(
        "[config]\n[templates.quickshell]\n"
        f'input_path = "{root.parent / "theme/templates/quickshell.json"}"\n'
        f'output_path = "{config / "colors.json"}"\n'
    )
    subprocess.run(
        [
            "matugen",
            "-c",
            str(matugen),
            "--source-color-index",
            "0",
            "image",
            str(folder / "blue.png"),
        ],
        check=True,
        capture_output=True,
    )
    initial = json.loads((config / "colors.json").read_text())
    runner = home / ".local/bin/wallpaper-theme"
    runner.parent.mkdir(parents=True)
    runner.write_text(f"""#!/bin/sh
printf '%s\\n' "$1" >> '{home}/calls'
exec matugen -c '{matugen}' --source-color-index 0 image "$1"
""")
    runner.chmod(0o755)
    shell = config / "shell.qml"
    shell.write_text(
        """import QtQuick
import Quickshell
import "services"
import "components"
import "."
ShellRoot {
    property int stage: 0
    property int ticks: 0
    property bool faded: false
    property bool captured: false
    property int paletteFrames: 0
    property color lastColor: initial
    property color initial: "INITIAL"
    WallpaperService { id: service }
    FloatingWindow {
        visible: true
        implicitWidth: 32; implicitHeight: 32
        WallpaperImage {
            id: image
            anchors.fill: parent
            source: service.current ? "file://" + service.current : ""
        }
    }
    Component.onCompleted: console.log("BOOT")
    Timer {
        interval: 16; running: true; repeat: true
        onTriggered: {
            ticks++;
            if (stage === 0 && ticks > 20 && image.displayedSource.toString().endsWith("blue.png")) {
                if (image.transitioning) throw new Error("Startup faded");
                service.setWallpaper(service.folder + "/red.png");
                stage = 1;
            } else if (stage === 1) {
                if (image.transitioning) {
                    const opacity = image.children[1].opacity;
                    if (opacity > 0 && opacity < 1) {
                        if (!image.displayedSource.toString().endsWith("blue.png"))
                            throw new Error("Old wallpaper lost during fade");
                        faded = true;
                        if (!captured && opacity > 0.2 && opacity < 0.6) {
                            captured = true;
                            image.grabToImage(result => {
                                if (!result.saveToFile(Quickshell.env("HOME") + "/blend.png"))
                                    throw new Error("Could not capture blend frame");
                            });
                        }
                    }
                }
                if (!Qt.colorEqual(Theme.g0, lastColor)) {
                    paletteFrames++;
                    lastColor = Theme.g0;
                }
                if (!faded || paletteFrames < 3 || ticks < 60 || image.transitioning
                    || !image.displayedSource.toString().endsWith("red.png")) return;
                console.log("PASS service, decoded image crossfade, Matugen palette update");
                Config.reducedMotion = true;
                service.setWallpaper(service.folder + "/green.png");
                stage = 2;
            } else if (stage === 2) {
                if (image.transitioning) throw new Error("Reduced motion faded wallpaper");
                if (!image.displayedSource.toString().endsWith("green.png")) return;
                stage = 3;
                ticks = 0;
            } else if (stage === 3 && ticks > 40) {
                console.log("PASS reduced motion; RELOAD");
                stage = 4;
            } else if (stage === 0 && ticks > 20 && image.displayedSource.toString().endsWith("green.png")) {
                if (image.transitioning) throw new Error("Reload faded wallpaper");
                console.log("PASS reload restored wallpaper");
                Qt.quit();
            }
        }
    }
}
""".replace("INITIAL", initial["g0"])
    )
    with subprocess.Popen(
        ["timeout", "12", "qs", "-p", str(config)],
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
                shell.write_text(shell.read_text() + "\n// Exercise QML hot reload.\n")
        assert process.wait() == 0, "Wallpaper pipeline failed or timed out"
    log = "".join(output)
    assert "Error:" not in log
    assert "PASS reload restored wallpaper" in log
    assert log.count("BOOT") == 2, "Unexpected QML reload during Matugen writes"
    assert (home / "calls").read_text().splitlines() == [
        str(folder / "red.png"),
        str(folder / "green.png"),
    ], "Startup or QML reload regenerated theme"
    assert json.loads(store.read_text())["wallpaper"] == str(folder / "green.png")
    pixel = subprocess.check_output(
        [
            "magick",
            str(home / "blend.png"),
            "-format",
            "%[fx:r] %[fx:g] %[fx:b]",
            "info:",
        ],
        text=True,
    )
    red, green, blue = map(float, pixel.split())
    assert 0 < red < 1 and green == 0 and 0 < blue < 1, pixel
    print(f"PASS rendered crossfade pixel RGB: {pixel}")
