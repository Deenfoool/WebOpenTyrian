"""Regression checks for archive case conversion and validation."""
import sys
from pathlib import Path
import tempfile
import unittest
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from prepare_data import unpack


class DataTests(unittest.TestCase):
    def make_archive(self, folder, content):
        path = folder / 'game.zip'
        with zipfile.ZipFile(path, 'w') as z:
            for name, data in content:
                z.writestr(name, data)
        return path

    def test_flat_lowercase_and_ignored_executables(self):
        with tempfile.TemporaryDirectory() as temp:
            folder = Path(temp)
            archive = self.make_archive(folder, [
                ('TYRIAN/TYRIAN1.LVL', b'level'),
                ('TYRIAN/TYRIAN.SHP', b'shapes'),
                ('setup.EXE', b'unused'),
            ])
            target = folder / 'assets'
            unpack(archive, target)
            self.assertEqual((target / 'tyrian1.lvl').read_bytes(), b'level')
            self.assertEqual((target / 'tyrian.shp').read_bytes(), b'shapes')
            self.assertFalse((target / 'setup.exe').exists())

    def test_invalid_archive_does_not_destroy_previous_extract(self):
        with tempfile.TemporaryDirectory() as temp:
            folder = Path(temp)
            target = folder / 'assets'
            target.mkdir()
            (target / 'tyrian1.lvl').write_bytes(b'old')
            archive = self.make_archive(folder, [('README.TXT', b'no level')])
            with self.assertRaises(ValueError):
                unpack(archive, target)
            self.assertEqual((target / 'tyrian1.lvl').read_bytes(), b'old')

    def test_filename_collision_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            folder = Path(temp)
            archive = self.make_archive(folder, [
                ('TYRIAN1.LVL', b'a'), ('folder/tyrian1.lvl', b'b')])
            with self.assertRaises(ValueError):
                unpack(archive, folder / 'assets')


if __name__ == '__main__':
    unittest.main()
