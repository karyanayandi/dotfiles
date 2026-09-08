#!/usr/bin/env python3
"""Render every template in a temporary home, never touching live app configs."""

import json
import os
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

import tomllib

ROOT = Path(__file__).resolve().parents[2]
THEME = ROOT / "config/theme"


def check():
    binary = shutil.which("matugen")
    if not binary:
        raise SystemExit("Install matugen, or add its binary directory to PATH.")
    config = tomllib.loads((THEME / "config.toml").read_text())
    with tempfile.TemporaryDirectory(prefix="wallpaper-theme-test-") as directory:
        home = Path(directory)
        entries = ["[config]"]
        outputs = []
        for name, template in config["templates"].items():
            source = Path(
                template["input_path"].replace("~/.config/", str(ROOT / "config") + "/")
            )
            if not source.is_absolute():
                source = (THEME / source).resolve()
            assert source.is_file(), source
            entries += [
                f"[templates.{name}]",
                f"input_path = {json.dumps(str(source))}",
            ]
            if "output_path" in template:
                target = home / template["output_path"].removeprefix("~/")
                target.parent.mkdir(parents=True, exist_ok=True)
                outputs.append(target)
                entries.append(f"output_path = {json.dumps(str(target))}")
        test_config = home / "config.toml"
        test_config.write_text("\n".join(entries))
        previous = None
        for color in ("#ff0000", "#0000ff"):
            result = subprocess.run(
                [
                    binary,
                    "--config",
                    str(test_config),
                    "--mode",
                    "dark",
                    "color",
                    "hex",
                    color,
                ],
                capture_output=True,
                check=False,
                text=True,
            )
            assert result.returncode == 0, result.stdout + result.stderr
            for output in outputs:
                text = output.read_text()
                assert "{{" not in text, output
                if output.suffix in (".json", ".jsonc"):
                    json.loads(text)
                elif output.suffix == ".toml":
                    tomllib.loads(text)
                elif output.suffix == ".tmTheme":
                    ET.fromstring(text)
                elif output.suffix == ".fish" and shutil.which("fish"):
                    subprocess.run(["fish", "--no-execute", str(output)], check=True)
            rendered = [p.read_text() for p in outputs]
            if previous is not None:
                for path, before, after in zip(outputs, previous, rendered):
                    assert before != after, f"Palette does not change: {path}"
            previous = rendered
        # Runner must preserve spaces, restore saved state, and propagate failure.
        bindir = home / "bin"
        bindir.mkdir()
        fake = bindir / "matugen"
        fake.write_text(
            '#!/bin/sh\nprintf "%s\\n" "$@" > "$HOME/args"\nexit "${FAIL:-0}"\n'
        )
        fake.chmod(0o755)
        env = {
            **os.environ,
            "HOME": str(home),
            "XDG_CONFIG_HOME": str(home / ".config"),
            "XDG_CACHE_HOME": str(home / ".cache"),
            "PATH": str(bindir) + os.pathsep + os.environ["PATH"],
        }
        env.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
        env.pop("TMUX", None)
        env["TMUX_TMPDIR"] = str(home)
        image = home / "wall paper.png"
        image.touch()
        runner = ROOT / "home/.local/bin/wallpaper-theme"
        subprocess.run([str(runner), str(image)], env=env, check=True)
        assert (home / "args").read_text().splitlines()[-1] == str(image)
        store = home / ".cache/quickshell/wallpaper"
        store.parent.mkdir(parents=True)
        store.write_text(json.dumps({"wallpaper": str(image), "interval": 0}))
        subprocess.run([str(runner)], env=env, check=True)
        failed = subprocess.run(
            [str(runner), str(image)], env={**env, "FAIL": "7"}, check=False
        )
        assert failed.returncode == 7
        missing = subprocess.run(
            [str(runner), str(home / "missing")],
            env=env,
            capture_output=True,
            check=False,
        )
        assert missing.returncode != 0
    print(
        f"PASS: {len(outputs)} templates render and change palettes; structured output parses; runner handles restore, spaces, and failure."
    )


if __name__ == "__main__":
    check()
