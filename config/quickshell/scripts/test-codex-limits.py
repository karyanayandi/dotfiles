#!/usr/bin/python3
"""Synthetic stdio peers only. No login, real sessions, or model calls."""

import contextlib
import importlib.util
import io
import json
import sys
import time
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "codex_limits", Path(__file__).with_name("codex-limits.py")
)
codex = importlib.util.module_from_spec(spec)
spec.loader.exec_module(codex)

WINDOW = {"usedPercent": 23, "windowDurationMins": 300, "resetsAt": 1900000000}
RESULT = {"rateLimits": {"primary": WINDOW}}
PEER = """
import json, sys, time

def read():
    return json.loads(sys.stdin.readline())
def send(value):
    print(json.dumps(value), flush=True)

assert read() == {"id": 1, "method": "initialize", "params": {
    "clientInfo": {"name": "quickshell_limits", "version": "1.0"}}}
send({"method": "unrelated", "params": {"private": "DO_NOT_EMIT"}})
send({"id": 1, "result": {}})
assert read() == {"method": "initialized"}
assert read() == {"id": 2, "method": "account/rateLimits/read"}
"""


class LimitsTest(unittest.TestCase):
    def test_widget_is_information_only(self):
        widget = (
            Path(__file__).parent.parent / "components/CodexLimits.qml"
        ).read_text()
        self.assertNotIn("ControlAction", widget)
        self.assertNotIn("onClicked", widget)

    def run_peer(self, suffix, timeout=2):
        return codex.live_limits([sys.executable, "-c", PEER + suffix], timeout)

    def test_handshake_and_projection(self):
        result = self.run_peer(
            'send({"id": 999, "result": {}})\n'
            f'send({{"id": 2, "result": {RESULT!r}}})\n'
            "time.sleep(10)\n"
        )
        self.assertEqual(set(result), {"source", "observedAt", "windows"})
        self.assertEqual(result["source"], "live")
        self.assertEqual(result["windows"][0]["usedPercent"], 23)
        self.assertNotIn("DO_NOT_EMIT", json.dumps(result))

    def test_child_reaped_even_when_termination_ignored(self):
        children = []
        popen = codex.subprocess.Popen

        def spawn(*args, **kwargs):
            child = popen(*args, **kwargs)
            children.append(child)
            return child

        with patch.object(codex.subprocess, "Popen", side_effect=spawn):
            self.run_peer(
                "import signal\nsignal.signal(signal.SIGTERM, signal.SIG_IGN)\n"
                f'send({{"id": 2, "result": {RESULT!r}}})\n'
                "time.sleep(10)"
            )
        self.assertIsNotNone(children[0].poll())
        self.assertTrue(children[0].stdin.closed)
        self.assertTrue(children[0].stdout.closed)

    def test_bucket_selection(self):
        response = {
            **RESULT,
            "rateLimitsByLimitId": {
                "codex": {
                    "limitId": "codex",
                    "secondary": {**WINDOW, "usedPercent": 42},
                },
                "other": {"primary": WINDOW},
            },
        }
        result = self.run_peer(f'send({{"id": 2, "result": {response!r}}})')
        self.assertEqual(result["windows"][0]["usedPercent"], 42)
        for response in [
            {**RESULT, "rateLimitsByLimitId": {"other": {"primary": WINDOW}}},
            {"rateLimits": {"limitId": "other", "primary": WINDOW}},
            {"rateLimits": {"primary": {**WINDOW, "usedPercent": True}}},
            {"rateLimits": {"primary": {**WINDOW, "resetsAt": None}}},
            {"rateLimits": {"credits": {"unlimited": True}}},
            {**RESULT, "rateLimitsByLimitId": "invalid"},
            {"rateLimits": {"primary": {**WINDOW, "usedPercent": 10**500}}},
        ]:
            with (
                self.subTest(response=response),
                self.assertRaises(codex.LiveUnavailable),
            ):
                self.run_peer(f'send({{"id": 2, "result": {response!r}}})')

    def test_failures_are_bounded_and_sanitized(self):
        for suffix in [
            'send({"id": 2, "error": {"code": -32601, "message": "DO_NOT_EMIT"}})',
            'print("malformed DO_NOT_EMIT", flush=True)',
            'send({"id": 2, "result": None})',
            'print("x" * (1024 * 1024 + 1), flush=True)',
            "sys.exit(0)",
            "time.sleep(10)",
        ]:
            with self.subTest(suffix=suffix):
                start = time.monotonic()
                with self.assertRaises(codex.LiveUnavailable) as raised:
                    self.run_peer(suffix, timeout=0.3)
                self.assertNotIn("DO_NOT_EMIT", str(raised.exception))
                self.assertLess(time.monotonic() - start, 1.5)
        with self.assertRaisesRegex(codex.LiveUnavailable, "not found"):
            codex.live_limits(["/nonexistent/codex"])
        with self.assertRaisesRegex(codex.LiveUnavailable, "timed out"):
            codex.live_limits(
                [sys.executable, "-c", "import time; time.sleep(10)"], 0.1
            )

    def test_main_fallback_and_live_precedence(self):
        for cached in [None, {"observedAt": 1, "windows": []}]:
            with (
                patch.object(
                    codex,
                    "live_limits",
                    side_effect=codex.LiveUnavailable("CLI rejected limits request"),
                ),
                patch.object(codex, "cached_limits", return_value=cached),
                contextlib.redirect_stdout(io.StringIO()) as output,
            ):
                codex.main()
            result = json.loads(output.getvalue())
            if cached:
                self.assertEqual(result["data"]["source"], "cache")
                self.assertIn("account unverified", result["message"])
            else:
                self.assertIsNone(result["data"])
                self.assertIn("no cached limits", result["message"])
        with (
            patch.object(codex, "live_limits", return_value={"source": "live"}),
            patch.object(codex, "cached_limits") as cache,
            contextlib.redirect_stdout(io.StringIO()),
        ):
            codex.main()
            cache.assert_not_called()


if __name__ == "__main__":
    unittest.main()
