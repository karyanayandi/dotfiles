#!/usr/bin/python3
"""Read Codex limits through app-server; fall back to labeled session metadata."""

import datetime
import json
import os
import selectors
import signal
import subprocess
import time
from pathlib import Path


class LiveUnavailable(Exception):
    pass


def live_limits(command=None, timeout=8):
    """Use CLI-owned authentication. Never request accounts, threads, or login."""
    deadline = time.monotonic() + timeout
    process = None
    try:
        process = subprocess.Popen(
            command or ["codex", "app-server", "--listen", "stdio://"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        with selectors.DefaultSelector() as selector:
            selector.register(process.stdout, selectors.EVENT_READ)
            pending = b""
            received = 0

            def send(message):
                process.stdin.write(json.dumps(message).encode() + b"\n")
                process.stdin.flush()

            def response(request_id):
                nonlocal pending, received
                while time.monotonic() < deadline:
                    if b"\n" not in pending:
                        if not selector.select(max(0, deadline - time.monotonic())):
                            break
                        chunk = os.read(process.stdout.fileno(), 65536)
                        if not chunk:
                            raise LiveUnavailable("CLI disconnected")
                        received += len(chunk)
                        if received > 1024 * 1024:
                            raise LiveUnavailable("CLI response too large")
                        pending += chunk
                        continue
                    line, pending = pending.split(b"\n", 1)
                    message = json.loads(line)
                    if not isinstance(message, dict):
                        raise LiveUnavailable("Invalid CLI response")
                    if message.get("id") != request_id or "method" in message:
                        continue
                    if "error" in message:
                        # Never expose backend errors, which may contain private details.
                        raise LiveUnavailable("CLI rejected limits request")
                    if not isinstance(message.get("result"), dict):
                        raise LiveUnavailable("Invalid CLI response")
                    return message["result"]
                raise LiveUnavailable("CLI limits request timed out")

            send(
                {
                    "id": 1,
                    "method": "initialize",
                    "params": {
                        "clientInfo": {"name": "quickshell_limits", "version": "1.0"}
                    },
                }
            )
            response(1)
            send({"method": "initialized"})
            send({"id": 2, "method": "account/rateLimits/read"})
            result = response(2)
            buckets = result.get("rateLimitsByLimitId")
            if buckets is not None and not isinstance(buckets, dict):
                raise LiveUnavailable("Invalid CLI bucket map")
            limits = (
                buckets.get("codex")
                if isinstance(buckets, dict)
                else result.get("rateLimits")
            )
            if not isinstance(limits, dict) or limits.get("limitId") not in (
                None,
                "codex",
            ):
                raise LiveUnavailable("No main Codex limits returned")
            windows = []
            for key in ("primary", "secondary"):
                value = limits.get(key)
                if isinstance(value, dict):
                    item = window(
                        {
                            "used_percent": value.get("usedPercent"),
                            "window_minutes": value.get("windowDurationMins"),
                            "resets_at": value.get("resetsAt"),
                        }
                    )
                    if item:
                        windows.append(item)
            if not windows:
                raise LiveUnavailable("No valid Codex windows returned")
            return {"source": "live", "observedAt": time.time(), "windows": windows}
    except FileNotFoundError:
        raise LiveUnavailable("Codex CLI not found") from None
    except (OSError, ValueError, RecursionError):
        raise LiveUnavailable("CLI limits read failed") from None
    finally:
        if process is not None:
            # Kill only this private app-server group, never an existing CLI session.
            try:
                os.killpg(process.pid, signal.SIGTERM)
                process.wait(timeout=0.2)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            except ProcessLookupError:
                process.wait()
            process.stdin.close()
            process.stdout.close()


def window(value):
    if not isinstance(value, dict):
        return None
    used = value.get("used_percent")
    minutes = value.get("window_minutes")
    reset = value.get("resets_at")
    if (
        type(used) not in (int, float)
        or not 0 <= used <= 100
        or type(minutes) is not int
        or minutes <= 0
        or type(reset) is not int
        or not 0 < reset < 253402300800
    ):
        return None
    return {"usedPercent": used, "windowMinutes": minutes, "resetsAt": reset}


def cached_limits(home):
    latest = None
    # ponytail: bounded scan of 20 recent 512 KiB tails; older events may be missed.
    # Increase bounds only if real sessions routinely exceed this between updates.
    files = sorted(
        (home / "sessions").glob("**/*.jsonl"),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )[:20]
    for path in files:
        try:
            with path.open("rb") as stream:
                offset = max(0, path.stat().st_size - 512 * 1024)
                stream.seek(offset)
                if offset:
                    stream.readline()
                lines = stream.read(512 * 1024).splitlines()
            for line in lines:
                try:
                    event = json.loads(line)
                    payload = event.get("payload", {})
                    if (
                        event.get("type") != "event_msg"
                        or payload.get("type") != "token_count"
                    ):
                        continue
                    limits = payload.get("rate_limits")
                    if not isinstance(limits, dict):
                        continue
                    # Do not present a model-specific bucket as the main Codex quota.
                    if limits.get("limit_id") not in (None, "codex"):
                        continue
                    stamp = datetime.datetime.fromisoformat(
                        event["timestamp"].replace("Z", "+00:00")
                    )
                    if stamp.tzinfo is None:
                        continue
                    observed = stamp.timestamp()
                    windows = [
                        item
                        for key in ("primary", "secondary")
                        if (item := window(limits.get(key)))
                    ]
                    if windows and (latest is None or observed > latest["observedAt"]):
                        latest = {"observedAt": observed, "windows": windows}
                except (ValueError, TypeError, KeyError, AttributeError, OverflowError):
                    continue
        except OSError:
            continue
    return latest


def main():
    try:
        home = Path(os.environ.get("CODEX_HOME", str(Path.home() / ".codex")))
        try:
            result = live_limits()
            message = "Live via Codex CLI session"
        except LiveUnavailable as error:
            result = cached_limits(home)
            if result:
                result["source"] = "cache"
            message = str(error) + (
                "; cached fallback, account unverified"
                if result
                else "; no cached limits available"
            )
        print(
            json.dumps(
                {
                    "ok": True,
                    "data": result,
                    "message": message,
                }
            )
        )
    except (OSError, ValueError):
        # Never emit paths, session content, credentials, or exception details.
        print(json.dumps({"ok": False, "message": "Local Codex cache unavailable"}))


if __name__ == "__main__":
    main()
