#!/usr/bin/env python3
"""Keep one connected Niri output enabled, independently of the Qt process."""

import fcntl
import hashlib
import json
import os
import socket
import subprocess
import time


def read_outputs(path):
    # Use Niri IPC directly: no Qt, Wayland connection or polling subprocess.
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.settimeout(2)
        connection.connect(path)
        connection.sendall(b'"Outputs"\n')
        with connection.makefile("rb") as stream:
            reply = json.loads(stream.readline())
    outputs = reply["Ok"]["Outputs"]
    if not isinstance(outputs, dict):
        raise ValueError("Invalid outputs reply")
    return outputs


def recovery_commands(outputs, attempt):
    connected = sorted(outputs.values(), key=lambda item: item["name"])
    if not connected or any(item.get("logical") is not None for item in connected):
        return []
    name = connected[attempt % len(connected)]["name"]
    actions = []
    if attempt >= len(connected):
        actions = [["mode", "auto"], ["scale", "1"], ["transform", "normal"],
                   ["position", "auto"], ["vrr", "off"], ["max-bpc", "8"]]
    return [["niri", "msg", "output", name, *action]
            for action in [*actions, ["on"]]]


def main():
    path = os.environ.get("NIRI_SOCKET")
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    if not path or not runtime:
        return
    key = hashlib.sha256(path.encode()).hexdigest()[:16]
    # One guard per compositor session, including across QS reloads/restarts.
    with open(os.path.join(runtime, "lc-qs-output-guard-" + key + ".lock"), "a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        attempt = 0
        while os.path.exists(path):
            try:
                outputs = read_outputs(path)
                commands = recovery_commands(outputs, attempt)
                if commands:
                    for command in commands:
                        # Recheck between fallback actions in case a screen
                        # appeared while the previous command was in flight.
                        current = read_outputs(path)
                        if any(item.get("logical") is not None
                               for item in current.values()):
                            break
                        if not any(item["name"] == command[3]
                                   for item in current.values()):
                            break
                        subprocess.run(command, timeout=3, check=False,
                                       stdout=subprocess.DEVNULL,
                                       stderr=subprocess.DEVNULL)
                    attempt += 1
                else:
                    attempt = 0
            except (OSError, ValueError, KeyError, TypeError,
                    subprocess.TimeoutExpired):
                # Transient IPC errors are not an empty list of outputs.
                pass
            time.sleep(1)


if __name__ == "__main__":
    main()
