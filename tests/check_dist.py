#!/usr/bin/env python3
"""Fast build artifact checks; does NOT replace running in a browser."""
from pathlib import Path
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else 'dist')
expected = ('index.html', 'index.js', 'index.wasm', 'index.data',
            'source-code.zip', 'source-commit.txt', 'COPYING.txt')
for name in expected:
    path = root / name
    assert path.is_file() and path.stat().st_size > 0, f'Missing/empty: {path}'
assert b'\0asm' == (root / 'index.wasm').read_bytes()[:4], 'Invalid WASM header'
assert b'OpenTyrian2000' in (root / 'index.html').read_bytes(), 'Unexpected HTML shell'
print('Artifact checks passed (binary header, HTML, data, license and source).')
