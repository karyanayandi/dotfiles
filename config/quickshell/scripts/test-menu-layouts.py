#!/usr/bin/env python3
"""Keep scrolling confined to launcher results and notifications."""

from pathlib import Path
import re

modules = Path(__file__).resolve().parents[1] / "modules"
for path in modules.rglob("*.qml"):
    relative = path.relative_to(modules)
    if relative.parts[0] in {"launcher", "notifications"}:
        continue
    source = path.read_text()
    assert not re.search(
        r"\b(?:ScrollView|ScrollBar|ScrollIndicator|Flickable)\s*[.{]", source
    ), relative
    if re.search(r"\b(?:ListView|GridView)\s*\{", source):
        assert "interactive: false" in source, relative

for name in (
    "panels/Panel.qml",
    "ControlCenter.qml",
    "displaypolkit/DisplayPanel.qml",
    "displaypolkit/PolkitDialog.qml",
    "capture/CaptureSurface.qml",
):
    assert "implicitHeight: Math.min" not in (modules / name).read_text(), name

assert "ScrollBar.AsNeeded" in (modules / "launcher/Results.qml").read_text()
assert "Flickable {" in (modules / "notifications/Center.qml").read_text()
print("PASS menus use content height; scrolling stays in launcher and notifications")
