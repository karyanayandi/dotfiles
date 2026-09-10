#!/usr/bin/python3
"""Conservative UDisks2 filesystem actions using the session's polkit agent."""

import json
import sys

PREFIX = "org.freedesktop.UDisks2."
ROOT = "/org/freedesktop/UDisks2"


def removable(objects, path):
    interfaces = objects.get(path, {})
    block = interfaces.get(PREFIX + "Block", {})
    drive = objects.get(block.get("Drive"), {}).get(PREFIX + "Drive", {})
    # Fail closed: USB alone is not proof a disk is removable.
    return bool(
        PREFIX + "Filesystem" in interfaces
        and block.get("HintSystem") is False
        and block.get("HintIgnore") is False
        and block.get("CryptoBackingDevice", "/") == "/"
        and (drive.get("Removable") is True or drive.get("MediaRemovable") is True)
        and not any(
            sibling.get(PREFIX + "Block", {}).get("Drive") == block.get("Drive")
            and (
                sibling.get(PREFIX + "Block", {}).get("HintSystem") is not False
                or any(
                    point == "/"
                    or point.startswith(("/boot", "/home", "/usr", "/var", "/etc"))
                    for point in mounts(sibling)
                )
            )
            for sibling in objects.values()
            if PREFIX + "Block" in sibling
        )
    )


def mounts(interfaces):
    return [
        bytes(value).rstrip(b"\0").decode("utf-8", "replace")
        for value in interfaces.get(PREFIX + "Filesystem", {}).get("MountPoints", [])
    ]


def ejectable(objects, drive_path):
    # Require all sibling volumes unmounted, no swap, no encrypted mappings.
    for interfaces in objects.values():
        block = interfaces.get(PREFIX + "Block", {})
        if block.get("Drive") != drive_path:
            continue
        if block.get("HintSystem") is not False or mounts(interfaces):
            return False
        if PREFIX + "Encrypted" in interfaces or interfaces.get(
            PREFIX + "Swapspace", {}
        ).get("Active"):
            return False
    return True


def main():
    try:
        from gi.repository import Gio, GLib
    except ImportError:
        print(
            json.dumps(
                {
                    "ok": False,
                    "devices": [],
                    "message": "Python GObject bindings unavailable",
                }
            )
        )
        return

    try:
        bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)

        def call(path, interface, method, parameters=None):
            return bus.call_sync(
                "org.freedesktop.UDisks2",
                path,
                interface,
                method,
                parameters,
                None,
                Gio.DBusCallFlags.ALLOW_INTERACTIVE_AUTHORIZATION,
                120000,
                None,
            ).unpack()

        def snapshot():
            return call(
                ROOT, "org.freedesktop.DBus.ObjectManager", "GetManagedObjects"
            )[0]

        objects = snapshot()
        action = sys.argv[1] if len(sys.argv) > 1 else "list"
        if action != "list":
            path = sys.argv[2] if len(sys.argv) == 3 else ""
            if action not in ("mount", "unmount", "eject") or not removable(
                objects, path
            ):
                raise ValueError("unsafe")
            interfaces = objects[path]
            drive_path = interfaces[PREFIX + "Block"]["Drive"]
            options = GLib.Variant("(a{sv})", ({},))
            if action == "eject":
                if not ejectable(objects, drive_path):
                    raise ValueError("mounted")
                drive = objects[drive_path][PREFIX + "Drive"]
                if drive.get("Ejectable"):
                    call(drive_path, PREFIX + "Drive", "Eject", options)
                elif drive.get("CanPowerOff"):
                    # PowerOff can affect sibling drives in the same enclosure.
                    siblings = [
                        value[PREFIX + "Drive"]
                        for key, value in objects.items()
                        if key != drive_path and PREFIX + "Drive" in value
                    ]
                    if drive.get("SiblingId") and any(
                        value.get("SiblingId") == drive["SiblingId"]
                        for value in siblings
                    ):
                        raise ValueError("shared")
                    call(drive_path, PREFIX + "Drive", "PowerOff", options)
                else:
                    raise ValueError("unsupported")
            else:
                call(
                    path,
                    PREFIX + "Filesystem",
                    "Mount" if action == "mount" else "Unmount",
                    options,
                )
            objects = snapshot()
        rows = []
        for path, interfaces in objects.items():
            if not removable(objects, path):
                continue
            block = interfaces[PREFIX + "Block"]
            drive = objects[block["Drive"]][PREFIX + "Drive"]
            rows.append(
                {
                    "path": path,
                    "name": block.get("IdLabel")
                    or drive.get("Model")
                    or "Removable volume",
                    "mounts": mounts(interfaces),
                    "canEject": ejectable(objects, block["Drive"])
                    and bool(drive.get("Ejectable") or drive.get("CanPowerOff")),
                }
            )
        print(json.dumps({"ok": True, "devices": rows, "message": ""}))
    except (GLib.Error, ValueError, KeyError, TypeError, OSError):
        # D-Bus exceptions may contain device paths. Return only a fixed message.
        print(
            json.dumps(
                {
                    "ok": False,
                    "devices": [],
                    "message": "Drive request failed or refused. Check UDisks2, polkit agent, and mounted sibling volumes.",
                }
            )
        )


if __name__ == "__main__":
    main()
