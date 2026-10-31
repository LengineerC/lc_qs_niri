#!/usr/bin/env python3
"""Desktop entries and positions; importing a file only creates a symlink."""
import json
import math
import mimetypes
import os
from pathlib import Path
import selectors
import shutil
import subprocess
import sys
import tempfile
from urllib.parse import unquote, urlsplit


FILE_KINDS = {
    'pdf': ('pdf', 'application-pdf'),
    'doc docx odt rtf': ('document', 'x-office-document'),
    'xls xlsx ods csv tsv': ('spreadsheet', 'x-office-spreadsheet'),
    'ppt pptx odp': ('presentation', 'x-office-presentation'),
    'zip rar 7z tar gz bz2 xz zst tgz': ('archive', 'package-x-generic'),
    'mp3 wav flac ogg m4a aac opus': ('audio', 'audio-x-generic'),
    'mp4 mkv avi mov webm m4v wmv': ('video', 'video-x-generic'),
    'py js ts jsx tsx c cpp h hpp rs go java sh qml html css json yaml yml toml xml': ('code', 'text-x-script'),
    'txt md log ini conf': ('text', 'text-x-generic'),
    'png jpg jpeg gif webp svg bmp avif heic tiff tif ico': ('image', 'image-x-generic'),
    'desktop appimage exe deb rpm': ('application', 'application-x-executable'),
}


def file_icon(path):
    if path.is_dir():
        return 'folder', 'folder'
    suffix = path.suffix.lower().lstrip('.')
    for extensions, icons in FILE_KINDS.items():
        if suffix in extensions.split():
            return icons
    mime = mimetypes.guess_type(str(path))[0] or ''
    for category in ('image', 'audio', 'video', 'text'):
        if mime.startswith(category + '/'):
            return category, category + '-x-generic'
    return 'file', 'text-x-generic'


class Desktop:
    def __init__(self, directory, state):
        self.directory = Path(directory)
        self.state = Path(state)
        self.directory.mkdir(parents=True, exist_ok=True)
        self.identities = {}
        try:
            self.positions = json.loads(self.state.read_text())
            if not isinstance(self.positions, dict):
                self.positions = {}
            self.positions = {
                screen: {name: point for name, point in entries.items()
                         if isinstance(point, dict)
                         and all(isinstance(point.get(axis), (int, float))
                                 and math.isfinite(point[axis]) for axis in ('x', 'y'))}
                for screen, entries in self.positions.items() if isinstance(entries, dict)
            }
        except (OSError, ValueError):
            self.positions = {}

    def save(self):
        self.state.parent.mkdir(parents=True, exist_ok=True)
        fd, temporary = tempfile.mkstemp(dir=self.state.parent, prefix='.desktop-')
        try:
            with os.fdopen(fd, 'w') as stream:
                json.dump(self.positions, stream, ensure_ascii=False)
                stream.flush()
                os.fsync(stream.fileno())
            os.replace(temporary, self.state)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)

    def snapshot(self):
        entries = []
        identities = {}
        for path in sorted(self.directory.iterdir(), key=lambda p: p.name.casefold()):
            if path.name.startswith('.'):
                continue
            try:
                stat = path.lstat()
            except FileNotFoundError:
                continue
            identities[path.name] = (stat.st_dev, stat.st_ino)
            preview = ""
            parent_url = path.parent.as_uri()
            kind, icon = file_icon(path)
            try:
                target = path.resolve(strict=True)
                parent_url = target.parent.as_uri()
                kind, icon = file_icon(target)
                mime = mimetypes.guess_type(str(target))[0] or ""
                if target.is_file() and mime.startswith('image/'):
                    info = target.stat()
                    preview = target.as_uri() + f'?v={info.st_mtime_ns}-{info.st_size}'
            except (OSError, RuntimeError):
                pass
            entries.append(dict(name=path.name, url=path.as_uri(), parentUrl=parent_url, preview=preview, kind=kind, icon=icon,
                                directory=path.is_dir(), link=path.is_symlink(),
                                broken=path.is_symlink() and not path.exists()))
        # Reconcile against directory entries, not target existence: a broken
        # symlink is still a desktop item. Preserve positions across live renames.
        old_names = {identity: name for name, identity in self.identities.items()}
        changed = False
        for positions in self.positions.values():
            for name, identity in identities.items():
                previous = old_names.get(identity)
                if name not in positions and previous and previous not in identities and previous in positions:
                    positions[name] = positions[previous]
                    changed = True
            for name in list(positions):
                replaced = (name in self.identities and name in identities
                            and self.identities[name] != identities[name])
                if name not in identities or replaced:
                    del positions[name]
                    changed = True
        self.identities = identities
        if changed:
            self.save()
        return dict(entries=entries, positions=self.positions)

    def link(self, source):
        if source.startswith('file:'):
            url = urlsplit(source)
            if url.netloc not in ('', 'localhost'):
                raise ValueError('Only local files can be added')
            source = unquote(url.path)
        elif '://' in source:
            raise ValueError('Only local files can be added')
        source = Path(os.path.abspath(os.path.expanduser(source)))
        if not source.exists():
            raise ValueError('File does not exist: ' + str(source))
        if source.parent == self.directory:
            return source.name
        destination = self.directory / source.name
        index = 1
        while True:
            try:
                destination.symlink_to(source, target_is_directory=source.is_dir())
                return destination.name
            except FileExistsError:
                if destination.is_symlink() and destination.resolve() == source.resolve():
                    return destination.name
                index += 1
                destination = self.directory / f'{source.stem} ({index}){source.suffix}'

    def handle(self, command):
        action = command['action']
        if action == 'link':
            errors = []
            for source in command['sources']:
                try:
                    name = self.link(source)
                    if 'screen' in command:
                        self.move(name, command['screen'], command['x'], command['y'])
                except (OSError, ValueError) as error:
                    errors.append(str(error))
            if errors:
                raise ValueError('\n'.join(errors))
        elif action == 'move':
            self.move(command['name'], command['screen'], command['x'], command['y'])
        elif action == 'moveMany':
            for item in command['items']:
                self.move(item['name'], command['screen'], item['x'], item['y'], save=False)
            self.save()
        elif action == 'renameMany':
            self.rename_many(command['items'])
        elif action == 'unlinkMany':
            names = list(dict.fromkeys(command['names']))
            if any(not self.entry(name).is_symlink() for name in names):
                raise ValueError('Only shortcuts can be removed here')
            for name in names:
                self.handle(dict(action='unlink', name=name))
        elif action == 'unlink':
            path = self.entry(command['name'])
            if not path.is_symlink():
                raise ValueError('Only shortcuts can be removed here')
            path.unlink()
            for positions in self.positions.values():
                if isinstance(positions, dict):
                    positions.pop(path.name, None)
            self.save()
        else:
            raise ValueError('Unknown desktop action')

    def rename_many(self, items):
        if len(items) != 1:
            raise ValueError('Rename one shortcut at a time')
        targets = set()
        sources = set()
        changes = []
        for item in items:
            source, target = self.entry(item['name']), self.entry(item['newName'])
            if not source.is_symlink():
                raise ValueError('Only shortcuts can be renamed here')
            if target.name.startswith('.'):
                raise ValueError('Desktop shortcut names cannot start with a dot')
            if target.name in targets or source.name in sources:
                raise ValueError('Duplicate shortcut name')
            targets.add(target.name)
            sources.add(source.name)
            if source == target:
                continue
            if os.path.lexists(target):
                raise ValueError('Name already exists: ' + target.name)
            changes.append((source, target))
        for source, target in changes:
            # Link the symlink inode itself, exclusively, then remove the old
            # name. This never overwrites a concurrent file or touches its target.
            os.link(source, target, follow_symlinks=False)
            try:
                source.unlink()
            except OSError:
                target.unlink()
                raise
            for positions in self.positions.values():
                if source.name in positions:
                    positions[target.name] = positions.pop(source.name)
            if source.name in self.identities:
                self.identities[target.name] = self.identities.pop(source.name)
            self.save()

    def entry(self, name):
        if (not isinstance(name, str) or not name.strip() or name in ('.', '..')
                or '/' in name or '\\' in name
                or any(ord(char) < 32 or ord(char) == 127 for char in name)
                or Path(name).name != name):
            raise ValueError('Invalid desktop entry')
        if len(os.fsencode(name)) > os.pathconf(self.directory, 'PC_NAME_MAX'):
            raise ValueError('Desktop entry name is too long')
        return self.directory / name

    def move(self, name, screen, x, y, save=True):
        path = self.entry(name)
        x, y = float(x), float(y)
        if not math.isfinite(x) or not math.isfinite(y):
            raise ValueError('Invalid position')
        if not os.path.lexists(path):
            return
        positions = self.positions.setdefault(str(screen), {})
        positions[name] = dict(x=max(0, x), y=max(0, y))
        if save:
            self.save()


def serve(desktop):
    selector = selectors.DefaultSelector()
    selector.register(sys.stdin, selectors.EVENT_READ)
    previous = None
    # Read bytes directly: TextIO buffering can hide queued lines from select().
    buffer = b''
    while True:
        try:
            snapshot = json.dumps(desktop.snapshot(), ensure_ascii=False)
            if snapshot != previous:
                print(snapshot, flush=True)
                previous = snapshot
        except OSError as error:
            print(json.dumps(dict(error=str(error))), flush=True)
        for key, _ in selector.select(timeout=2):
            data = os.read(key.fd, 65536)
            if not data:
                return
            buffer += data
            while b'\n' in buffer:
                line, buffer = buffer.split(b'\n', 1)
                try:
                    desktop.handle(json.loads(line))
                except (OSError, ValueError, KeyError, TypeError) as error:
                    print(json.dumps(dict(error=str(error))), flush=True)


def open_file(value):
    """Pass a decoded, resolved local path to the desktop MIME launcher."""
    if value.startswith('file:'):
        url = urlsplit(value)
        if url.netloc not in ('', 'localhost'):
            raise ValueError('Only local files can be opened')
        value = unquote(url.path)
    elif '://' in value:
        raise ValueError('Only local files can be opened')
    target = Path(value).expanduser().resolve(strict=True)
    command = ['gio', 'open', str(target)] if shutil.which('gio') else ['xdg-open', str(target)]
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode:
        raise ValueError(result.stderr.strip() or 'Unable to open file: ' + str(target))


if __name__ == '__main__':
    if sys.argv[1] == '--open':
        try:
            open_file(sys.argv[2])
        except (OSError, ValueError, RuntimeError) as error:
            print(str(error), file=sys.stderr)
            sys.exit(1)
    else:
        serve(Desktop(sys.argv[1], sys.argv[2]))
