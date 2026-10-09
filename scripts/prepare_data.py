#!/usr/bin/env python3
"""Extract Tyrian 2000 files to lowercase, flat, case-sensitive WASM paths."""
from pathlib import Path
import shutil
import sys
import tempfile
import zipfile

EXCLUDE = ('.exe', '.com', '.bat', '.zip', '.dll')
MAX_TOTAL_BYTES = 200 * 1024 * 1024


def unpack(archive: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    total_size = 0
    names = set()
    # Only replace the last good extract after validating a complete archive.
    with tempfile.TemporaryDirectory(prefix='tyrian-data-', dir=destination.parent) as temp:
        staging = Path(temp) / 'assets'
        staging.mkdir()
        with zipfile.ZipFile(archive) as source:
            for item in source.infolist():
                if item.is_dir():
                    continue
                name = Path(item.filename.replace('\\', '/')).name.lower()
                if not name or name.endswith(EXCLUDE):
                    continue
                if name in names:
                    raise ValueError(f'duplicate resource name: {name}')
                if item.file_size < 0 or total_size + item.file_size > MAX_TOTAL_BYTES:
                    raise ValueError('game archive expands beyond the resource limit')
                names.add(name)
                total_size += item.file_size
                with source.open(item) as infile, (staging / name).open('wb') as outfile:
                    shutil.copyfileobj(infile, outfile)
        if 'tyrian1.lvl' not in names:
            raise ValueError('tyrian1.lvl is missing — not the Tyrian 2000 data archive')
        if destination.exists():
            shutil.rmtree(destination)
        staging.rename(destination)
    print(f'Prepared {len(names)} resource files in {destination}')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit('Usage: prepare_data.py GAME.zip OUTPUT_DIR')
    unpack(Path(sys.argv[1]), Path(sys.argv[2]))
