#!/usr/bin/env python3
"""No live monitor mutations. Run with python3 test-display-settings.py."""

import importlib.util
import tempfile
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "displays", Path(__file__).with_name("display-settings.py")
)
d = importlib.util.module_from_spec(spec)
spec.loader.exec_module(d)
m = {
    "name": "HDMI-A-1",
    "width": 1920,
    "height": 1080,
    "refreshRate": 60,
    "x": 0,
    "y": 0,
    "scale": 1,
    "transform": 0,
    "disabled": False,
    "availableModes": ["1920x1080@60.00Hz"],
}
request = {
    "output": m["name"],
    "mode": "1920x1080@60.00",
    "position": "0x0",
    "scale": 1,
    "transform": 0,
}
assert d.validate(request, [m]) == request
for bad in (
    {"scale": "nan"},
    {"mode": "bad"},
    {"output": 'x";evil()'},
    {"position": "auto"},
    {"transform": 8},
):
    try:
        d.validate(request | bad, [m])
        raise AssertionError("Accepted invalid request")
    except ValueError:
        pass
with tempfile.TemporaryDirectory() as directory:
    d.RUNTIME = Path(directory)
    d.SAVED = Path(directory) / "saved.lua"
    with patch.object(d, "monitors", return_value=[m]), patch.object(d, "hypr") as call:
        with patch.object(d.time, "monotonic", side_effect=[0, 21]):
            d.worker(request)
        assert call.call_count == 2, "Deadline must restore previous rule"
        assert call.call_args.args == ("eval", d.lua(d.rule(m)))
        assert not d.SAVED.exists(), "Trial must not persist"
        call.reset_mock()

        def decide(_):
            (d.RUNTIME / "decision").write_text("save")

        with patch.object(d.time, "sleep", side_effect=decide):
            d.worker(request)
        assert call.call_count == 1, "Confirmed settings must not revert"
        assert "hl.monitor" in d.SAVED.read_text()
        call.reset_mock()
        call.side_effect = [RuntimeError("apply failed"), "ok"]
        d.worker(request)
        assert call.call_count == 2, "Apply error must attempt rollback"
print("PASS: validation, deadline rollback, explicit persistence, failure rollback")

# Cancellation, persistence failure, and failed rollback remain observable.
with tempfile.TemporaryDirectory() as directory:
    d.RUNTIME = Path(directory)
    d.SAVED = Path(directory) / "missing" / "saved.lua"
    with patch.object(d, "monitors", return_value=[m]), patch.object(d, "hypr") as call:

        def revert(_):
            (d.RUNTIME / "decision").write_text("revert")

        with patch.object(d.time, "sleep", side_effect=revert):
            d.worker(request)
        assert call.call_count == 2
        call.reset_mock()
        with patch.object(d.time, "sleep", side_effect=SystemExit):
            try:
                d.worker(request)
            except SystemExit:
                pass
        assert call.call_count == 2, "Worker termination must revert"
        assert not d.state()["pending"]
        call.reset_mock()
        call.side_effect = [None, RuntimeError("disconnected")]
        with patch.object(d.time, "monotonic", side_effect=[0, 21]):
            d.worker(request)
        assert "Rollback failed" in d.state()["message"]
        call.side_effect = None
        call.reset_mock()
        with (
            patch.object(d.time, "sleep", side_effect=decide),
            patch.object(Path, "mkdir", side_effect=OSError("disk full")),
        ):
            d.worker(request)
        assert call.call_count == 2, "Save failure must revert"
        assert "disk full" in d.state()["message"]

# Saving an unrelated output must never turn mirrored siblings into independent outputs.
with tempfile.TemporaryDirectory() as directory:
    d.RUNTIME = Path(directory)
    d.SAVED = Path(directory) / "saved.lua"
    d.SAVED.write_text("-- previous layout\n")
    mirrored = m | {"name": "DP-2", "mirrorOf": "HDMI-A-1"}
    with (
        patch.object(d, "monitors", return_value=[m, mirrored]),
        patch.object(d, "hypr") as call,
        patch.object(d.time, "sleep", side_effect=decide),
    ):
        d.worker(request)
    assert call.call_count == 2
    assert "mirrored layouts" in d.state()["message"]
    assert d.SAVED.read_text() == "-- previous layout\n"

# No component may create a second Wayland surface.
for name in ("DisplayPanel.qml", "PolkitDialog.qml"):
    source = (Path(__file__).parent.parent / "modules/displaypolkit" / name).read_text()
    assert "PanelWindow" not in source and "WlrLayershell" not in source
    assert "Item {" in source
print("PASS: cancellation, termination, rollback failure, save failure, embedded Items")
