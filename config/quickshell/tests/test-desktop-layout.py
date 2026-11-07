#!/usr/bin/env python3
"""Check desktop placement and retain the public shell interfaces."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
host = (root / "modules/Island.qml").read_text()
bar = (root / "modules/Bar.qml").read_text()
config = (root / "Config.qml").read_text()
popups = (root / "modules/NotificationPopups.qml").read_text()

assert "id: menuBar" in host
assert "id: panelSurface" in host
assert "anchors.top: parent.top" in host
assert "exclusiveZone: Config.barExclusiveZone" in host
assert 'view === "launcher" && !bluetoothPanel' in host
assert 'view === "launcher" && launcher.mode === "bluetooth"' in host
assert 'Math.min(height - Config.barExclusiveZone - 40, center.implicitHeight)' in host
assert 'win.centeredSearch ? Config.launcherWidth' in host
assert ': centered ? Math.max(Config.barHeight + 16, (win.height - height) / 2)' in host
assert 'property int launcherWidth: 920' in config
assert 'implicitHeight: Config.launcherMaxHeight' in (root / "modules/Launcher.qml").read_text()
assert "target: \"island\"" in host
assert "barHeight + (win.view" not in host
assert "property int barBottomMargin: 0" in config
assert 'launcherRequested("apps")' not in bar
assert 'glyph: "󰀵"' not in bar
assert 'glyph: ""' not in bar
assert 'text: "Desktop"' not in bar
assert 'label: "Control Center"' not in bar
assert "Accessible.name:" in (root / "modules/bar/MenuButton.qml").read_text()
assert "anchors.centerIn: parent\n        onClicked: barWin.panelRequested(\"calendar\")" in bar
assert "top: true" in popups and "right: true" in popups
assert "bottom: true" not in popups
assert "!Config.reducedMotion" in host
print("PASS top bar, detached panels, centered clock, no launcher icons, top-right notifications, and legacy IPC")
