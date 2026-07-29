#!/usr/bin/env python3

import hashlib
import json
import os
import pathlib
import subprocess
import sys


EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}


def preview_path(source: str, cache_directory: str) -> str:
    source_path = pathlib.Path(source).expanduser().resolve()
    cache_path = pathlib.Path(cache_directory).expanduser().resolve()
    cache_path.mkdir(parents=True, exist_ok=True)

    try:
        stamp = source_path.stat().st_mtime_ns
    except OSError:
        return ""

    digest = hashlib.sha256(
        f"{source_path}\0{stamp}".encode("utf-8")
    ).hexdigest()[:24]
    output = cache_path / f"{digest}.png"
    if output.exists():
        return str(output)

    command = [
        "magick",
        str(source_path),
        "-auto-orient",
        "-thumbnail",
        "640x360^",
        "-gravity",
        "center",
        "-extent",
        "640x360",
        str(output),
    ]
    result = subprocess.run(
        command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    return str(output) if result.returncode == 0 and output.exists() else ""


def scan(directory: str, cache_directory: str) -> int:
    root = pathlib.Path(directory).expanduser()
    if not root.is_dir():
        return 0

    files = [
        item
        for item in root.iterdir()
        if item.is_file() and item.suffix.lower() in EXTENSIONS
    ]
    files.sort(key=lambda item: item.stat().st_mtime_ns, reverse=True)

    for item in files:
        preview = preview_path(str(item), cache_directory)
        print(
            json.dumps(
                {"path": str(item.resolve()), "preview": preview},
                ensure_ascii=False,
            ),
            flush=True,
        )
    return 0


def main() -> int:
    if len(sys.argv) != 4 or sys.argv[1] != "scan":
        return 2
    return scan(sys.argv[2], sys.argv[3])


if __name__ == "__main__":
    raise SystemExit(main())
