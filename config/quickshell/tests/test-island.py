#!/usr/bin/env python3
"""Opt-in live UI checks. No passwords, mount operations, or display changes."""

import argparse
import json
import subprocess
import time

PANELS = [
    ("audioMixer", ["open"], "audio"),
    ("mediaPanel", ["open"], "media"),
    ("calendarPanel", ["open"], "calendar"),
    ("displays", ["open"], "displays"),
    ("capture", ["open", "area"], "capture"),
    ("colorPicker", ["open"], "color"),
]


def ipc(target, *arguments):
    return subprocess.check_output(
        ["qs", "ipc", "call", target, *arguments], text=True, timeout=4
    ).strip()


def state():
    return json.loads(ipc("island", "status"))


def wait_for(predicate):
    deadline = time.monotonic() + 4
    while time.monotonic() < deadline:
        current = state()
        if predicate(current):
            return current
        time.sleep(0.05)
    raise AssertionError(current)


def check_panels():
    try:
        for target, arguments, view in PANELS:
            ipc(target, *arguments)
            current = wait_for(
                lambda current, expected=view: current["view"] == expected
            )
            assert current["panels"] == [view], current
        print("PASS one island panel at a time")
    finally:
        for target, _, _ in PANELS:
            ipc(target, "close")


def check_selector():
    try:
        ipc("capture", "open", "area")
        wait_for(lambda current: current["view"] == "capture")
        for _ in range(20):
            current = state()
            assert current["view"] == "capture", current
            if current["focus"] == "captureStart":
                break
            subprocess.run(["wtype", "-k", "Tab"], check=True)
            time.sleep(0.05)
        assert state()["focus"] == "captureStart"
        subprocess.run(["wtype", "-k", "space"], check=True)
        wait_for(lambda current: current["captureHidden"])
        # Allow unmap delay and slurp's keyboard grab to reach the compositor.
        time.sleep(0.3)
        # Escape cancels the real slurp selector; no screenshot is taken.
        subprocess.run(["wtype", "-k", "Escape"], check=True)
        wait_for(
            lambda current: (
                current["view"] == "capture" and not current["captureHidden"]
            )
        )
        print("PASS keyboard capture, island unmap, selector cancellation and restore")
    finally:
        ipc("capture", "stop")
        ipc("capture", "close")


def check_polkit(with_popup=False):
    assert ipc("polkit", "status") == "registered"
    assert not state()["authentication"], "Another authentication request is active"
    if with_popup:
        ipc("displays", "open")
        wait_for(lambda current: current["view"] == "displays")
        time.sleep(0.2)
        subprocess.run(["wtype", "-k", "space"], check=True)
    process = subprocess.Popen(
        ["pkexec", "--disable-internal-agent", "/usr/bin/true"],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        wait_for(
            lambda current: (
                current["authentication"] and current["focus"] == "polkitResponse"
            )
        )
        for target, arguments, _ in PANELS + [
            ("launcher", ["open", "apps"], ""),
            ("controls", ["toggle"], ""),
            ("notifications", ["open"], ""),
        ]:
            ipc(target, *arguments)
            time.sleep(0.1)
            current = state()
            assert current["view"] == "polkit", current
            assert current["focus"] == "polkitResponse", current
            assert not current["panels"], current
        print("PASS genuine Polkit request retains exclusive password focus")
    finally:
        if process.poll() is None:
            ipc("polkit", "cancel")
        try:
            process.wait(timeout=4)
        except subprocess.TimeoutExpired:
            process.terminate()
            process.wait(timeout=3)
    assert process.returncode == 126, "Expected dismissed request, not authorization"
    wait_for(lambda current: current["view"] == "bar")
    print("PASS native authentication cancellation")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--live", action="store_true", help="Open and close live island panels"
    )
    parser.add_argument(
        "--selector", action="store_true", help="Use wtype to cancel a real selector"
    )
    parser.add_argument(
        "--polkit",
        action="store_true",
        help="Open and cancel a harmless native auth request",
    )
    args = parser.parse_args()
    if not args.live:
        print("SKIP live UI checks; opt in with --live [--selector] [--polkit]")
        return
    assert state()["view"] == "bar", "Close existing panels before testing"
    assert not json.loads(ipc("capture", "status"))["busy"], "Capture is busy"
    check_panels()
    if args.selector:
        check_selector()
    if args.polkit:
        check_polkit(with_popup=args.selector)


if __name__ == "__main__":
    main()
