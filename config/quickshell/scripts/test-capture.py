#!/usr/bin/env python3
"""Run with python3 config/quickshell/scripts/test-capture.py."""

import importlib.util
import json
import os
import shutil
import signal
import subprocess
import sys
import time
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "capture", Path(__file__).with_name("capture.py")
)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class CaptureTests(unittest.TestCase):
    def setUp(self):
        self.events = []
        self.capture = module.Capture(self.events.append)

    def tearDown(self):
        self.capture.close()

    def test_hyprland_window(self):
        commands = []

        def run(args, **kwargs):
            commands.append((args, kwargs))
            if args[:3] == ["hyprctl", "-j", "clients"]:
                return json.dumps(
                    [
                        {
                            "mapped": True,
                            "workspace": {"id": 2},
                            "at": [-100, 20],
                            "size": [80, 60],
                        }
                    ]
                ).encode()
            if args[:3] == ["hyprctl", "-j", "monitors"]:
                return b'[{"activeWorkspace":{"id":2}}]'
            if args[0] == "slurp":
                self.assertEqual(kwargs["data"], b"-100,20 80x60\n")
                self.assertIn("-r", args)
                return "-100,20 80x60"
            Path(args[-1]).touch()
            return b""

        with (
            patch.dict(os.environ, {"HYPRLAND_INSTANCE_SIGNATURE": "test"}),
            patch.object(self.capture, "run", side_effect=run),
            patch.object(self.capture, "png_ready", return_value=True),
        ):
            self.capture.screenshot({"mode": "window"})
        self.assertEqual(commands[-1][0][0:3], ["grim", "-g", "-100,20 80x60"])
        self.assertEqual(self.events[-1]["event"], "preview")

    @unittest.skipUnless(shutil.which("magick"), "ImageMagick missing")
    def test_edit_and_invalid_bounds(self):
        path = Path(self.capture.temp.name) / "input.png"
        subprocess.run(["magick", "-size", "20x10", "xc:white", str(path)], check=True)
        self.capture.preview = path
        self.capture.edit(
            {
                "operation": "rectangle",
                "x": 1,
                "y": 1,
                "width": 8,
                "height": 5,
                "color": "#ff0000",
            }
        )
        self.assertTrue(self.capture.png_ready(self.capture.preview))
        self.capture.edit(
            {"operation": "crop", "x": 0, "y": 0, "width": 10, "height": 5}
        )
        size = subprocess.check_output(
            ["magick", "identify", "-format", "%wx%h", str(self.capture.preview)]
        )
        self.assertEqual(size, b"10x5")
        old = self.capture.preview
        with self.assertRaises(ValueError):
            self.capture.edit(
                {"operation": "crop", "x": -1, "y": 0, "width": 10, "height": 5}
            )
        self.assertEqual(old, self.capture.preview)
        self.capture.busy.acquire()
        self.capture.execute({"action": "undo"})
        size = subprocess.check_output(
            ["magick", "identify", "-format", "%wx%h", str(self.capture.preview)]
        )
        self.assertEqual(size, b"20x10")
        self.assertTrue(self.capture.history)

    def test_record_stop_preserves_video(self):
        def run(args, **kwargs):
            kwargs["recording"].write_bytes(b"finalized video")
            raise module.Cancelled()

        with (
            patch.object(self.capture, "slurp", return_value="DP-1"),
            patch.object(
                self.capture, "folder", return_value=Path(self.capture.temp.name)
            ),
            patch.object(self.capture, "run", side_effect=run),
            patch.dict(os.environ, {"XDG_RUNTIME_DIR": self.capture.temp.name}),
        ):
            self.capture.record({"mode": "screen"})
        self.assertEqual(self.events[-1]["kind"], "recording")
        self.assertEqual(Path(self.events[-1]["path"]).read_bytes(), b"finalized video")

    def test_copy_and_save_preview(self):
        self.capture.preview = Path(self.capture.temp.name) / "preview.png"
        self.capture.preview.write_bytes(b"test image")
        with patch.object(self.capture, "run", return_value=b"") as run:
            self.capture.busy.acquire()
            self.capture.execute({"action": "copy-image"})
            self.assertEqual(run.call_args.kwargs["data"], b"test image")
            self.assertTrue(run.call_args.kwargs["forks"])
            self.capture.busy.acquire()
            self.capture.execute({"action": "copy-color", "text": "#123456"})
            self.assertTrue(run.call_args.kwargs["forks"])
        with patch.object(
            self.capture, "folder", return_value=Path(self.capture.temp.name)
        ):
            self.capture.busy.acquire()
            self.capture.execute({"action": "save"})
        saved = next(event for event in self.events if event["event"] == "saved")
        self.assertEqual(Path(saved["path"]).read_bytes(), b"test image")

    def test_cancel_child(self):
        self.capture.cancel.set()
        with self.assertRaises(module.Cancelled):
            self.capture.run(["sleep", "5"])

    def test_forking_clipboard_owner_does_not_hold_completion_open(self):
        pid_file = Path(self.capture.temp.name) / "owner.pid"
        script = (
            "import os,sys,time; from pathlib import Path; "
            "sys.stdin.buffer.read(); pid=os.fork(); "
            "Path(sys.argv[1]).write_text(str(pid)) if pid else None; "
            "os._exit(0) if pid else time.sleep(10)"
        )
        started = time.monotonic()
        try:
            self.capture.run(
                [sys.executable, "-c", script, str(pid_file)],
                data=b"clipboard payload",
                timeout=1,
                forks=True,
            )
            self.assertLess(time.monotonic() - started, 1)
        finally:
            if pid_file.exists():
                os.kill(int(pid_file.read_text()), signal.SIGTERM)

    def test_invalid_selection(self):
        with (
            patch.object(self.capture, "run", return_value="0,0 0x20"),
            self.assertRaises(RuntimeError),
        ):
            self.capture.slurp({})


if __name__ == "__main__":
    unittest.main()
