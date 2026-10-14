#!/usr/bin/env python3
"""Render every template in a temporary home, never touching live app configs."""

import colorsys
import json
import os
import pty
import re
import runpy
import select
import shlex
import shutil
import signal
import struct
import subprocess
import tempfile
import time
import tomllib
import xml.etree.ElementTree as ET
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
THEME = ROOT / "config/theme"


def check_workmux(home):
    path = home / ".config/theme/generated/workmux/config.yaml"
    text = path.read_text()
    base = (ROOT / "config/workmux/base.yaml").read_text()
    assert text.startswith(base), "Workmux settings changed during generation"
    fields = {
        key: int(value)
        for key, value in re.findall(r"^    (\w+): (\d+)$", text, re.MULTILINE)
    }
    assert fields == {
        "current_row_bg": 20,
        "highlight_row_bg": 18,
        "current_worktree_fg": 2,
        "dimmed": 7,
        "text": 15,
        "border": 8,
        "help_border": 8,
        "help_muted": 7,
        "header": 2,
        "keycap": 4,
        "info": 4,
        "success": 3,
        "warning": 4,
        "danger": 1,
        "accent": 2,
    }, fields
    ghostty = (home / ".config/theme/generated/ghostty").read_text()
    tmux = (home / ".cache/theme/tmux.sh").read_text()
    for slot, role in (
        (20, "highlight"),
        (18, "active"),
        (15, "foreground"),
        (2, "blue"),
    ):
        color = re.search(rf'\[{role}\]="(#[0-9a-fA-F]{{6}})"', tmux)[1]
        assert f"palette = {slot}={color}" in ghostty, (slot, role)
    config = home / ".config/workmux/config.yaml"
    config.parent.mkdir(parents=True, exist_ok=True)
    if not config.is_symlink():
        config.symlink_to(path)
    if shutil.which("workmux"):
        subprocess.run(
            ["workmux", "list", "--json"],
            cwd=ROOT,
            env={
                **os.environ,
                "HOME": str(home),
                "XDG_CONFIG_HOME": str(home / ".config"),
                "XDG_STATE_HOME": str(home / ".local/state"),
            },
            capture_output=True,
            text=True,
            check=True,
        )


def check_prompt(home, env):
    config = home / ".config/theme/generated/starship.toml"
    config.write_text(
        'format = "[THEME>](red)"\npalette = "test"\n[palettes.test]\nred = "#123456"\n'
    )
    source = shlex.quote(str(ROOT / "config/fish/functions/wallpaper_cli_reload.fish"))
    pid, master = pty.fork()
    if pid == 0:
        os.execvpe(
            "fish",
            [
                "fish",
                "--interactive",
                "--init-command",
                f"source {source}; wallpaper_cli_reload; starship init fish | source",
            ],
            {**env, "TERM": "xterm-256color", "COLORTERM": "truecolor"},
        )

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
        wait_for(b"38;2;18;52;86")
        config.write_text(config.read_text().replace("#123456", "#654321"))
        subprocess.run(
            ["fish", "-c", "set -U wallpaper_theme_generation prompt-test"],
            env=env,
            check=True,
        )
        # No keypress: the idle prompt must repaint from the variable event.
        wait_for(b"38;2;101;67;33")
    finally:
        os.kill(pid, signal.SIGTERM)
        os.waitpid(pid, 0)
        os.close(master)


def check_tmux(home, env, terminal, palettes):
    shutil.copytree(ROOT / "home/.tmux/theme", home / ".tmux/theme")
    probe = home / "palette-probe.py"
    probe.write_text(
        "import os, select, time, tty\n"
        "from pathlib import Path\n"
        "tty.setraw(0)\n"
        "home = Path.home()\n"
        "(home / 'probe-ready').touch()\n"
        "for index in range(2):\n"
        "    while not (home / f'query-{index}').exists(): time.sleep(0.01)\n"
        "    os.write(1, b'\\x1b]4;0;?\\x1b\\\\\\x1b]4;18;?\\x1b\\\\\\x1b]4;20;?\\x1b\\\\\\x1b]10;?\\x1b\\\\\\x1b]11;?\\x1b\\\\')\n"
        "    data = b''\n"
        "    deadline = time.monotonic() + 3\n"
        "    while data.count(b'\\x1b\\\\') < 5 and time.monotonic() < deadline:\n"
        "        if select.select([0], [], [], 0.1)[0]: data += os.read(0, 4096)\n"
        "    (home / f'reply-{index}').write_bytes(data)\n"
        "time.sleep(10)\n"
    )
    tmux = ["tmux", "-L", "wallpaper-palette-check", "-f", "/dev/null"]

    def run(*args):
        return subprocess.run(
            [*tmux, *args], env=env, check=True, capture_output=True, text=True
        ).stdout.strip()

    def wait(path):
        deadline = time.monotonic() + 5
        while not path.exists() and time.monotonic() < deadline:
            time.sleep(0.01)
        assert path.exists(), f"tmux probe timed out: {path}"

    run("new-session", "-d", f"python3 {shlex.quote(str(probe))}")
    try:
        wait(home / "probe-ready")
        socket = run("display-message", "-p", "#{socket_path}")
        pane = Path(run("display-message", "-p", "#{pane_tty}"))
        dashboard = None
        if shutil.which("workmux"):
            capture = home / "workmux-live.ansi"
            dashboard = run(
                "new-window",
                "-d",
                "-P",
                "-F",
                "#{pane_id}",
                "-c",
                str(ROOT),
                "sleep 1; exec workmux dashboard --tab worktrees",
            )
            run("pipe-pane", "-t", dashboard, f"cat > {shlex.quote(str(capture))}")
            deadline = time.monotonic() + 8
            while time.monotonic() < deadline:
                if capture.exists() and b"48;5;18m" in capture.read_bytes():
                    break
                time.sleep(0.05)
            assert b"48;5;18m" in capture.read_bytes(), (
                "Workmux did not render indexed highlight color"
            )
            dashboard_pid = run("display-message", "-p", "-t", dashboard, "#{pane_pid}")
        sidebar = None
        if shutil.which("workmux"):
            generated = home / ".config/theme/generated/workmux/config.yaml"
            indexed_config = generated.read_text()
            generated.write_text(
                indexed_config.replace("text: 15", 'text: "#654321"').replace(
                    "header: 2", 'header: "#123456"'
                )
            )
            host = run(
                "new-window",
                "-d",
                "-P",
                "-F",
                "#{pane_id}",
                "-c",
                str(ROOT),
                "sleep 120",
            )
            sidebar_env = {**env, "TMUX": f"{socket},0,0", "TMUX_PANE": host}
            for args in (
                ("set-window-status", "working"),
                ("sidebar", "on", "--width", "40"),
            ):
                subprocess.run(
                    ["workmux", *args],
                    cwd=ROOT,
                    env=sidebar_env,
                    capture_output=True,
                    text=True,
                    check=True,
                )
            deadline = time.monotonic() + 8
            while time.monotonic() < deadline:
                panes = run(
                    "list-panes", "-a", "-F", "#{pane_id} #{@workmux_role}"
                ).splitlines()
                sidebar = next(
                    (line.split()[0] for line in panes if line.endswith(" sidebar")),
                    None,
                )
                if sidebar is not None:
                    break
                time.sleep(0.05)
            assert sidebar is not None, "Workmux sidebar did not start"
            sidebar_pid = run("display-message", "-p", "-t", sidebar, "#{pane_pid}")
            sidebar_capture = home / "workmux-sidebar-live.ansi"
            run(
                "pipe-pane", "-t", sidebar, f"cat > {shlex.quote(str(sidebar_capture))}"
            )
            run("resize-pane", "-t", sidebar, "-x", "39")
            deadline = time.monotonic() + 8
            while time.monotonic() < deadline:
                if (
                    sidebar_capture.exists()
                    and b"38;2;101;67;33" in sidebar_capture.read_bytes()
                ):
                    break
                time.sleep(0.05)
            assert b"38;2;101;67;33" in sidebar_capture.read_bytes(), (
                "Sidebar did not load stale RGB config"
            )
            sidebar_offset = sidebar_capture.stat().st_size
            generated.write_text(indexed_config)
        for index, palette in enumerate(palettes):
            for name, text in palette.items():
                (home / name).write_text(text)
            styles = (
                "status-style",
                "window-status-style",
                "window-status-current-style",
                "window-status-activity-style",
                "window-status-bell-style",
                "window-status-last-style",
            )
            for option in styles:
                run("set-option", "-g", option, "fg=#123456,bg=#654321,reverse")
            for option in ("window-status-format", "window-status-current-format"):
                run(
                    "set-option",
                    "-w",
                    option,
                    "#[fg=#123456]#W#{?@workmux_status, #{@workmux_status},}",
                )
            run("set-option", "-w", "@workmux_status", "🤖")
            subprocess.run(
                [
                    str(ROOT / "home/.local/bin/wallpaper-theme"),
                    str(ROOT / "wallpapers/arch-linux.png"),
                ],
                env={**env, "TMUX": f"{socket},0,0"},
                check=True,
                capture_output=True,
                text=True,
            )
            if sidebar is not None:
                deadline = time.monotonic() + 8
                while time.monotonic() < deadline:
                    if (
                        sidebar_capture.exists()
                        and b"38;5;15" in sidebar_capture.read_bytes()[sidebar_offset:]
                    ):
                        break
                    time.sleep(0.05)
                assert b"38;5;15" in sidebar_capture.read_bytes()[sidebar_offset:], (
                    "Sidebar did not reload indexed text color"
                )
                assert (
                    run("display-message", "-p", "-t", sidebar, "#{pane_pid}")
                    == sidebar_pid
                )
                terminal["send"](
                    Path(run("display-message", "-p", "-t", sidebar, "#{pane_tty}")),
                    terminal["sequences"](home / ".config/theme/generated/ghostty"),
                )
            for option in styles:
                style = run("show-options", "-gv", option)
                assert "#123456" not in style and "#654321" not in style, (
                    option,
                    style,
                )
                assert "reverse" not in style, (option, style)
            for option in ("window-status-format", "window-status-current-format"):
                assert run("show-options", "-wqv", option) == ""
                inherited = run("show-options", "-wv", option)
                assert "@workmux_status" not in inherited and "#123456" not in inherited
            assert run("show-options", "-wqv", "@workmux_status") == "🤖"
            data = terminal["sequences"](home / ".config/theme/generated/ghostty")
            terminal["send"](pane, data)
            if dashboard is not None:
                dashboard_tty = Path(
                    run("display-message", "-p", "-t", dashboard, "#{pane_tty}")
                )
                terminal["send"](dashboard_tty, data)
                assert (
                    run("display-message", "-p", "-t", dashboard, "#{pane_pid}")
                    == dashboard_pid
                )
                assert (
                    run("display-message", "-p", "-t", dashboard, "#{pane_dead}") == "0"
                )
            (home / f"query-{index}").touch()
            reply = home / f"reply-{index}"
            wait(reply)
            lines = palette[".config/theme/generated/ghostty"].splitlines()
            colors = dict(
                line.split(" = ", 1)
                for line in lines
                if " = " in line and not line.startswith("palette")
            )
            ansi = {
                int(line.split("=", 2)[1]): line.split("=", 2)[2]
                for line in lines
                if line.startswith("palette = ")
            }
            for code, color in (
                ("4;0", ansi[0]),
                ("4;18", ansi[18]),
                ("4;20", ansi[20]),
                ("10", colors["foreground"]),
                ("11", colors["background"]),
            ):
                rgb = "/".join(
                    part * 2 for part in (color[1:3], color[3:5], color[5:7])
                )
                expected = f"\033]{code};rgb:{rgb}\033\\".encode()
                assert expected in reply.read_bytes(), reply.read_bytes()
        if sidebar is not None:
            shutil.copyfile(
                sidebar_capture,
                Path(tempfile.gettempdir()) / "workmux-sidebar-live-theme.ansi",
            )
            print(
                "PASS: running Workmux sidebar reloads symlinked config without restart"
            )
        if dashboard is not None:
            shutil.copyfile(
                capture, Path(tempfile.gettempdir()) / "workmux-live-theme.ansi"
            )
            print(
                "PASS: running Workmux uses indexed row colors and survives both palette updates"
            )
    finally:
        run("kill-server")


def check():
    binary = shutil.which("matugen")
    if not binary:
        raise SystemExit("Install matugen, or add its binary directory to PATH.")
    config = tomllib.loads((THEME / "config.toml").read_text())
    assert "window-theme = ghostty" in (ROOT / "config/ghostty/config").read_text()
    # Keep semantic ANSI foregrounds, but never reverse colored text on selection.
    lazy_templates = {"lazygit", "lazydocker"}
    docker_fields = {
        "activeBorderColor",
        "inactiveBorderColor",
        "optionsTextColor",
        "selectedLineBgColor",
    }
    for name in lazy_templates:
        text = (THEME / f"templates/{name}.yml").read_text()
        fields = set()
        for line in text.splitlines():
            if ": [" not in line:
                continue
            key, values = line.strip().split(": ", 1)
            fields.add(key)
            if key == "selectedLineBgColor":
                assert values == '["{{colors.surface_container_high.default.hex}}"]'
                continue
            assert values.startswith("[") and values.endswith("]")
            assert set(values[1:-1].split(", ")) <= {
                "default",
                "green",
                "white",
                "yellow",
                "blue",
                "red",
                "bold",
            }, line
        assert "selectedLineBgColor" in fields
        if name == "lazydocker":
            assert fields == docker_fields, "Lazydocker supports only four theme fields"
    # Pi's native watcher ignores externally registered theme paths.
    assert config["templates"]["pi"]["output_path"] == "~/.pi/agent/themes/matugen.json"
    assert (
        json.loads((ROOT / "config/opencode/cli.json").read_text())["theme"]["name"]
        == "system"
    )
    assert (
        config["templates"]["fzf"]["output_path"]
        == "~/.config/theme/generated/fzf.opts"
    )
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
        palettes = []
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
            check_workmux(home)
            fzf_opts = (home / ".config/theme/generated/fzf.opts").read_text()
            assert fzf_opts.startswith("--color=bg:#")
            if shutil.which("fzf"):
                fzf_env = {
                    **os.environ,
                    "FZF_DEFAULT_OPTS_FILE": str(
                        home / ".config/theme/generated/fzf.opts"
                    ),
                }
                fzf_env.pop("FZF_DEFAULT_OPTS", None)
                filtered = subprocess.run(
                    ["fzf", "--filter=match"],
                    input="match\n",
                    env=fzf_env,
                    capture_output=True,
                    text=True,
                    check=True,
                )
                assert filtered.stdout == "match\n"
            rendered = [p.read_text() for p in outputs]
            if previous is not None:
                for path, before, after in zip(outputs, previous, rendered):
                    if path == home / ".config/theme/generated/workmux/config.yaml":
                        assert before == after, (
                            "Workmux must keep terminal palette indices"
                        )
                    else:
                        assert before != after, f"Palette does not change: {path}"
            previous = rendered
            palettes.append(
                {
                    name: (home / name).read_text()
                    for name in (
                        ".config/theme/generated/ghostty",
                        ".cache/theme/tmux.sh",
                    )
                }
            )
        terminal = runpy.run_path(str(THEME / "terminal.py"))
        data = terminal["sequences"](home / ".config/theme/generated/ghostty")
        assert data.count(b"\x1b]4;") == 21
        assert all(f"\033]{code};".encode() in data for code in (10, 11, 12, 17, 19))
        proc = home / "proc"
        for pid, name, index in (
            (1, "foot", 4),
            (2, "ghostty", 5),
            (3, "bash", 6),
            (4, "foot-server", 4),
            (5, "tmux: server", 7),
            (6, "tmux: client", 8),
        ):
            info = proc / str(pid) / "fdinfo"
            info.mkdir(parents=True)
            (info.parent / "comm").write_text(name + "\n")
            (info / "12").write_text(f"tty-index:\t{index}\n")
        assert terminal["terminals"](proc) == {
            Path("/dev/pts/4"),
            Path("/dev/pts/5"),
            Path("/dev/pts/7"),
        }
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
            '#!/bin/sh\nprintf "%s\\n" "$@" > "$HOME/args"\n'
            'if [ "${FAIL:-0}" != 0 ]; then exit "$FAIL"; fi\n'
            'case " $* " in *" json "*)\n'
            '  for arg in "$@"; do palette=$arg; done\n'
            '  cp "$palette" "$HOME/render-palette.json";; esac\n'
            'case " $* " in *" --dry-run "*)\n'
            '  if [ "${INVALID_PALETTE:-0}" != 0 ]; then printf "invalid"; exit 0; fi\n'
            f'  {shlex.quote(binary)} "$@" > "$HOME/source-palette.json" || exit $?\n'
            '  if [ "${MISSING_ANCHOR:-0}" != 0 ]; then\n'
            '    jq "del(.colors.background.default)" "$HOME/source-palette.json"\n'
            '  else cat "$HOME/source-palette.json"; fi\n'
            "  exit;; esac\n"
            f'if [ "${{RENDER:-0}}" = 1 ]; then exec {shlex.quote(binary)} "$@"; fi\n'
        )
        fake.chmod(0o755)
        # Never signal the user's Ghostty during isolated runner tests.
        signal_stub = bindir / "pkill"
        signal_stub.write_text(
            '#!/bin/sh\nprintf "%s\\n" "$@" >> "$HOME/signal-args"\n'
        )
        signal_stub.chmod(0o755)
        settings_stub = bindir / "gsettings"
        settings_stub.write_text(
            '#!/bin/sh\nif [ "$1" = get ]; then\n'
            '  printf "\x27%s\x27\\n" "$(cat "$HOME/gtk-theme" 2>/dev/null)"\n'
            'else\n  printf "%s" "$4" > "$HOME/gtk-theme"\nfi\n'
        )
        settings_stub.chmod(0o755)
        qt_configs = [home / f".config/qt{v}ct/qt{v}ct.conf" for v in (5, 6)]
        for qt_config in qt_configs:
            # Match the deployed symlinks: touching the target must not count.
            target = home / qt_config.name
            target.write_text("[Appearance]\ncustom_palette=true\n")
            qt_config.symlink_to(target)
            os.utime(target, (1, 1))
            os.utime(qt_config.parent, (1, 1))
        env = {
            **os.environ,
            "HOME": str(home),
            "XDG_CONFIG_HOME": str(home / ".config"),
            "XDG_CACHE_HOME": str(home / ".cache"),
            "XDG_DATA_HOME": str(home / ".local/share"),
            "XDG_STATE_HOME": str(home / ".local/state"),
            "PATH": str(bindir) + os.pathsep + os.environ["PATH"],
        }
        env.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
        env.pop("TMUX", None)
        env["TMUX_TMPDIR"] = str(home)
        if shutil.which("tmux"):
            check_tmux(home, env, terminal, palettes)
        if shutil.which("fish") and shutil.which("starship"):
            check_prompt(home, env)
        image = home / "wall paper.png"
        shutil.copyfile(ROOT / "wallpapers/arch-linux.png", image)
        runner = ROOT / "home/.local/bin/wallpaper-theme"
        (home / ".config/theme/config.toml").write_text(test_config.read_text())
        wallpaper_images = [
            ROOT / "wallpapers" / name
            for name in (
                "forest.jpg",
                "aesthetic_blue_jupiter.jpg",
                "sunforest.jpg",
                "galaxy.png",
                "spaceman-in-sace.jpeg",
            )
        ]
        for name, rgb in (
            ("black", bytes((0, 0, 0))),
            ("white", bytes((255, 255, 255))),
        ):
            path = home / f"{name}.png"
            png = b"\x89PNG\r\n\x1a\n"
            for kind, payload in (
                (b"IHDR", struct.pack(">IIBBBBB", 16, 16, 8, 2, 0, 0, 0)),
                (b"IDAT", zlib.compress((b"\0" + rgb * 16) * 16)),
                (b"IEND", b""),
            ):
                png += struct.pack(">I", len(payload)) + kind + payload
                png += struct.pack(">I", zlib.crc32(kind + payload))
            path.write_bytes(png)
            wallpaper_images.append(path)
        monochrome_outputs = {}
        monochrome_palettes = {}
        monochrome_seeds = {}
        render_cases = [("monochrome", wallpaper_images[0])]
        render_cases += [("mono", path) for path in wallpaper_images]
        render_cases += [("mono", wallpaper_images[0]), ("color", image)]
        for mode, wallpaper_image in render_cases:
            subprocess.run(
                [str(runner), str(wallpaper_image), mode],
                env={**env, "RENDER": "1"},
                check=True,
            )
            check_workmux(home)
            if mode != "color":
                original_palette = json.loads(
                    (home / "source-palette.json").read_text()
                )
                seed = original_palette["colors"]["background"]["default"]["color"]
                seed_rgb = [int(seed[i : i + 2], 16) for i in (1, 3, 5)]
                hue, _, saturation = colorsys.rgb_to_hls(*(c / 255 for c in seed_rgb))
            colors = []
            for output in outputs:
                text = output.read_text()
                assert "{{" not in text, output
                if output == home / ".config/theme/generated/workmux/config.yaml":
                    text = (home / ".config/theme/generated/ghostty").read_text()
                if output.name == "manifest.json":
                    matches = [
                        "".join(f"{channel:02x}" for channel in rgb)
                        for rgb in json.loads(text)["theme"]["colors"].values()
                    ]
                else:
                    matches = re.findall(
                        r"(?<![\w])#?([0-9a-fA-F]{8}|[0-9a-fA-F]{6})(?![\w])", text
                    )
                    matches = [
                        color[-6:]
                        if output.name == "colors-generated.conf"
                        else color[:6]
                        for color in matches
                    ]
                assert matches, f"No colors checked: {output}"
                colors.extend(matches)
                if mode != "color":
                    chromatic = any(c[:2] != c[2:4] or c[2:4] != c[4:] for c in matches)
                    assert chromatic == (len(set(seed_rgb)) > 1), (
                        f"Incorrect background color: {wallpaper_image.name}; {seed}; {output}"
                    )
            assert not list((home / ".cache/theme").glob("monochrome.*.json"))
            if mode == "color":
                assert any(c[:2] != c[2:4] or c[2:4] != c[4:] for c in colors)
            else:
                rendered = [output.read_text() for output in outputs]
                quickshell = json.loads(
                    (home / ".config/quickshell/colors.json").read_text()
                )
                if wallpaper_image.name in monochrome_palettes:
                    assert rendered == monochrome_outputs[wallpaper_image.name], (
                        "Monochrome render is not repeatable"
                    )
                else:
                    for previous_image, previous_outputs in monochrome_outputs.items():
                        if monochrome_seeds[previous_image] == seed:
                            continue
                        for path, before, after in zip(
                            outputs, previous_outputs, rendered
                        ):
                            if (
                                path
                                == home / ".config/theme/generated/workmux/config.yaml"
                            ):
                                assert before == after, (
                                    "Workmux indices must stay fixed"
                                )
                            else:
                                assert before != after, (
                                    f"Monochrome palette is fixed: {path}; "
                                    f"{previous_image} and {wallpaper_image.name}"
                                )
                    monochrome_outputs[wallpaper_image.name] = rendered
                    monochrome_palettes[wallpaper_image.name] = quickshell
                    monochrome_seeds[wallpaper_image.name] = seed
                tinted_palette = json.loads((home / "render-palette.json").read_text())
                assert (
                    tinted_palette["colors"]["background"]["default"]["color"] == seed
                ), "Mono changed the terminal background"
                foot = (home / ".config/theme/generated/foot.ini").read_text()
                ghostty = (home / ".config/theme/generated/ghostty").read_text()
                assert f"background={seed[1:]}\n" in foot
                assert f"background = {seed}\n" in ghostty
                order = sorted(range(3), key=seed_rgb.__getitem__)
                for color in colors:
                    rgb = [int(color[i : i + 2], 16) for i in (0, 2, 4)]
                    assert rgb[order[0]] <= rgb[order[1]] <= rgb[order[2]], (
                        "Colors do not share terminal background hue",
                        seed,
                        color,
                    )
                    _, lightness, _ = colorsys.rgb_to_hls(*(c / 255 for c in rgb))
                    expected = colorsys.hls_to_rgb(hue, lightness, saturation)
                    assert (
                        max(
                            abs(actual / 255 - target)
                            for actual, target in zip(rgb, expected)
                        )
                        <= 1.001 / 255
                    ), (
                        "Mono must keep background hue and saturation, with no gray mixing",
                        wallpaper_image.name,
                        seed,
                        color,
                    )
                for group in ("colors", "base16"):
                    for role, variants in original_palette[group].items():
                        for variant, original in variants.items():
                            dark = variant != "light"
                            reference = original["color"]
                            if group == "base16" and int(role[4:], 16) < 8:
                                tones = (
                                    (5, 10, 15, 20, 35, 70, 90, 98)
                                    if dark
                                    else (98, 95, 90, 80, 60, 30, 20, 5)
                                )
                                tone = tones[int(role[4:], 16)]
                                reference = original_palette["palettes"]["neutral"][
                                    str(tone)
                                ]["color"]
                            elif group == "base16" and int(role[4:], 16) >= 8:
                                tones = (
                                    (60, 70, 80, 90, 95, 98, 99, 100)
                                    if dark
                                    else (5, 10, 15, 20, 25, 30, 35, 40)
                                )
                                tone = tones[int(role[4:], 16) - 8]
                                reference = original_palette["palettes"]["primary"][
                                    str(tone)
                                ]["color"]
                            elif group == "colors" and role in (
                                "primary",
                                "secondary",
                                "tertiary",
                            ):
                                tones = (80, 90, 95) if dark else (40, 30, 20)
                                tone = tones[
                                    ("primary", "secondary", "tertiary").index(role)
                                ]
                                reference = original_palette["palettes"]["primary"][
                                    str(tone)
                                ]["color"]
                            original_rgb = [
                                int(reference[i : i + 2], 16) / 255 for i in (1, 3, 5)
                            ]
                            tinted = tinted_palette[group][role][variant]["color"]
                            tinted_rgb = [
                                int(tinted[i : i + 2], 16) / 255 for i in (1, 3, 5)
                            ]
                            values = [
                                sum(
                                    (
                                        c / 12.92
                                        if c <= 0.04045
                                        else ((c + 0.055) / 1.055) ** 2.4
                                    )
                                    * w
                                    for c, w in zip(rgb, (0.2126, 0.7152, 0.0722))
                                )
                                for rgb in (original_rgb, tinted_rgb)
                            ]
                            assert abs(values[0] - values[1]) < 0.01, (
                                role,
                                variant,
                                values,
                            )
                base16 = [
                    variants["dark"]["color"]
                    for variants in tinted_palette["base16"].values()
                ]
                assert len(set(base16)) >= 12, "Base16 shades collapsed into one color"
                palette = tinted_palette["colors"]
                for foreground, background in (
                    ("on_background", "background"),
                    ("on_surface", "surface_bright"),
                    ("on_surface_variant", "surface_bright"),
                    ("on_primary", "primary"),
                    ("on_primary_container", "primary_container"),
                    ("on_secondary", "secondary"),
                    ("on_secondary_container", "secondary_container"),
                    ("on_tertiary", "tertiary"),
                    ("on_tertiary_container", "tertiary_container"),
                    ("on_error", "error"),
                    ("on_error_container", "error_container"),
                    ("inverse_on_surface", "inverse_surface"),
                    ("on_primary_fixed", "primary_fixed_dim"),
                    ("on_primary_fixed_variant", "primary_fixed_dim"),
                    ("on_secondary_fixed", "secondary_fixed_dim"),
                    ("on_secondary_fixed_variant", "secondary_fixed_dim"),
                    ("on_tertiary_fixed", "tertiary_fixed_dim"),
                    ("on_tertiary_fixed_variant", "tertiary_fixed_dim"),
                ):
                    for variant in ("dark", "light"):
                        rgb_values = [
                            [
                                int(palette[role][variant]["color"][i : i + 2], 16)
                                / 255
                                for i in (1, 3, 5)
                            ]
                            for role in (foreground, background)
                        ]
                        luminance = [
                            sum(
                                (
                                    c / 12.92
                                    if c <= 0.04045
                                    else ((c + 0.055) / 1.055) ** 2.4
                                )
                                * w
                                for c, w in zip(rgb, (0.2126, 0.7152, 0.0722))
                            )
                            for rgb in rgb_values
                        ]
                        contrast = (max(luminance) + 0.05) / (min(luminance) + 0.05)
                        assert contrast >= 4.5, (
                            wallpaper_image.name,
                            variant,
                            foreground,
                            background,
                            contrast,
                        )
        for role in ("g0", "g5", "g7"):
            assert len(
                {monochrome_palettes[path.name][role] for path in wallpaper_images[:5]}
            ) >= len({monochrome_seeds[path.name] for path in wallpaper_images[:5]}), (
                f"Terminal background hue does not vary: {role}"
            )
        Path("/tmp/wallpaper-mono-colors.json").write_text(
            json.dumps(monochrome_palettes, indent=2) + "\n"
        )
        (home / "signal-args").unlink()
        subprocess.run([str(runner), str(image)], env=env, check=True)
        assert (home / "args").read_text().splitlines()[-1] == str(image)
        assert (home / "gtk-theme").read_text() == "matugen-dark"
        theme_css = home / ".local/share/themes/matugen-dark/gtk-3.0/gtk.css"
        assert theme_css.read_text().endswith(
            (home / ".config/gtk-3.0/colors.css").read_text()
        )
        for qt_config in qt_configs:
            assert qt_config.is_symlink()
            assert qt_config.stat().st_mtime == 1
            assert qt_config.parent.stat().st_mtime > 1
            assert not list(qt_config.parent.glob(".matugen-reload.*"))
            assert qt_config.read_text() == "[Appearance]\ncustom_palette=true\n"
        assert (home / "signal-args").read_text().splitlines() == [
            "--require-handler",
            "--signal",
            "USR2",
            "--euid",
            str(os.getuid()),
            "--exact",
            "ghostty",
            "--require-handler",
            "--signal",
            "USR2",
            "--euid",
            str(os.getuid()),
            "--exact",
            "opencode",
        ]
        store = home / ".cache/quickshell/wallpaper"
        store.parent.mkdir(parents=True)
        store.write_text(json.dumps({"wallpaper": str(image), "interval": 0}))
        subprocess.run([str(runner)], env=env, check=True)
        assert (home / "gtk-theme").read_text() == "matugen-dark-alt"
        assert "scheme-tonal-spot" in (home / "args").read_text().splitlines()
        for saved in (str(image), {"wallpaper": str(image), "interval": 0}):
            store.write_text(saved if isinstance(saved, str) else json.dumps(saved))
            subprocess.run([str(runner)], env=env, check=True)
            assert "scheme-tonal-spot" in (home / "args").read_text().splitlines()
        store.write_text(
            json.dumps({"wallpaper": str(image), "interval": 0, "monochrome": True})
        )
        subprocess.run([str(runner)], env=env, check=True)
        assert "json" in (home / "args").read_text().splitlines()
        subprocess.run([str(runner), str(image), "color"], env=env, check=True)
        assert "scheme-tonal-spot" in (home / "args").read_text().splitlines()
        invalid = subprocess.run(
            [str(runner), str(image), "invalid"],
            env=env,
            capture_output=True,
            check=False,
        )
        assert invalid.returncode == 2
        if shutil.which("tmux"):
            tmux = ["tmux", "-L", "wallpaper-theme-check"]
            subprocess.run([*tmux, "new-session", "-d"], env=env, check=True)
            socket = subprocess.run(
                [*tmux, "display-message", "-p", "#{socket_path}"],
                env=env,
                check=True,
                capture_output=True,
                text=True,
            ).stdout.strip()
            tmux_env = {**env, "TMUX": f"{socket},0,0"}
            try:
                subprocess.run(
                    [
                        *tmux,
                        "set-environment",
                        "-g",
                        "FZF_DEFAULT_OPTS",
                        "--color=bg:#000000",
                    ],
                    env=env,
                    check=True,
                )
                subprocess.run([str(runner), str(image)], env=tmux_env, check=True)
                actual = subprocess.run(
                    [*tmux, "show-environment", "-g", "FZF_DEFAULT_OPTS_FILE"],
                    env=env,
                    check=True,
                    capture_output=True,
                    text=True,
                ).stdout.strip()
                assert actual == (
                    f"FZF_DEFAULT_OPTS_FILE={home}/.config/theme/generated/fzf.opts"
                )
                cleared = subprocess.run(
                    [*tmux, "show-environment", "-g", "FZF_DEFAULT_OPTS"],
                    env=env,
                    check=False,
                    capture_output=True,
                    text=True,
                )
                assert cleared.returncode == 1
                assert "unknown variable: FZF_DEFAULT_OPTS" in cleared.stderr
            finally:
                subprocess.run([*tmux, "kill-server"], env=env, check=True)
        failed = subprocess.run(
            [str(runner), str(image)], env={**env, "FAIL": "7"}, check=False
        )
        assert failed.returncode == 7
        for failure_env in ({"INVALID_PALETTE": "1"}, {"MISSING_ANCHOR": "1"}):
            before = [output.read_bytes() for output in outputs]
            signals = (home / "signal-args").read_bytes()
            failed = subprocess.run(
                [str(runner), str(image), "mono"],
                env={**env, **failure_env},
                capture_output=True,
                check=False,
            )
            assert failed.returncode != 0, "Invalid Matugen palette must fail"
            assert [output.read_bytes() for output in outputs] == before
            assert (home / "signal-args").read_bytes() == signals
            assert not list((home / ".cache/theme").glob("monochrome.*.json"))
        assert not list((home / ".cache/theme").glob("monochrome.*.json"))
        missing = subprocess.run(
            [str(runner), str(home / "missing")],
            env=env,
            capture_output=True,
            check=False,
        )
        assert missing.returncode != 0
    print(
        f"PASS: {len(outputs)} palettes use terminal background hue and saturation without gray mixing, with varied Base16 shades; Foot/Ghostty background stays unchanged, different background seeds vary, luminance is preserved, legacy mode works, repeated renders match, and text contrast stays >= 4.5; terminal PTY delivery, tmux palette queries/styles, and runner pass; available Fish/Starship idle-repaint check passes."
    )


if __name__ == "__main__":
    check()
