"""Push generated colors to this user's running Foot/Ghostty PTYs on Linux."""

import os
import re
import stat
import sys
from pathlib import Path


def sequences(config):
    colors = {}
    palette = {}
    for line in config.read_text().splitlines():
        match = re.fullmatch(r"\s*([\w-]+)\s*=\s*(?:(\d+)=)?(#[\da-fA-F]{6})\s*", line)
        if match:
            key, index, color = match.groups()
            if key == "palette" and index is not None:
                palette[int(index)] = color
            else:
                colors[key] = color
    # Validate the complete palette before writing anything to a terminal.
    codes = {
        10: "foreground",
        11: "background",
        12: "cursor-color",
        17: "selection-background",
        19: "selection-foreground",
    }
    result = "".join(f"\033]4;{index};{palette[index]}\033\\" for index in range(18))
    result += "".join(f"\033]{code};{colors[key]}\033\\" for code, key in codes.items())
    return result.encode("ascii")


def terminals(proc=Path("/proc")):
    paths = set()
    for process in proc.glob("[0-9]*"):
        try:
            if process.stat().st_uid != os.getuid() or (
                process / "comm"
            ).read_text().strip() not in {"foot", "foot-server", "ghostty"}:
                continue
            for info in (process / "fdinfo").iterdir():
                try:
                    match = re.search(
                        r"^tty-index:\s*(\d+)$", info.read_text(), re.MULTILINE
                    )
                    if match:
                        paths.add(Path("/dev/pts") / match[1])
                except (FileNotFoundError, PermissionError):
                    continue
        except (FileNotFoundError, PermissionError):
            continue
    return paths


def send(path, data):
    # Write to the slave: bytes reach the terminal renderer, not shell input.
    fd = os.open(path, os.O_WRONLY | os.O_NOCTTY | os.O_NONBLOCK | os.O_NOFOLLOW)
    try:
        device = os.fstat(fd)
        if device.st_uid != os.getuid() or not stat.S_ISCHR(device.st_mode):
            raise ValueError(f"Not an owned terminal: {path}")
        if os.write(fd, data) != len(data):
            raise OSError(f"Incomplete color update: {path}")
    finally:
        os.close(fd)


if __name__ == "__main__":
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    data = sequences(config_home / "theme/generated/ghostty")
    for terminal in terminals():
        try:
            send(terminal, data)
        except OSError as error:
            # Windows may close between discovery and writing; never block others.
            print(f"wallpaper-theme: {terminal}: {error}", file=sys.stderr)
