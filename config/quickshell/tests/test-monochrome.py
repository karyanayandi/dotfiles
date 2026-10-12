"""Check wallpaper color controls in an offscreen window with a private HOME."""

import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REPORT = Path("/tmp/quickshell-monochrome-check.txt")

with tempfile.TemporaryDirectory(prefix="quickshell-monochrome-") as directory:
    home = Path(directory)
    config = home / ".config/quickshell"
    for name in (
        "Theme.qml",
        "Config.qml",
        "qmldir",
        "services/WallpaperService.qml",
        "modules/launcher/Footer.qml",
        "modules/launcher/SearchInput.qml",
    ):
        target = config / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / name, target)
    (config / "colors.json").write_text("{}")
    folder = home / ".config/dotfiles/wallpapers"
    folder.mkdir(parents=True)
    image = folder / "test.png"
    image.touch()
    next_image = folder / "next.png"
    next_image.touch()
    store = home / ".cache/quickshell/wallpaper"
    store.parent.mkdir(parents=True)
    store.write_text(json.dumps({"wallpaper": str(image), "interval": 0}))
    runner = home / ".local/bin/wallpaper-theme"
    runner.parent.mkdir(parents=True)
    runner.write_text('#!/bin/sh\nprintf "%s\\n" "$2" >> "$HOME/calls"\nsleep 0.3\n')
    runner.chmod(0o755)
    shell = config / "shell.qml"
    shell.write_text("""import QtQuick
import QtQuick.Layouts
import QtTest
import Quickshell
import "services"
import "modules/launcher" as Launcher

ShellRoot {
    WallpaperService { id: wallpaper }
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 700
        implicitHeight: 120
        ColumnLayout {
            anchors.fill: parent
            Launcher.SearchInput {
                id: input
                mode: "wallpaper"
                onToggleWallpaperMonochrome: wallpaper.toggleMonochrome()
            }
            Launcher.Footer {
                id: footer
                mode: "wallpaper"
                wallpaper: wallpaper
                bluetooth: ({scanning: false, powered: false})
                clipboard: ({})
            }
        }
    }
    TestCase {
        name: "WallpaperMonochrome"
        when: window.visible
        function test_controls() {
            verify(!wallpaper.monochrome);
            const button = footer.children.find(child => child.children
                && child.children.some(label => label.text === "ctrl+m  Color"));
            verify(button !== undefined, "Color button missing");
            mouseClick(button, button.width / 2, button.height / 2);
            compare(wallpaper.monochrome, true);
            verify(button.children.some(label => label.text === "ctrl+m  Mono"), "Mono label missing");
            wait(200);
            input.focusInput();
            keyClick(Qt.Key_M, Qt.ControlModifier);
            compare(wallpaper.monochrome, false);
            keyClick(Qt.Key_M, Qt.ControlModifier);
            compare(wallpaper.monochrome, true);
            wait(900);
            wallpaper.setWallpaper(wallpaper.folder + "/next.png");
            wait(700);
            compare(wallpaper.monochrome, true);
            console.info("PASS mouse, keyboard, queued monochrome render, wallpaper change");
            Qt.quit();
        }
    }
}
""")
    env = {
        **os.environ,
        "HOME": directory,
        "QT_QPA_PLATFORM": "offscreen",
        "NO_COLOR": "1",
    }
    result = subprocess.run(
        ["timeout", "10", "qs", "-p", str(config)],
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    log = result.stdout + result.stderr
    REPORT.write_text(log)
    assert result.returncode == 0 and "PASS mouse, keyboard" in log, log
    assert "FAIL!" not in log and "Error:" not in log, log
    assert json.loads(store.read_text()) == {
        "wallpaper": str(next_image),
        "interval": 0,
        "monochrome": True,
    }
    assert (home / "calls").read_text().splitlines() == ["mono"] * 3
    shell.write_text("""import QtQuick
import Quickshell
import "services"
ShellRoot {
    WallpaperService { id: wallpaper }
    Timer {
        interval: 700; running: true
        onTriggered: {
            if (!wallpaper.monochrome || wallpaper.rotationInterval !== 0
                || !wallpaper.current.endsWith("/next.png"))
                throw new Error("Saved mode not restored");
            console.info("PASS saved monochrome restored without render");
            Qt.quit();
        }
    }
}
""")
    result = subprocess.run(
        ["timeout", "5", "qs", "-p", str(config)],
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    log = result.stdout + result.stderr
    REPORT.write_text(REPORT.read_text() + log)
    assert result.returncode == 0 and "PASS saved monochrome restored" in log, log
    assert "Error:" not in log, log
    assert (home / "calls").read_text().splitlines() == ["mono"] * 3

print(
    f"PASS wallpaper monochrome controls, render queue, persistence; report: {REPORT}"
)
