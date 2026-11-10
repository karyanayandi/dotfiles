#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import tempfile
import tomllib

ROOT = Path(__file__).resolve().parents[2]
THEME = ROOT / "config/theme"


def check():
    config = tomllib.loads((THEME / "config.toml").read_text())
    base = tomllib.loads((ROOT / "config/herdr/base.toml").read_text())
    layout = json.loads((ROOT / "config/herdr-app/layouts/matugen.json").read_text())
    assert layout["theme"] == "matugen"
    assert "colors" not in layout
    assert not layout.get("background", "").startswith("#")
    default_path = ROOT / "config/herdr-app/layouts/matugen-herdr.json"
    default_layout = json.loads(default_path.read_text())
    assert default_layout["theme"] == layout["theme"]
    assert default_layout["type"] == "row"
    assert layout["type"] == "column"
    assert "colors" not in default_layout
    assert "#" not in default_path.read_text()
    assert [node["id"] for node in default_layout["children"]] == ["sidebar", "work"]
    for mod in ("workspace-chrome", "spaces", "agents", "tabs", "pane", "files", "changes", "workspace-status"):
        assert f'"mod": "{mod}"' in default_path.read_text()
    with tempfile.TemporaryDirectory(prefix="herdr-theme-") as directory:
        home = Path(directory)
        entries = ["[config]"]
        outputs = {}
        for name in ("herdr-base", "herdr", "herdr-app", "ghostty"):
            template = config["templates"][name]
            source = (THEME / template["input_path"]).resolve()
            entries += [f"[templates.{name}]", f"input_path = {json.dumps(str(source))}"]
            if "output_path" in template:
                target = home / template["output_path"].removeprefix("~/")
                target.parent.mkdir(parents=True, exist_ok=True)
                outputs[name] = target
                entries.append(f"output_path = {json.dumps(str(target))}")
        test_config = home / "config.toml"
        test_config.write_text("\n".join(entries))
        previous = None
        for color in ("#ff0000", "#0000ff"):
            subprocess.run(["matugen", "--config", str(test_config), "--mode", "dark", "color", "hex", color], check=True, capture_output=True)
            cli = tomllib.loads(outputs["herdr"].read_text())
            assert cli["keys"] == base["keys"]
            assert cli["onboarding"] == base["onboarding"]
            result = subprocess.run(["herdr", "config", "check"], env={**os.environ, "HERDR_CONFIG_PATH": str(outputs["herdr"])}, capture_output=True, text=True)
            assert result.returncode == 0, result.stdout + result.stderr
            desktop = json.loads(outputs["herdr-app"].read_text())
            ghostty = outputs["ghostty"].read_text().splitlines()
            ansi = [line.split("=", 2)[2] for line in ghostty if line.startswith("palette = ")][:16]
            assert desktop["ansi"] == ansi
            assert desktop["background"] == ghostty[0].split(" = ")[1]
            assert cli["theme"]["custom"]["panel_bg"] == desktop["background"]
            assert cli["theme"]["custom"]["sidebar_bg"] == desktop["background"]
            rendered = [outputs[name].read_text() for name in ("herdr", "herdr-app")]
            if previous is not None:
                assert all(before != after for before, after in zip(previous, rendered))
            previous = rendered
        artifact = Path("/tmp/herdr-theme-check.json")
        artifact.write_text(json.dumps({"cli": cli["theme"], "desktop": desktop, "layouts": {"matugen": layout, "matugen-herdr": default_layout}}, indent=2) + "\n")
        assert json.loads(artifact.read_text())["desktop"] == desktop
    print("PASS: two Herdr palettes, valid config, preserved keys, Desktop ANSI colors and both layouts; /tmp/herdr-theme-check.json")


if __name__ == "__main__":
    check()
