#!/usr/bin/env python3
"""Keep scrolling confined to results, notifications, and the capture editor."""

import re
from pathlib import Path

modules = Path(__file__).resolve().parents[1] / "modules"
for path in modules.rglob("*.qml"):
    relative = path.relative_to(modules)
    if (
        relative.parts[0] in {"launcher", "notifications"}
        or relative.name == "CaptureWindow.qml"
        or relative.as_posix() == "capture/CaptureEditor.qml"
    ):
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
print(
    "PASS menus use content height; scrolling stays in launcher, notifications, and capture"
)

# Empty drive section must not stop discovery when control center is open.
drives = (modules.parent / "components/RemovableDrives.qml").read_text()
assert "visible: (source.result.devices || []).length > 0" in drives
controls = (modules / "ControlCenter.qml").read_text()
assert re.search(r"Extras\.RemovableDrives\s*\{[^}]*active: win\.opened", controls)
print("PASS empty drives stay hidden without disabling discovery")
