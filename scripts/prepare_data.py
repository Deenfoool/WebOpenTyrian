#!/usr/bin/env python3
"""Unpack Tyrian 2000 freeware assets to lowercase flat paths for case-sensitive WASM FS.

Usage: python3 scripts/prepare_data.py tyrian2000.zip .work/game-data
"""
import sys
import zipfile
from pathlib import Path


def unpack(archive: Path, destination: Path) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    accepted = 0
    names = set()
    with zipfile.ZipFile(archive) as z:
        for item in z.infolist():
            if item.is_dir():
                continue
            # Ignore bundled binaries, setup utilities and nested archives.
            name = Path(item.filename.replace('\\', '/')).name.lower()
            if not name or name.endswith(('.exe', '.com', '.bat', '.zip', '.dll')):
                continue
            if name in names:
                raise ValueError(f'duplicate asset filename: {name}')
            names.add(name)
            (destination / name).write_bytes(z.read(item))
            accepted += 1
    if not (destination / 'tyrian1.lvl').is_file():
        raise ValueError('tyrian1.lvl is missing — wrong or incomplete Tyrian 2000 archive')
    print(f'Prepared {accepted} resource files in {destination}')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit('Usage: prepare_data.py GAME.zip OUTPUT_DIR')
    unpack(Path(sys.argv[1]), Path(sys.argv[2]))
