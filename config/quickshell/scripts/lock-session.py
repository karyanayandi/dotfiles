#!/usr/bin/python3
"""Quickshell/logind bridge. Requires dbus-python, PyGObject/GLib and system logind.

Run with system Python, stdin/stdout pipes owned by Quickshell. stdout emits
'lock\n' for session Lock, 'sleep\n' before sleep, and 'resume\n' when awake.
Reply 'secured\n' EXACTLY ONCE per lock line, in order, only after WlSessionLock
confirms secure (reply again if already secure). Never cache a previous reply.
Unlock is deliberately not subscribed to: only local authentication may unlock.

A sleep delay inhibitor is held while awake and released only for the matching
sleep lock acknowledgment. logind's InhibitDelayMaxSec still bounds the delay;
this cannot guarantee locking if the compositor hangs or either process dies.
EOF, invalid input, broken stdout, termination, or logind loss exits and closes
our inhibitor. Supervisor must treat exit as failure and restart the bridge.
No idle timer, authentication, or QML wiring is provided here. Starting during
sleep preparation is best-effort: logind may already have exhausted its delay.
"""

import logging
import os
import signal
import sys
from collections import deque

logger = logging.getLogger(__name__)


class Bridge:
    def __init__(self, inhibit, emit):
        self.inhibit = inhibit
        self.emit = emit
        self.fd = None
        self.sleeping = False
        self.generation = 0
        self.pending = deque()
        self.buffer = b""

    def acquire(self):
        if self.fd is None:
            self.fd = self.inhibit()

    def close(self):
        if self.fd is not None:
            os.close(self.fd)
            self.fd = None

    def lock(self, token=None):
        self.pending.append(token)
        self.emit("sleep" if token is not None else "lock")

    def prepare(self, sleeping):
        if sleeping == self.sleeping:
            return
        self.sleeping = sleeping
        if sleeping:
            self.generation += 1
            self.lock(self.generation)
        else:
            self.acquire()
            self.emit("resume")

    def feed(self, data):
        self.buffer += data
        while b"\n" in self.buffer:
            line, self.buffer = self.buffer.split(b"\n", 1)
            if line != b"secured" or not self.pending:
                raise ValueError("expected one secured line per lock request")
            token = self.pending.popleft()
            if self.sleeping and token == self.generation:
                self.close()
        if len(self.buffer) > len(b"secured"):
            raise ValueError("invalid stdin line")


def main():
    import dbus
    from dbus.mainloop.glib import DBusGMainLoop
    from gi.repository import GLib, GLibUnix

    DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    name = "org.freedesktop.login1"
    manager_path = "/org/freedesktop/login1"
    manager_object = bus.get_object(name, manager_path)
    manager = dbus.Interface(manager_object, name + ".Manager")
    session_id = os.environ.get("XDG_SESSION_ID")
    session_path = (
        manager.GetSession(session_id)
        if session_id
        else manager.GetSessionByPID(os.getpid())
    )
    loop = GLib.MainLoop()
    bridge = Bridge(
        lambda: manager.Inhibit(
            "sleep", "Quickshell", "Wait for session lock to become secure", "delay"
        ).take(),
        lambda line: print(line, flush=True),
    )
    status = 0

    def stop(message=None):
        nonlocal status
        if message:
            print(f"lock-session: {message}", file=sys.stderr)
            status = 1
        loop.quit()
        return False

    def guarded(callback):
        def run(*args):
            try:
                return callback(*args)
            except Exception as error:
                # GLib otherwise swallows callback errors and leaves the bridge alive.
                logger.exception("Lock bridge callback failed")
                return stop(str(error))

        return run

    def read_stdin(_fd, condition):
        if condition & GLib.IO_NVAL:
            return stop("stdin unavailable")
        try:
            data = os.read(0, 4096)
        except BlockingIOError:
            return True
        if not data:
            return stop("stdin closed")
        bridge.feed(data)
        return True

    def owner_changed(_name, _old, _new):
        stop("logind owner changed; restart required")

    try:
        bus.add_signal_receiver(
            guarded(lambda: bridge.lock()),
            signal_name="Lock",
            dbus_interface=name + ".Session",
            bus_name=name,
            path=str(session_path),
        )
        bus.add_signal_receiver(
            guarded(bridge.prepare),
            signal_name="PrepareForSleep",
            dbus_interface=name + ".Manager",
            bus_name=name,
            path=manager_path,
        )
        bus.add_signal_receiver(
            owner_changed,
            signal_name="NameOwnerChanged",
            dbus_interface="org.freedesktop.DBus",
            bus_name="org.freedesktop.DBus",
            path="/org/freedesktop/DBus",
            arg0=name,
        )
        bus.call_on_disconnection(lambda _bus: stop("system bus disconnected"))
        os.set_blocking(0, False)
        GLib.io_add_watch(
            0,
            GLib.IO_IN | GLib.IO_HUP | GLib.IO_ERR | GLib.IO_NVAL,
            guarded(read_stdin),
        )
        for signum in (signal.SIGINT, signal.SIGTERM):
            GLibUnix.signal_add(GLib.PRIORITY_DEFAULT, signum, stop)
        bridge.acquire()
        properties = dbus.Interface(manager_object, "org.freedesktop.DBus.Properties")
        bridge.prepare(bool(properties.Get(name + ".Manager", "PreparingForSleep")))
        if not bridge.sleeping:
            bridge.emit("resume")
        loop.run()
    finally:
        bridge.close()
    return status


if __name__ == "__main__":
    sys.exit(main())
