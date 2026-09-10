#!/usr/bin/env python3
"""JSON-lines capture worker. Owns children; stdin EOF stops recording safely."""

import fcntl
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path


class Cancelled(Exception):
    pass


class Capture:
    def __init__(self, emit):
        self.emit = emit
        self.cancel = threading.Event()
        self.busy = threading.Lock()
        self.thread = None
        self.preview = None
        self.history = []
        self.temp = tempfile.TemporaryDirectory(prefix="quickshell-capture-")

    def run(
        self,
        args,
        *,
        data=None,
        selector=False,
        recording=None,
        timeout=None,
        forks=False,
    ):
        started = time.monotonic()
        announced = False
        # wl-copy forks its selection owner. Inherited PIPEs never reach EOF while
        # that owner is alive, even after the original command has exited.
        with (
            tempfile.TemporaryFile() as fork_errors,
            subprocess.Popen(
                args,
                stdin=subprocess.PIPE if data is not None else subprocess.DEVNULL,
                stdout=subprocess.DEVNULL if forks else subprocess.PIPE,
                stderr=fork_errors if forks else subprocess.PIPE,
            ) as child,
        ):
            try:
                while True:
                    if self.cancel.is_set():
                        raise Cancelled()
                    if timeout and time.monotonic() - started > timeout:
                        raise RuntimeError(f"{args[0]} timed out")
                    try:
                        out, err = child.communicate(input=data, timeout=0.15)
                        break
                    except subprocess.TimeoutExpired:
                        data = None
                    if (
                        recording
                        and not announced
                        and time.monotonic() - started >= 0.5
                    ):
                        announced = True
                        self.emit({"event": "recording", "path": str(recording)})
                if child.returncode:
                    if forks:
                        fork_errors.seek(0)
                        err = fork_errors.read()
                    message = err.decode(errors="replace").strip()
                    if selector and (not message or "cancel" in message.lower()):
                        raise Cancelled()
                    raise RuntimeError(
                        message[-1500:] or f"{args[0]} exited {child.returncode}"
                    )
                return out.decode().strip() if selector else out or b""
            finally:
                if child.poll() is None:
                    # Signal only our child, never a process name or a reused PID file.
                    child.send_signal(signal.SIGINT if recording else signal.SIGTERM)
                    try:
                        child.communicate(timeout=10 if recording else 2)
                    except subprocess.TimeoutExpired:
                        child.kill()
                        child.communicate()
                        raise RuntimeError(
                            "Capture process hung and was killed; output may be incomplete"
                        )
                    if recording and child.returncode not in (0, 255, -signal.SIGINT):
                        raise RuntimeError(
                            f"Recorder failed while stopping: {child.returncode}"
                        )

    def slurp(self, request, screen=False, rectangles=None):
        args = ["slurp"]
        for flag, key in (("-b", "background"), ("-c", "border"), ("-s", "selection")):
            color = request.get(key, "")
            if re.fullmatch(r"#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?", color):
                args += [flag, color]
        args += ["-o", "-f", "%o"] if screen else ["-f", "%x,%y %wx%h"]
        if rectangles is not None:
            args += ["-r"]
        selected = self.run(args, data=rectangles, selector=True)
        if not selected:
            raise Cancelled()
        if not screen and not re.fullmatch(r"-?\d+,-?\d+ [1-9]\d*x[1-9]\d*", selected):
            raise RuntimeError("Invalid area from slurp")
        return selected

    def capabilities(self):
        tools = {
            name: bool(shutil.which(name))
            for name in (
                "grim",
                "slurp",
                "hyprctl",
                "magick",
                "niri",
                "wf-recorder",
                "wl-copy",
                "hyprpicker",
                "pactl",
            )
        }
        window = bool(
            os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
            and all(tools[name] for name in ("hyprctl", "grim", "slurp"))
        )
        if (
            not window
            and not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
            and tools["niri"]
        ):
            try:
                help_text = self.run(
                    ["niri", "msg", "action", "screenshot-window", "--help"], timeout=3
                )
                pick_help = self.run(["niri", "msg", "--help"], timeout=3)
                window = b"--path" in help_text and b"pick-window" in pick_help
            except RuntimeError:
                pass
        sources = [{"name": "", "description": "No audio"}]
        if tools["pactl"]:
            try:
                raw = self.run(["pactl", "--format=json", "list", "sources"], timeout=3)
                for source in json.loads(raw):
                    sources.append(
                        {
                            "name": source["name"],
                            "description": source.get("description", source["name"]),
                        }
                    )
            except (RuntimeError, ValueError, KeyError):
                pass
        self.emit(
            {
                "event": "capabilities",
                "tools": tools,
                "window": window,
                "sources": sources,
            }
        )

    def screenshot(self, request):
        mode = request.get("mode")
        path = Path(self.temp.name) / f"preview-{time.time_ns()}.png"
        try:
            if mode == "window" and os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
                clients = json.loads(self.run(["hyprctl", "-j", "clients"], timeout=3))
                workspaces = json.loads(
                    self.run(["hyprctl", "-j", "monitors"], timeout=3)
                )
                visible = {
                    m[key]["id"]
                    for m in workspaces
                    for key in ("activeWorkspace", "specialWorkspace")
                    if key in m
                }
                rectangles = []
                for client in clients:
                    if (
                        not client.get("mapped")
                        or client.get("hidden")
                        or (
                            client["workspace"]["id"] not in visible
                            and not client.get("pinned")
                        )
                    ):
                        continue
                    x, y = client["at"]
                    w, h = client["size"]
                    if w > 0 and h > 0:
                        rectangles.append(f"{int(x)},{int(y)} {int(w)}x{int(h)}")
                if not rectangles:
                    raise RuntimeError("No visible windows to capture")
                geometry = self.slurp(
                    request, rectangles=("\n".join(rectangles) + "\n").encode()
                )
                self.run(["grim", "-g", geometry, str(path)], timeout=15)
            elif mode == "window":
                selected = json.loads(
                    self.run(["niri", "msg", "--json", "pick-window"], selector=True)
                )
                if not selected:
                    raise Cancelled()
                self.run(
                    [
                        "niri",
                        "msg",
                        "action",
                        "screenshot-window",
                        "--id",
                        str(selected["id"]),
                        "--path",
                        str(path),
                    ],
                    timeout=5,
                )
                # Niri acknowledges before its asynchronous PNG write completes.
                deadline = time.monotonic() + 5
                while not self.png_ready(path):
                    if self.cancel.wait(0.05):
                        raise Cancelled()
                    if time.monotonic() > deadline:
                        raise RuntimeError("Niri did not produce a complete screenshot")
            elif mode in ("screen", "area"):
                selected = self.slurp(request, mode == "screen")
                self.run(
                    ["grim", "-o" if mode == "screen" else "-g", selected, str(path)],
                    timeout=15,
                )
            else:
                raise ValueError("Choose screen, window, or area")
            if not self.png_ready(path):
                raise RuntimeError("Capture did not produce a complete PNG")
            old = self.preview
            self.preview = path
            if old:
                old.unlink(missing_ok=True)
            for previous in self.history:
                previous.unlink(missing_ok=True)
            self.history.clear()
            self.emit(
                {
                    "event": "preview",
                    "path": str(path),
                    "url": path.as_uri(),
                    "canUndo": False,
                }
            )
        finally:
            if path != self.preview:
                path.unlink(missing_ok=True)

    def edit(self, request):
        if not self.preview:
            raise ValueError("Take a screenshot first")
        import struct

        with self.preview.open("rb") as image:
            image.seek(16)
            width, height = struct.unpack(">II", image.read(8))
        values = [request.get(key) for key in ("x", "y", "width", "height")]
        if any(type(value) is not int for value in values):
            raise ValueError("Rectangle must use integer pixels")
        x, y, w, h = values
        if x < 0 or y < 0 or w < 1 or h < 1 or x + w > width or y + h > height:
            raise ValueError("Rectangle is outside the screenshot")
        path = Path(self.temp.name) / f"preview-{time.time_ns()}.png"
        args = ["magick", str(self.preview)]
        if request.get("operation") == "crop":
            args += ["-crop", f"{w}x{h}+{x}+{y}", "+repage"]
        elif request.get("operation") == "rectangle":
            color = request.get("color", "")
            if not re.fullmatch(r"#[0-9a-fA-F]{6}", color):
                raise ValueError("Invalid annotation color")
            args += [
                "-fill",
                "none",
                "-stroke",
                color,
                "-strokewidth",
                "3",
                "-draw",
                f"rectangle {x},{y} {x + w - 1},{y + h - 1}",
            ]
        else:
            raise ValueError("Unknown edit operation")
        try:
            self.run(args + [str(path)], timeout=15)
            if not self.png_ready(path):
                raise RuntimeError("Image edit did not produce a complete PNG")
            self.history.append(self.preview)
            # ponytail: keep 20 bitmap undo steps; use vector edits if memory becomes an issue.
            if len(self.history) > 20:
                self.history.pop(0).unlink(missing_ok=True)
            self.preview = path
            self.emit(
                {
                    "event": "preview",
                    "path": str(path),
                    "url": path.as_uri(),
                    "canUndo": True,
                }
            )
        finally:
            if path != self.preview:
                path.unlink(missing_ok=True)

    @staticmethod
    def png_ready(path):
        try:
            with path.open("rb") as image:
                if image.read(8) != b"\x89PNG\r\n\x1a\n":
                    return False
                image.seek(-12, os.SEEK_END)
                return image.read() == b"\x00\x00\x00\x00IEND\xaeB`\x82"
        except (OSError, ValueError):
            return False

    def folder(self, kind, child):
        folder = Path.home() / kind
        if shutil.which("xdg-user-dir"):
            value = self.run(["xdg-user-dir", kind.upper()], timeout=3).decode().strip()
            if value and Path(value).is_absolute():
                folder = Path(value)
        folder /= child
        folder.mkdir(parents=True, exist_ok=True)
        return folder

    def record(self, request):
        mode = request.get("mode")
        if mode not in ("screen", "area"):
            raise ValueError("Recording supports screen or area only")
        # flock is released by the OS, including crashes. No stale PID ownership.
        runtime = Path(os.environ.get("XDG_RUNTIME_DIR", self.temp.name))
        with (runtime / "quickshell-capture-record.lock").open("a") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                raise RuntimeError(
                    "Another Quickshell capture instance owns a recording"
                ) from None
            selected = self.slurp(request, mode == "screen")
            folder = self.folder("Videos", "Records")
            fd, filename = tempfile.mkstemp(
                prefix=time.strftime("Recording-%Y%m%d-%H%M%S-"),
                suffix=".mp4",
                dir=folder,
            )
            os.close(fd)
            path = Path(filename)
            args = [
                "wf-recorder",
                "-y",
                "-f",
                filename,
                "-c",
                "libx264",
                "-o" if mode == "screen" else "-g",
                selected,
            ]
            audio = request.get("audio", "")
            if not isinstance(audio, str) or "\x00" in audio:
                raise ValueError("Invalid audio source")
            if audio:
                args += [f"--audio={audio}", "-C", "aac"]
            try:
                self.run(args, recording=path)
            except Cancelled:
                pass
            finally:
                if path.exists() and path.stat().st_size == 0:
                    path.unlink()
            if not path.exists():
                raise Cancelled()
            self.emit({"event": "saved", "path": str(path), "kind": "recording"})

    def execute(self, request):
        try:
            action = request.get("action")
            if action == "capabilities":
                self.capabilities()
            elif action == "screenshot":
                self.screenshot(request)
            elif action == "edit":
                self.edit(request)
            elif action == "undo":
                if not self.history:
                    raise ValueError("No edit to undo")
                self.preview.unlink(missing_ok=True)
                self.preview = self.history.pop()
                self.emit(
                    {
                        "event": "preview",
                        "url": self.preview.as_uri(),
                        "canUndo": bool(self.history),
                    }
                )
            elif action == "record":
                self.record(request)
            elif action == "pick":
                color = self.run(
                    ["hyprpicker", "--no-fancy", "--format=hex"], selector=True
                )
                if not re.fullmatch(r"#[0-9a-fA-F]{6}", color):
                    raise RuntimeError("Picker did not return a HEX color")
                self.emit({"event": "color", "hex": color.upper()})
            elif action == "copy-image":
                if not self.preview:
                    raise ValueError("Take a screenshot first")
                self.run(
                    ["wl-copy", "--type", "image/png"],
                    data=self.preview.read_bytes(),
                    timeout=5,
                    forks=True,
                )
                self.emit({"event": "copied"})
            elif action == "copy-color":
                text = request.get("text", "")
                if not isinstance(text, str) or len(text) > 128 or not text:
                    raise ValueError("Invalid color text")
                self.run(
                    ["wl-copy", "--type", "text/plain;charset=utf-8"],
                    data=text.encode(),
                    timeout=5,
                    forks=True,
                )
                self.emit({"event": "copied"})
            elif action == "save":
                if not self.preview:
                    raise ValueError("Take a screenshot first")
                folder = self.folder("Pictures", "Screenshots")
                with tempfile.NamedTemporaryFile(
                    prefix=time.strftime("Screenshot-%Y%m%d-%H%M%S-"),
                    suffix=".png",
                    dir=folder,
                    delete=False,
                ) as output:
                    try:
                        output.write(self.preview.read_bytes())
                    except OSError:
                        Path(output.name).unlink(missing_ok=True)
                        raise
                self.emit({"event": "saved", "path": output.name, "kind": "screenshot"})
            else:
                raise ValueError("Unknown capture action")
        except Cancelled:
            self.emit({"event": "cancelled"})
        except (OSError, RuntimeError, ValueError, TypeError, KeyError) as error:
            self.emit({"event": "error", "message": str(error)})
        finally:
            self.busy.release()
            self.emit({"event": "idle"})

    def submit(self, request):
        if request.get("action") == "stop":
            self.cancel.set()
        elif self.busy.acquire(blocking=False):
            self.cancel.clear()
            self.thread = threading.Thread(target=self.execute, args=(request,))
            self.thread.start()
        else:
            self.emit(
                {"event": "error", "message": "Capture is busy; stop or cancel first"}
            )

    def close(self):
        self.cancel.set()
        if self.thread:
            self.thread.join()
        self.temp.cleanup()


def main():
    os.umask(0o077)
    output_lock = threading.Lock()

    def emit(message):
        with output_lock:
            try:
                print(json.dumps(message), flush=True)
            except BrokenPipeError:
                pass

    capture = Capture(emit)

    def terminate(_signal, _frame):
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, terminate)
    signal.signal(signal.SIGINT, terminate)
    emit({"event": "ready"})
    try:
        for line in sys.stdin:
            try:
                request = json.loads(line)
                if not isinstance(request, dict):
                    raise TypeError("Expected a JSON object")
                capture.submit(request)
            except (ValueError, TypeError) as error:
                emit({"event": "error", "message": str(error)})
    finally:
        capture.close()


if __name__ == "__main__":
    main()
