"""Run with /usr/bin/python3; needs matugen, Ghostty, PyGObject and a GTK display.

Uses a private HOME and session bus, unmapped GTK widgets, and a windowless
Ghostty child. Never runs wallpaper-theme or signals existing terminals.
"""

import os
import signal
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def probe(home):
    import gi

    gi.require_version("Gtk", "4.0")
    gi.require_version("Adw", "1")
    from gi.repository import Adw, Gdk, GLib, Gtk

    Adw.init()
    display = Gdk.Display.get_default()
    assert display is not None, "GTK display required"
    css = home / ".config/gtk-4.0/colors.css"
    blue = css.read_text()
    red = (home / "red.css").read_text()
    window = Adw.ApplicationWindow()
    box = Gtk.Box()
    window.set_content(box)
    labels = []
    # Read native UI variables through computed foreground colors, without mapping.
    provider = Gtk.CssProvider()
    provider.load_from_string(
        "".join(
            f"label.{name} {{ color: var(--{name}); }}"
            for name in ("headerbar-bg-color", "popover-bg-color", "accent-bg-color")
        )
    )
    Gtk.StyleContext.add_provider_for_display(display, provider, 801)
    for name in ("headerbar-bg-color", "popover-bg-color", "accent-bg-color"):
        label = Gtk.Label(label=name)
        label.add_css_class(name)
        box.append(label)
        labels.append(label)

    def colors():
        context = GLib.MainContext.default()
        for _ in range(20):
            while context.pending():
                context.iteration(False)
            time.sleep(0.01)
        window.allocate(200, 200, -1, None)
        return [label.get_color().to_string() for label in labels]

    window.realize()
    startup = colors()
    runtime = Gtk.CssProvider()
    runtime.load_from_string(red)
    Gtk.StyleContext.add_provider_for_display(display, runtime, 603)
    assert colors() == startup, "Startup user CSS should outrank Ghostty runtime CSS"
    custom = None
    for text in (red, blue, red):
        if custom is not None:
            Gtk.StyleContext.remove_provider_for_display(display, custom)
        custom = Gtk.CssProvider()
        errors = []
        custom.connect(
            "parsing-error", lambda *args, errors=errors: errors.append(str(args[-1]))
        )
        custom.load_from_string(text)
        assert not errors, errors
        Gtk.StyleContext.add_provider_for_display(display, custom, 800)
        current = colors()
        expected = []
        for label in labels:
            value = text.split(f"--{label.get_label()}: ", 1)[1].split(";", 1)[0]
            color = Gdk.RGBA()
            assert color.parse(value), value
            expected.append(color.to_string())
        assert current == expected, (expected, current)
        print("PASS native CSS variables", current, flush=True)
    window.destroy()

    # Real installed Ghostty: no window, no shell, no reuse of a user instance.
    log = home / "ghostty.log"
    with (
        log.open("w") as output,
        subprocess.Popen(
            ["ghostty", "--gtk-single-instance=false", "--initial-window=false"],
            stdout=output,
            stderr=subprocess.STDOUT,
        ) as process,
    ):
        try:
            for stage, text in enumerate((blue, red, blue, red), 1):
                if stage > 1:
                    replacement = css.with_suffix(".tmp")
                    replacement.write_text(text)
                    replacement.replace(css)
                    process.send_signal(signal.SIGUSR2)
                deadline = time.monotonic() + 10
                while time.monotonic() < deadline:
                    logs = log.read_text()
                    assert process.poll() is None, logs
                    status = Path(f"/proc/{process.pid}/status").read_text()
                    mask = next(
                        x.split()[1]
                        for x in status.splitlines()
                        if x.startswith("SigCgt:")
                    )
                    ready = int(mask, 16) & (1 << (signal.SIGUSR2 - 1))
                    marker = "received SIGUSR2, reloading configuration"
                    if (
                        ready
                        and logs.count(marker) == stage - 1
                        and f"loading gtk-custom-css path={css}"
                        in logs.rsplit(marker, 1)[-1]
                    ):
                        break
                    time.sleep(0.05)
                else:
                    raise AssertionError(logs)
                assert "error" not in logs.lower(), logs
                print(f"PASS Ghostty custom CSS load {stage}", flush=True)
            assert logs.count("received SIGUSR2, reloading configuration") == 3, logs
        finally:
            # Only our windowless child is terminated.
            process.terminate()
            process.wait(timeout=5)


def main():
    if len(sys.argv) == 3 and sys.argv[1] == "--probe":
        probe(Path(sys.argv[2]))
        return
    with tempfile.TemporaryDirectory(prefix="ghostty-theme-test-") as directory:
        home = Path(directory)
        config = home / ".config"
        (config / "ghostty").mkdir(parents=True)
        (config / "gtk-4.0").mkdir()
        (config / "theme/generated").mkdir(parents=True)
        template = home / "matugen.toml"
        template.write_text(
            "[config]\n[templates.gtk]\n"
            f'input_path = "{ROOT / "config/theme/templates/gtk4.css"}"\n'
            f'output_path = "{config / "gtk-4.0/colors.css"}"\n'
            "[templates.ghostty]\n"
            f'input_path = "{ROOT / "config/theme/templates/ghostty.conf"}"\n'
            f'output_path = "{config / "theme/generated/ghostty"}"\n'
        )
        for color in ("#ff0000", "#0000ff"):
            subprocess.run(
                [
                    "matugen",
                    "-c",
                    str(template),
                    "--mode",
                    "dark",
                    "color",
                    "hex",
                    color,
                ],
                check=True,
                capture_output=True,
            )
            if color == "#ff0000":
                (home / "red.css").write_text(
                    (config / "gtk-4.0/colors.css").read_text()
                )
        (config / "gtk-4.0/gtk.css").write_text('@import url("colors.css");\n')
        ghostty_config = (ROOT / "config/ghostty/config").read_text()
        (config / "ghostty/config").write_text(
            ghostty_config.replace("/home/karyana/.config", str(config))
        )
        env = dict(
            os.environ,
            HOME=directory,
            XDG_CONFIG_HOME=str(config),
            XDG_CACHE_HOME=str(home / ".cache"),
            XDG_DATA_HOME=str(home / ".local/share"),
            XDG_CONFIG_DIRS="/etc/xdg",
            GTK_A11Y="none",
            GIO_USE_VFS="local",
            ADW_DISABLE_PORTAL="1",
            GSETTINGS_BACKEND="memory",
        )
        subprocess.run(["ghostty", "+validate-config"], env=env, check=True, timeout=10)
        bus = home / "bus.conf"
        bus.write_text(
            "<busconfig><type>session</type><listen>unix:tmpdir=/tmp</listen>"
            '<policy context="default"><allow send_destination="*"/>'
            '<allow receive_sender="*"/><allow own="*"/></policy></busconfig>'
        )
        subprocess.run(
            [
                "dbus-run-session",
                "--config-file",
                str(bus),
                "--",
                sys.executable,
                __file__,
                "--probe",
                directory,
            ],
            env=env,
            check=True,
            timeout=60,
        )


if __name__ == "__main__":
    main()
