#!/usr/bin/env python3

import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time


PREVIEW_BYTES = 32768


def history_files(directory):
    return sorted(directory.glob("*.json"), reverse=True)


def load_meta(path):
    try:
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, ValueError):
        return None


def remove_entry(directory, entry_id):
    for suffix in (".json", ".data"):
        try:
            (directory / f"{entry_id}{suffix}").unlink()
        except FileNotFoundError:
            pass


def prune(directory, max_entries, max_bytes=None):
    metadata = history_files(directory)
    retained = []
    for path in metadata:
        entry = load_meta(path)
        if max_bytes is not None and (
            not entry or int(entry.get("size", 0)) > max_bytes
        ):
            remove_entry(directory, path.stem)
        else:
            retained.append(path)
    for path in retained[max_entries:]:
        remove_entry(directory, path.stem)


def clipboard_types():
    try:
        result = subprocess.run(
            ["wl-paste", "--list-types"],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        return [
            line.strip()
            for line in result.stdout.decode("utf-8", "replace").splitlines()
            if line.strip()
        ]
    except OSError:
        return []


def detect_kind(data, offered_types):
    signatures = (
        b"\x89PNG\r\n\x1a\n",
        b"\xff\xd8\xff",
        b"GIF87a",
        b"GIF89a",
        b"RIFF",
        b"BM",
    )
    image_types = [mime for mime in offered_types if mime.startswith("image/")]
    text_types = [
        mime for mime in offered_types
        if mime.startswith("text/") or mime == "UTF8_STRING"
    ]
    looks_like_image = any(data.startswith(signature) for signature in signatures)
    if looks_like_image or (image_types and not text_types):
        return "image", image_types[0] if image_types else "image/png"
    try:
        data.decode("utf-8")
        return "text", text_types[0] if text_types else "text/plain;charset=utf-8"
    except UnicodeDecodeError:
        if image_types:
            return "image", image_types[0]
        return "binary", "application/octet-stream"


def capture(directory, max_bytes, max_entries):
    state = os.environ.get("CLIPBOARD_STATE", "data")
    if state in {"nil", "clear", "sensitive"}:
        return

    data = sys.stdin.buffer.read(max_bytes + 1)
    if not data or len(data) > max_bytes:
        return

    kind, mime = detect_kind(data, clipboard_types())
    if kind == "binary":
        return

    digest = hashlib.sha256(data).hexdigest()
    directory.mkdir(parents=True, exist_ok=True)

    # Re-copying an older item promotes it instead of creating duplicates.
    for metadata_path in history_files(directory):
        metadata = load_meta(metadata_path)
        if metadata and metadata.get("sha256") == digest:
            remove_entry(directory, metadata_path.stem)

    entry_id = str(time.time_ns())
    data_path = directory / f"{entry_id}.data"
    metadata_path = directory / f"{entry_id}.json"
    data_path.write_bytes(data)
    metadata_path.write_text(
        json.dumps(
            {
                "id": entry_id,
                "kind": kind,
                "mime": mime,
                "size": len(data),
                "sha256": digest,
                "timestamp": int(time.time()),
            },
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )
    prune(directory, max_entries, max_bytes)
    print("changed", flush=True)


def list_entries(directory):
    directory.mkdir(parents=True, exist_ok=True)
    for metadata_path in history_files(directory):
        metadata = load_meta(metadata_path)
        if not metadata:
            continue
        data_path = directory / f"{metadata['id']}.data"
        if not data_path.exists():
            continue
        if metadata.get("kind") == "text":
            preview = data_path.read_bytes()[:PREVIEW_BYTES].decode(
                "utf-8", "replace"
            )
        else:
            preview = ""
        metadata["preview"] = preview
        metadata["path"] = str(data_path)
        print(json.dumps(metadata, ensure_ascii=False), flush=True)


def copy_entry(directory, entry_id):
    metadata = load_meta(directory / f"{entry_id}.json")
    data_path = directory / f"{entry_id}.data"
    if not metadata or not data_path.exists():
        return 1
    try:
        subprocess.run(
            ["wl-copy", "--type", metadata.get("mime", "text/plain")],
            input=data_path.read_bytes(),
            check=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return 1
    return 0


def clear_history(directory):
    if directory.exists():
        for path in directory.iterdir():
            if path.suffix in {".json", ".data"}:
                path.unlink(missing_ok=True)
    subprocess.run(
        ["wl-copy", "--clear"],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def watch(directory, max_bytes, max_entries):
    directory.mkdir(parents=True, exist_ok=True)
    prune(directory, max_entries, max_bytes)
    command = [
        "wl-paste",
        "--watch",
        sys.executable,
        str(Path(__file__).resolve()),
        "capture",
        str(directory),
        str(max_bytes),
        str(max_entries),
    ]
    os.execvp(command[0], command)


def main():
    if len(sys.argv) < 3:
        return 2

    mode = sys.argv[1]
    directory = Path(sys.argv[2])
    if mode == "watch":
        watch(directory, int(sys.argv[3]), int(sys.argv[4]))
    elif mode == "capture":
        capture(directory, int(sys.argv[3]), int(sys.argv[4]))
    elif mode == "list":
        list_entries(directory)
    elif mode == "copy":
        return copy_entry(directory, sys.argv[3])
    elif mode == "delete":
        remove_entry(directory, sys.argv[3])
        print("changed", flush=True)
    elif mode == "clear":
        clear_history(directory)
        print("changed", flush=True)
    elif mode == "prune":
        max_bytes = int(sys.argv[4]) if len(sys.argv) > 4 else None
        prune(directory, int(sys.argv[3]), max_bytes)
        print("changed", flush=True)
    else:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
