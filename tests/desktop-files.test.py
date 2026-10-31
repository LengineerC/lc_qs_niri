import importlib.util
import json
import pathlib
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / 'scripts/desktop_files.py'
spec = importlib.util.spec_from_file_location('desktop_files', SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class DesktopTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = pathlib.Path(self.temp.name)
        self.desktop = module.Desktop(self.root / 'Desktop', self.root / 'state/positions.json')
        self.source = self.root / '文件 # %.txt'
        self.source.write_text('original')

    def test_links_and_collisions_preserve_originals(self):
        existing = self.desktop.directory / self.source.name
        existing.write_text('existing desktop file')
        name = self.desktop.link(self.source.as_uri())
        link = self.desktop.directory / name
        self.assertTrue(link.is_symlink())
        self.assertEqual(link.resolve(), self.source)
        self.assertEqual(self.desktop.link(str(self.source)), name)
        self.desktop.handle(dict(action='unlink', name=name))
        self.assertEqual(self.source.read_text(), 'original')
        self.assertEqual(existing.read_text(), 'existing desktop file')
        with self.assertRaises(ValueError):
            self.desktop.handle(dict(action='unlink', name=existing.name))

    def test_directory_and_broken_link(self):
        folder = self.root / 'folder'
        folder.mkdir()
        name = self.desktop.link(str(folder))
        self.assertTrue(self.desktop.snapshot()['entries'][0]['directory'])
        folder.rmdir()
        self.assertTrue(self.desktop.snapshot()['entries'][0]['broken'])
        self.desktop.handle(dict(action='unlink', name=name))

    def test_positions_survive_restart_per_screen(self):
        name = self.desktop.link(str(self.source))
        self.desktop.move(name, 'DP-1', 123.5, 200)
        self.desktop.move(name, 'HDMI-A-1', 400, 30)
        restarted = module.Desktop(self.desktop.directory, self.desktop.state)
        self.assertEqual(restarted.positions['DP-1'][name], dict(x=123.5, y=200))
        self.assertEqual(restarted.positions['HDMI-A-1'][name], dict(x=400, y=30))

    def test_untrusted_paths_and_positions(self):
        for name in ('../target', '/tmp/target', '..', ''):
            with self.assertRaises(ValueError):
                self.desktop.handle(dict(action='unlink', name=name))
        for source in ('https://example.com/file', 'file://server/path'):
            with self.assertRaises(ValueError):
                self.desktop.link(source)
        with self.assertRaises(ValueError):
            self.desktop.move('x', 'DP-1', float('nan'), 0)

    def test_existing_desktop_file_not_copied(self):
        path = self.desktop.directory / 'local.txt'
        path.write_text('local')
        self.assertEqual(self.desktop.link(str(path)), path.name)
        self.assertEqual(len(self.desktop.snapshot()['entries']), 1)

    def test_drop_position_and_invalid_saved_state(self):
        self.desktop.handle(dict(action='link', sources=[self.source.as_uri()],
                                 screen='DP-1', x=400, y=300))
        self.assertEqual(self.desktop.positions['DP-1'][self.source.name], dict(x=400, y=300))
        self.desktop.state.write_text('{"DP-1":{"bad":{"x":"oops"}},"broken":null}')
        restarted = module.Desktop(self.desktop.directory, self.desktop.state)
        self.assertEqual(restarted.positions, {'DP-1': {}})

    def test_external_delete_prunes_all_outputs_on_disk(self):
        name = self.desktop.link(str(self.source))
        self.desktop.move(name, 'DP-1', 20, 40)
        self.desktop.move(name, 'DP-2', 30, 60)
        self.desktop.snapshot()
        (self.desktop.directory / name).unlink()
        self.desktop.snapshot()
        self.assertTrue(all(name not in items for items in self.desktop.positions.values()))
        self.assertEqual(json.loads(self.desktop.state.read_text()), self.desktop.positions)
        self.desktop.move(name, 'DP-1', 99, 99)
        self.assertNotIn(name, self.desktop.positions['DP-1'])

    def test_external_rename_preserves_position_and_broken_link_is_retained(self):
        name = self.desktop.link(str(self.source))
        self.desktop.move(name, 'DP-1', 10, 20)
        self.desktop.snapshot()
        (self.desktop.directory / name).rename(self.desktop.directory / 'renamed.txt')
        self.desktop.snapshot()
        self.assertEqual(self.desktop.positions['DP-1']['renamed.txt'], dict(x=10, y=20))
        self.source.unlink()
        self.assertTrue(self.desktop.snapshot()['entries'][0]['broken'])
        self.assertIn('renamed.txt', self.desktop.positions['DP-1'])

    def test_offline_deletion_and_group_move(self):
        name = self.desktop.link(str(self.source))
        other = self.desktop.directory / 'other.txt'
        other.write_text('other')
        self.desktop.handle(dict(action='moveMany', screen='DP-1', items=[
            dict(name=name, x=100, y=200), dict(name=other.name, x=300, y=200)]))
        self.assertEqual(self.desktop.positions['DP-1'][other.name]['x'], 300)
        other.unlink()
        restarted = module.Desktop(self.desktop.directory, self.desktop.state)
        restarted.snapshot()
        self.assertNotIn(other.name, restarted.positions['DP-1'])
        self.assertIn(name, restarted.positions['DP-1'])

    def test_open_uses_real_decoded_path_and_reports_errors(self):
        name = self.desktop.link(self.source.as_uri())
        with patch.object(module.shutil, 'which', return_value='/usr/bin/gio'), \
             patch.object(module.subprocess, 'run') as run:
            run.return_value = subprocess.CompletedProcess([], 0, '', '')
            module.open_file((self.desktop.directory / name).as_uri())
            self.assertEqual(run.call_args.args[0], ['gio', 'open', str(self.source)])
            run.return_value = subprocess.CompletedProcess([], 1, '', 'No default application')
            with self.assertRaisesRegex(ValueError, 'No default application'):
                module.open_file((self.desktop.directory / name).as_uri())

    def test_image_preview_tracks_target_and_changes(self):
        image = self.root / '图片 # %.png'
        image.write_bytes(b'placeholder image')
        name = self.desktop.link(image.as_uri())
        first = self.desktop.snapshot()['entries'][0]['preview']
        self.assertTrue(first.startswith(image.as_uri() + '?v='))
        image.write_bytes(b'changed image bytes')
        self.assertNotEqual(first, self.desktop.snapshot()['entries'][0]['preview'])
        image.unlink()
        self.assertEqual(self.desktop.snapshot()['entries'][0]['preview'], '')

    def test_single_rename_keeps_targets_and_positions(self):
        name = self.desktop.link(str(self.source))
        folder = self.root / 'folder'
        folder.mkdir()
        other = self.desktop.link(str(folder))
        self.desktop.move(name, 'DP-1', 50, 70)
        self.desktop.move(other, 'DP-2', 90, 10)
        self.desktop.snapshot()
        self.desktop.handle(dict(action='renameMany', items=[dict(name=name, newName='renamed.txt')]))
        self.desktop.handle(dict(action='renameMany', items=[dict(name=other, newName='renamed folder')]))
        self.desktop.snapshot()
        self.assertEqual((self.desktop.directory / 'renamed.txt').resolve(), self.source)
        self.assertEqual((self.desktop.directory / 'renamed folder').resolve(), folder)
        self.assertEqual(self.desktop.positions['DP-1']['renamed.txt'], dict(x=50, y=70))
        self.assertEqual(self.desktop.positions['DP-2']['renamed folder'], dict(x=90, y=10))
        self.assertTrue(self.source.exists())

    def test_rename_rejects_collision_and_batch_remove_preserves_originals(self):
        name = self.desktop.link(str(self.source))
        existing = self.desktop.directory / 'existing.txt'
        existing.write_text('keep')
        with self.assertRaises(ValueError):
            self.desktop.rename_many([dict(name=name, newName=existing.name)])
        with self.assertRaises(ValueError):
            self.desktop.rename_many([dict(name=name, newName='../escape')])
        with self.assertRaises(ValueError):
            self.desktop.handle(dict(action='unlinkMany', names=[name, existing.name]))
        self.assertTrue((self.desktop.directory / name).is_symlink())
        self.desktop.handle(dict(action='unlinkMany', names=[name]))
        self.assertTrue(self.source.exists())
        self.assertEqual(existing.read_text(), 'keep')

    def test_suffix_icons_and_no_batch_rename(self):
        for filename, kind in [('report.PDF', 'pdf'), ('table.xlsx', 'spreadsheet'),
                               ('slide.pptx', 'presentation'), ('bundle.tar.gz', 'archive'),
                               ('music.flac', 'audio'), ('movie.mkv', 'video'),
                               ('script.py', 'code'), ('note.md', 'text'),
                               ('photo.jpeg', 'image'), ('unknown.zzzz', 'file')]:
            self.assertEqual(module.file_icon(self.root / filename)[0], kind)
        with self.assertRaises(ValueError):
            self.desktop.rename_many([dict(name='a', newName='b'), dict(name='c', newName='d')])

    def test_rename_path_validation(self):
        name = self.desktop.link(str(self.source))
        for target in ('', '   ', '.', '..', '../escape', '/tmp/escape',
                       'nested/file', 'nested\\file', 'line\nname', 'nul\0name',
                       '.hidden', 'a' * 256, '图' * 100):
            with self.subTest(target=repr(target)):
                with self.assertRaises(ValueError):
                    self.desktop.rename_many([dict(name=name, newName=target)])
                self.assertTrue((self.desktop.directory / name).is_symlink())
        self.desktop.rename_many([dict(name=name, newName='合法 名称 # 100%.txt')])
        self.assertEqual((self.desktop.directory / '合法 名称 # 100%.txt').resolve(), self.source)

    def test_containing_folder_resolves_shortcut_target(self):
        name = self.desktop.link(self.source.as_uri())
        local = self.desktop.directory / 'local.txt'
        local.write_text('local')
        entries = {entry['name']: entry for entry in self.desktop.snapshot()['entries']}
        self.assertEqual(entries[name]['parentUrl'], self.source.parent.as_uri())
        self.assertEqual(entries[local.name]['parentUrl'], self.desktop.directory.as_uri())

    def test_daemon_handles_queued_commands(self):
        commands = [dict(action='link', sources=[self.source.as_uri()]),
                    dict(action='move', name=self.source.name, screen='DP-1', x=71, y=99)]
        result = subprocess.run(['python3', str(SCRIPT), str(self.desktop.directory),
                                 str(self.desktop.state)],
                                input=''.join(json.dumps(c) + '\n' for c in commands),
                                text=True, capture_output=True, timeout=5, check=True)
        snapshots = [json.loads(line) for line in result.stdout.splitlines()]
        self.assertEqual(snapshots[-1]['positions']['DP-1'][self.source.name]['x'], 71)
        self.assertTrue((self.desktop.directory / self.source.name).is_symlink())


if __name__ == '__main__':
    unittest.main()
