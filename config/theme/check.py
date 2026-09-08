#!/usr/bin/env python3
"""Render every template in a temporary home, never touching live app configs."""

import fcntl
import json
import os
import pty
import runpy
import select
import shlex
import shutil
import subprocess
import tempfile
import termios
import time
import xml.etree.ElementTree as ET
from pathlib import Path

import tomllib

ROOT = Path(__file__).resolve().parents[2]
THEME = ROOT / "config/theme"


def check_prompt(home, env):
    config = home / ".config/theme/generated/starship.toml"
    config.write_text(
        'format = "[THEME>](red)"\npalette = "test"\n[palettes.test]\nred = "#123456"\n'
    )
    source = shlex.quote(str(ROOT / "config/fish/functions/wallpaper_cli_reload.fish"))
    master, slave = pty.openpty()

    def wait_for(color):
        received = b""
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            if select.select([master], [], [], 0.1)[0]:
                chunk = os.read(master, 65536)
                received += chunk
                if b"\x1b[0c" in chunk:
                    # Answer Fish's startup terminal query, not a user keypress.
                    os.write(master, b"\x1b[?1;2c")
                if color in received:
                    return
        raise AssertionError(f"Prompt did not repaint: {received!r}")

    try:
        with subprocess.Popen(
            [
                "fish",
                "--no-config",
                "--interactive",
                "--init-command",
                f"source {source}; wallpaper_cli_reload; starship init fish | source",
            ],
            stdin=slave,
            stdout=slave,
            stderr=slave,
            env={**env, "TERM": "xterm-256color", "COLORTERM": "truecolor"},
            start_new_session=True,
            preexec_fn=lambda: fcntl.ioctl(0, termios.TIOCSCTTY, 0),
        ) as shell:
            try:
                wait_for(b"38;2;18;52;86")
                config.write_text(config.read_text().replace("#123456", "#654321"))
                subprocess.run(
                    [
                        "fish",
                        "--no-config",
                        "-c",
                        "set -U wallpaper_theme_generation prompt-test",
                    ],
                    env=env,
                    check=True,
                )
                # No keypress: the idle prompt must repaint from the variable event.
                wait_for(b"38;2;101;67;33")
            finally:
                shell.terminate()
    finally:
        os.close(master)
        os.close(slave)


def check():
    binary = shutil.which("matugen")
    if not binary:
        raise SystemExit("Install matugen, or add its binary directory to PATH.")
    config = tomllib.loads((THEME / "config.toml").read_text())
    with tempfile.TemporaryDirectory(prefix="wallpaper-theme-test-") as directory:
        home = Path(directory)
        entries = ["[config]"]
        outputs = []
        for name, template in config["templates"].items():
            source = Path(
                template["input_path"].replace("~/.config/", str(ROOT / "config") + "/")
            )
            if not source.is_absolute():
                source = (THEME / source).resolve()
            assert source.is_file(), source
            entries += [
                f"[templates.{name}]",
                f"input_path = {json.dumps(str(source))}",
            ]
            if "output_path" in template:
                target = home / template["output_path"].removeprefix("~/")
                target.parent.mkdir(parents=True, exist_ok=True)
                outputs.append(target)
                entries.append(f"output_path = {json.dumps(str(target))}")
        test_config = home / "config.toml"
        test_config.write_text("\n".join(entries))
        previous = None
        for color in ("#ff0000", "#0000ff"):
            result = subprocess.run(
                [
                    binary,
                    "--config",
                    str(test_config),
                    "--mode",
                    "dark",
                    "color",
                    "hex",
                    color,
                ],
                capture_output=True,
                check=False,
                text=True,
            )
            assert result.returncode == 0, result.stdout + result.stderr
            for output in outputs:
                text = output.read_text()
                assert "{{" not in text, output
                if output.suffix in (".json", ".jsonc"):
                    json.loads(text)
                elif output.suffix == ".toml":
                    tomllib.loads(text)
                elif output.suffix == ".tmTheme":
                    ET.fromstring(text)
                elif output.suffix == ".fish" and shutil.which("fish"):
                    subprocess.run(["fish", "--no-execute", str(output)], check=True)
            rendered = [p.read_text() for p in outputs]
            if previous is not None:
                for path, before, after in zip(outputs, previous, rendered):
                    assert before != after, f"Palette does not change: {path}"
            previous = rendered
        terminal = runpy.run_path(str(THEME / "terminal.py"))
        data = terminal["sequences"](home / ".config/theme/generated/ghostty")
        assert data.count(b"\x1b]4;") == 18
        assert all(f"\033]{code};".encode() in data for code in (10, 11, 12, 17, 19))
        proc = home / "proc"
        for pid, name, index in (
            (1, "foot", 4),
            (2, "ghostty", 5),
            (3, "bash", 6),
            (4, "foot-server", 4),
        ):
            info = proc / str(pid) / "fdinfo"
            info.mkdir(parents=True)
            (info.parent / "comm").write_text(name + "\n")
            (info / "12").write_text(f"tty-index:\t{index}\n")
        assert terminal["terminals"](proc) == {Path("/dev/pts/4"), Path("/dev/pts/5")}
        master, slave = pty.openpty()
        try:
            terminal["send"](Path(os.ttyname(slave)), data)
            assert select.select([master], [], [], 1)[0]
            assert os.read(master, 4096) == data
            assert not select.select([slave], [], [], 0)[0], (
                "Colors leaked into shell input"
            )
        finally:
            os.close(master)
            os.close(slave)
        # Stub live-terminal discovery for the runner tests, never touch real PTYs.
        (home / ".config/theme/terminal.py").write_text("pass\n")
        # Runner must preserve spaces, restore saved state, and propagate failure.
        bindir = home / "bin"
        bindir.mkdir()
        fake = bindir / "matugen"
        fake.write_text(
            '#!/bin/sh\nprintf "%s\\n" "$@" > "$HOME/args"\nexit "${FAIL:-0}"\n'
        )
        fake.chmod(0o755)
        # Never signal the user's Ghostty during isolated runner tests.
        signal_stub = bindir / "pkill"
        signal_stub.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$HOME/signal-args"\n')
        signal_stub.chmod(0o755)
        env = {
            **os.environ,
            "HOME": str(home),
            "XDG_CONFIG_HOME": str(home / ".config"),
            "XDG_CACHE_HOME": str(home / ".cache"),
            "PATH": str(bindir) + os.pathsep + os.environ["PATH"],
        }
        env.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
        env.pop("TMUX", None)
        env["TMUX_TMPDIR"] = str(home)
        if shutil.which("fish") and shutil.which("starship"):
            check_prompt(home, env)
        image = home / "wall paper.png"
        image.touch()
        runner = ROOT / "home/.local/bin/wallpaper-theme"
        subprocess.run([str(runner), str(image)], env=env, check=True)
        assert (home / "args").read_text().splitlines()[-1] == str(image)
        assert (home / "signal-args").read_text().splitlines() == [
            "--require-handler",
            "--signal",
            "USR2",
            "--euid",
            str(os.getuid()),
            "--exact",
            "ghostty",
        ]
        store = home / ".cache/quickshell/wallpaper"
        store.parent.mkdir(parents=True)
        store.write_text(json.dumps({"wallpaper": str(image), "interval": 0}))
        subprocess.run([str(runner)], env=env, check=True)
        failed = subprocess.run(
            [str(runner), str(image)], env={**env, "FAIL": "7"}, check=False
        )
        assert failed.returncode == 7
        missing = subprocess.run(
            [str(runner), str(home / "missing")],
            env=env,
            capture_output=True,
            check=False,
        )
        assert missing.returncode != 0
    print(
        f"PASS: {len(outputs)} templates render and change palettes; structured output parses; runner handles restore, spaces, and failure."
    )


if __name__ == "__main__":
    check()
