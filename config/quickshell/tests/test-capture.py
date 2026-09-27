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

    def test_capture_window_and_stop_button(self):
        modules = Path(__file__).resolve().parents[1] / "modules"
        island = (modules / "Island.qml").read_text()
        self.assertIn("CaptureWindow {", island)
        self.assertNotIn("CapturePanel {", island)
        self.assertIn('captureHidden = action === "pick"', island)
        self.assertIn(
            'if (panel !== "capture")\n                            win.dismiss();',
            island,
        )
        self.assertIn("win.captureSelecting ? null", island)
        self.assertIn("!capture.opened && !captureSelecting", island)
        self.assertIn("!capture.opened && !win.captureSelecting", island)
        bar = (modules / "Bar.qml").read_text()
        self.assertIn("visible: barWin.capture.recording", bar)
        self.assertIn("onClicked: barWin.capture.stop()", bar)

    def test_annotate_removed(self):
        with patch.object(self.capture, "run") as run:
            self.capture.busy.acquire()
            self.capture.execute({"action": "annotate"})
            run.assert_not_called()
        self.assertEqual(
            self.events[-2], {"event": "error", "message": "Unknown capture action"}
        )
        self.assertEqual(self.events[-1]["event"], "idle")

    def test_capabilities_without_swappy(self):
        with patch("shutil.which", return_value=None):
            self.capture.capabilities()
        self.assertNotIn("swappy", self.events[-1]["tools"])
        self.assertIn("magick", self.events[-1]["tools"])

    def test_screen_selection_cannot_drag_area(self):
        with patch.object(self.capture, "run", return_value="DP-1") as run:
            self.assertEqual(self.capture.slurp({}, screen=True), "DP-1")
            args = run.call_args.args[0]
            self.assertIn("-o", args)
            self.assertIn("-r", args)
            self.assertEqual(args[args.index("-f") + 1], "%o")
        with patch.object(self.capture, "run", return_value="10,20 300x200") as run:
            self.capture.slurp({}, screen=False)
            self.assertNotIn("-r", run.call_args.args[0])
            self.assertNotIn("-o", run.call_args.args[0])

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


@unittest.skipUnless(shutil.which("magick"), "ImageMagick missing")
class AnnotationTests(unittest.TestCase):
    def setUp(self):
        self.events = []
        self.capture = module.Capture(self.events.append)
        self.addCleanup(self.capture.close)
        self.original = Path(self.capture.temp.name) / "original.png"
        subprocess.run(
            ["magick", "-size", "800x180", "xc:white", str(self.original)], check=True
        )
        self.capture.preview = self.original
        self.request = {
            "action": "edit",
            "operation": "marker",
            "x": 10,
            "y": 10,
            "width": 100,
            "height": 100,
            "points": [[10, 10], [50, 10], [50, 80]],
            "color": "#ff0000",
            "strokeWidth": 4,
        }

    def pixels(self, path):
        return subprocess.check_output(["magick", str(path), "-depth", "8", "rgb:-"])

    def pixel(self, path, x, y):
        pixels = self.pixels(path)
        offset = (y * 800 + x) * 3
        return pixels[offset : offset + 3]

    def undo(self):
        self.capture.busy.acquire()
        self.capture.execute({"action": "undo"})

    def test_strokes_and_undo(self):
        original = self.pixels(self.original)
        for operation, point in (
            ("marker", (50, 40)),
            ("arrow", (50, 40)),
            ("rectangle", (10, 40)),
        ):
            with self.subTest(operation=operation):
                request = self.request | {"operation": operation}
                if operation == "arrow":
                    request["points"] = [[10, 40], [30, 100], [90, 40]]
                self.capture.edit(request)
                edited = self.capture.preview
                self.assertTrue(self.capture.png_ready(edited))
                self.assertNotEqual(self.pixels(edited), original)
                self.assertEqual(self.pixel(edited, *point), b"\xff\x00\x00")
                if operation == "arrow":
                    self.assertEqual(self.pixel(edited, 30, 100), b"\xff\xff\xff")
                    # Arrowhead extends off the horizontal shaft.
                    self.assertNotEqual(self.pixel(edited, 80, 35), b"\xff\xff\xff")
                self.undo()
                self.assertFalse(edited.exists())
                self.assertEqual(self.capture.preview, self.original)
                self.assertEqual(self.pixels(self.capture.preview), original)
                self.assertFalse(self.events[-2]["canUndo"])

    def test_identical_endpoints_and_limits(self):
        for operation in ("marker", "arrow"):
            for stroke, points in ((1, [[0, 0], [0, 0]]), (64, [[799, 179]] * 4096)):
                with self.subTest(operation=operation, stroke=stroke):
                    self.capture.edit(
                        self.request
                        | {
                            "operation": operation,
                            "points": points,
                            "strokeWidth": stroke,
                        }
                    )
                    self.assertTrue(self.capture.png_ready(self.capture.preview))
                    self.undo()

    def test_literal_text(self):
        secret = Path(self.capture.temp.name) / "secret.txt"
        secret.write_text("DO NOT RENDER FILE CONTENT")
        # ImageMagick reads a trusted @file verbatim, without expanding its
        # contents. Independent oracle for our escaped command-line text.
        texts = [
            "%w %[fx:1+2] %[filename] &amp; &lt;",
            "@" + str(secret),
            "  @" + str(secret),
            "' \"; image over 0,0 0,0 '@/etc/passwd'",
            r"\n \r \\ % @ &",
            " leading spaces",
            "line one\nline two",
            "\nleading newline",
            "\tleading tab",
            "trailing slash\\",
            "-write /tmp/not-an-output.png",
        ]
        for text in texts:
            with self.subTest(text=text):
                self.capture.edit(
                    self.request | {"operation": "text", "text": text, "fontSize": 18}
                )
                expected = Path(self.capture.temp.name) / "expected.png"
                literal = Path(self.capture.temp.name) / "literal.txt"
                literal.write_text(text)
                subprocess.run(
                    [
                        "magick",
                        str(self.original),
                        "-font",
                        "Adwaita-Sans",
                        "-pointsize",
                        "18",
                        "-fill",
                        "#ff0000",
                        "-stroke",
                        "none",
                        "-gravity",
                        "NorthWest",
                        "-annotate",
                        "+10+10",
                        "@" + str(literal),
                        str(expected),
                    ],
                    check=True,
                )
                self.assertEqual(
                    self.pixels(self.capture.preview), self.pixels(expected)
                )
                self.assertNotEqual(
                    self.pixels(self.capture.preview), self.pixels(self.original)
                )
                self.undo()
        self.assertEqual(secret.read_text(), "DO NOT RENDER FILE CONTENT")
        for size in (8, 144):
            self.capture.edit(
                self.request
                | {"operation": "text", "text": "a" * 500, "fontSize": size}
            )
            self.undo()

    def test_invalid_input_preserves_preview_and_history(self):
        self.capture.edit(self.request)
        preview = self.capture.preview
        history = list(self.capture.history)
        files = set(Path(self.capture.temp.name).iterdir())
        invalid = [
            {"operation": "unknown"},
            {"x": True},
            {"x": 1.5},
            {"x": -1},
            {"width": 0},
            {"width": 801},
            {"height": None},
            {"y": 180},
            {"color": None},
            {"color": "red"},
            {"color": "#ff0000; image"},
            {"color": "#ff000000"},
            {"strokeWidth": True},
            {"strokeWidth": 1.5},
            {"strokeWidth": 0},
            {"strokeWidth": 65},
            {"strokeWidth": None},
            {"points": None},
            {"points": []},
            {"points": [[0, 0]]},
            {"points": [[0, 0]] * 4097},
            {"points": [[-1, 0], [0, 0]]},
            {"points": [[800, 0], [0, 0]]},
            {"points": [[0, 180], [0, 0]]},
            {"points": [[True, 0], [0, 0]]},
            {"points": [[0.5, 0], [0, 0]]},
            {"points": [[0], [0, 0]]},
            {"points": ["0,0", [0, 0]]},
        ]
        text_request = {"operation": "text", "text": "hello", "fontSize": 18}
        invalid += [
            text_request | change
            for change in (
                {"text": None},
                {"text": ""},
                {"text": "a" * 501},
                {"text": "\x00"},
                {"text": "\ud800"},
                {"fontSize": True},
                {"fontSize": 8.5},
                {"fontSize": 7},
                {"fontSize": 145},
                {"fontSize": None},
            )
        ]
        with patch.object(self.capture, "run") as run:
            for change in invalid:
                with self.subTest(change=change), self.assertRaises(ValueError):
                    self.capture.edit(self.request | change)
                self.assertEqual(self.capture.preview, preview)
                self.assertEqual(self.capture.history, history)
                self.assertEqual(set(Path(self.capture.temp.name).iterdir()), files)
            run.assert_not_called()

    def test_failed_and_cancelled_edits_are_atomic(self):
        self.capture.edit(self.request)
        preview = self.capture.preview
        history = list(self.capture.history)
        files = set(Path(self.capture.temp.name).iterdir())
        for failure in (module.Cancelled(), RuntimeError("failed"), None):

            def fail(args, failure=failure, **kwargs):
                Path(args[-1]).write_bytes(b"partial PNG")
                if failure:
                    raise failure
                return b""

            with patch.object(self.capture, "run", side_effect=fail):
                self.capture.busy.acquire()
                self.capture.execute(self.request)
            self.assertEqual(
                self.events[-2]["event"],
                "cancelled" if isinstance(failure, module.Cancelled) else "error",
            )
            self.assertEqual(self.capture.preview, preview)
            self.assertEqual(self.capture.history, history)
            self.assertEqual(set(Path(self.capture.temp.name).iterdir()), files)
        # Real ImageMagick process cancellation leaves no new preview/history.
        self.capture.cancel.set()
        self.capture.busy.acquire()
        self.capture.execute(self.request)
        self.assertEqual(self.events[-2]["event"], "cancelled")
        self.assertEqual(self.capture.preview, preview)
        self.assertEqual(self.capture.history, history)
        self.assertEqual(set(Path(self.capture.temp.name).iterdir()), files)
        self.capture.cancel.clear()
        run = self.capture.run

        def cancel_after_render(args, **kwargs):
            result = run(args, **kwargs)
            self.capture.cancel.set()
            return result

        with patch.object(self.capture, "run", side_effect=cancel_after_render):
            self.capture.busy.acquire()
            self.capture.execute(self.request)
        self.assertEqual(self.events[-2]["event"], "cancelled")
        self.assertEqual(self.capture.preview, preview)
        self.assertEqual(self.capture.history, history)
        self.assertEqual(set(Path(self.capture.temp.name).iterdir()), files)
        self.capture.cancel.clear()
        self.undo()
        self.assertEqual(self.capture.preview, self.original)
        self.undo()
        self.assertEqual(self.events[-2]["event"], "error")


if __name__ == "__main__":
    unittest.main()
