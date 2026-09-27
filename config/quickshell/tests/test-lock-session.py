#!/usr/bin/python3
"""Run: /usr/bin/python3 config/quickshell/scripts/test-lock-session.py"""

import os
import runpy
from pathlib import Path

Bridge = runpy.run_path(str(Path(__file__).with_name("lock-session.py")))["Bridge"]


def test_bridge():
    events = []
    acquired = []

    def inhibit():
        fd = os.open(os.devnull, os.O_RDONLY)
        acquired.append(fd)
        return fd

    bridge = Bridge(inhibit, events.append)
    try:
        bridge.acquire()
        bridge.acquire()
        assert len(acquired) == 1
        bridge.lock()
        bridge.prepare(True)
        bridge.prepare(True)
        assert events == ["lock", "sleep"]
        bridge.feed(b"secured\n")  # Earlier session lock must not release sleep FD.
        assert bridge.fd is not None
        fd = bridge.fd
        bridge.feed(b"sec")
        assert bridge.fd == fd
        bridge.feed(b"ured\n")  # Already-secured QML still acknowledges this request.
        assert bridge.fd is None
        try:
            os.fstat(fd)
        except OSError:
            pass
        else:
            raise AssertionError("inhibitor FD leaked")
        bridge.prepare(False)
        assert bridge.fd is not None and len(acquired) == 2
        assert events[-1] == "resume"
        bridge.prepare(False)
        assert len(acquired) == 2

        bridge.prepare(True)
        bridge.prepare(False)  # Timeout/cancel before acknowledgment.
        bridge.prepare(True)
        bridge.feed(b"secured\n")  # Stale sleep acknowledgment.
        assert bridge.fd is not None
        bridge.feed(b"secured\n")
        assert bridge.fd is None
        bridge.prepare(False)
        bridge.lock()
        bridge.lock()
        bridge.feed(b"secured\nsecured\n")
        assert bridge.fd is not None  # Ordinary locks keep awake inhibitor.
    finally:
        bridge.close()
        bridge.close()

    for invalid in (b"unlock\n", b"secured\n", b"xxxxxxxx"):
        other = Bridge(inhibit, events.append)
        try:
            other.feed(invalid)
        except ValueError:
            pass
        else:
            raise AssertionError(f"accepted invalid input: {invalid!r}")


def test_failed_output():
    def emit(_line):
        raise BrokenPipeError("parent gone")

    bridge = Bridge(lambda: os.open(os.devnull, os.O_RDONLY), emit)
    try:
        bridge.acquire()
        try:
            bridge.prepare(True)
        except BrokenPipeError:
            pass
        else:
            raise AssertionError("stdout failure ignored")
    finally:
        bridge.close()
    assert bridge.fd is None


if __name__ == "__main__":
    test_bridge()
    test_failed_output()
    print("lock-session tests passed")
