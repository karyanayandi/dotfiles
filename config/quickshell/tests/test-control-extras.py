#!/usr/bin/python3
"""Offline regression checks. No real device operations or credentials."""

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


def load(name):
    spec = importlib.util.spec_from_file_location(
        name, Path(__file__).with_name(name + ".py")
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


codex = load("codex-limits")
drives = load("removable-drives")
P = drives.PREFIX


class ExtrasTest(unittest.TestCase):
    def test_cache_validation_and_latest(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            (home / "sessions").mkdir()
            events = []
            for day, used in [(2, 23), (1, 5)]:
                events.append(
                    json.dumps(
                        {
                            "type": "event_msg",
                            "timestamp": f"2026-01-0{day}T12:00:00Z",
                            "payload": {
                                "type": "token_count",
                                "rate_limits": {
                                    "primary": {
                                        "used_percent": used,
                                        "window_minutes": 300,
                                        "resets_at": 1767360000,
                                    }
                                },
                            },
                        }
                    )
                )
            (home / "sessions" / "test.jsonl").write_text(
                "not json\n" + "\n".join(events) + "\n{partial"
            )
            result = codex.cached_limits(home)
            self.assertEqual(result["windows"][0]["usedPercent"], 23)
            self.assertEqual(set(result), {"observedAt", "windows"})
            (home / "sessions" / "test.jsonl").write_text("{}\n")
            self.assertIsNone(codex.cached_limits(home))
        for used in [True, -1, 101, float("nan"), "20"]:
            self.assertIsNone(
                codex.window(
                    {"used_percent": used, "window_minutes": 300, "resets_at": 1}
                )
            )

    def test_drives_fail_closed(self):
        objects = {
            "/drive": {P + "Drive": {"Removable": True}},
            "/volume": {
                P + "Block": {
                    "Drive": "/drive",
                    "HintSystem": False,
                    "HintIgnore": False,
                },
                P + "Filesystem": {"MountPoints": []},
            },
        }
        self.assertTrue(drives.removable(objects, "/volume"))
        self.assertTrue(drives.ejectable(objects, "/drive"))
        objects["/volume"][P + "Filesystem"]["MountPoints"] = [list(b"/media/test\0")]
        self.assertEqual(drives.mounts(objects["/volume"]), ["/media/test"])
        self.assertFalse(drives.ejectable(objects, "/drive"))
        objects["/volume"][P + "Filesystem"]["MountPoints"] = []
        objects["/drive"][P + "Drive"] = {"ConnectionBus": "usb", "Removable": False}
        self.assertFalse(drives.removable(objects, "/volume"))
        objects["/drive"][P + "Drive"]["Removable"] = True
        objects["/sibling"] = {P + "Block": {"Drive": "/drive", "HintSystem": True}}
        self.assertFalse(drives.removable(objects, "/volume"))
        self.assertFalse(drives.ejectable(objects, "/drive"))
        del objects["/sibling"]
        objects["/volume"][P + "Filesystem"]["MountPoints"] = [list(b"/\0")]
        self.assertFalse(drives.removable(objects, "/volume"))
        objects["/volume"][P + "Filesystem"]["MountPoints"] = []
        objects["/volume"][P + "Encrypted"] = {}
        self.assertFalse(drives.ejectable(objects, "/drive"))
        del objects["/volume"][P + "Encrypted"]
        objects["/volume"][P + "Swapspace"] = {"Active": True}
        self.assertFalse(drives.ejectable(objects, "/drive"))
        del objects["/volume"][P + "Block"]["HintSystem"]
        self.assertFalse(drives.removable(objects, "/volume"))
        self.assertFalse(drives.removable(objects, "/unknown"))


if __name__ == "__main__":
    unittest.main()
