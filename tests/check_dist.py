#!/usr/bin/env python3
"""Structural checks only; passing does NOT prove that the game runs in a browser."""
from pathlib import Path
import sys
import zipfile

root = Path(sys.argv[1] if len(sys.argv) > 1 else 'dist')
required = ('index.html', 'index.js', 'index.wasm', 'index.data',
            'source-code.zip', 'source-commit.txt', 'COPYING.txt', '.nojekyll')
for name in required:
    file = root / name
    assert file.is_file(), f'Missing: {file}'
    if name != '.nojekyll':
        assert file.stat().st_size > 0, f'Empty: {file}'
assert (root / 'index.wasm').read_bytes()[:4] == bytes([0, 97, 115, 109]), 'Invalid WASM magic'
html = (root / 'index.html').read_text(encoding='utf-8')
assert 'OpenTyrian2000' in html and '<canvas' in html, 'Invalid HTML shell'
assert (root / 'index.data').stat().st_size > 1024, 'Game archive seems empty'
with zipfile.ZipFile(root / 'source-code.zip') as sources:
    assert 'src/opentyr.c' in sources.namelist(), 'Corresponding C source missing'
print('Structural checks passed: HTML, JavaScript, WASM, data, source and license.')
