#!/usr/bin/env bash
# Build a standalone GitHub Pages site from the WebAssembly-ready OpenTyrian2000 fork.
set -Eeuo pipefail
cd "$(dirname "$0")/.."

for tool in git curl python3 emcc; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing required tool: $tool" >&2
    exit 1
  fi
done

SOURCE_REPO="${SOURCE_REPO:-https://github.com/aescarcha/opentyrian-wasm.git}"
WORK="${WORK:-$PWD/.work}"
mkdir -p "$WORK" dist
if [[ ! -d "$WORK/source/.git" ]]; then
  git clone --depth 1 "$SOURCE_REPO" "$WORK/source"
fi
SOURCE="$WORK/source"
if [[ ! -f "$SOURCE/src/opentyr.c" || ! -f "$SOURCE/COPYING" ]]; then
  echo "Unexpected source repository layout" >&2
  exit 1
fi

# Do not commit game data to this repository. Download the freeware release at build time.
DATA_ZIP="${TYRIAN_ZIP:-$WORK/tyrian2000.zip}"
if [[ ! -f "$DATA_ZIP" ]]; then
  curl --fail --location --retry 3 --retry-all-errors --silent --show-error \
    'https://www.camanis.net/tyrian/tyrian2000.zip' -o "$DATA_ZIP"
fi
python3 scripts/prepare_data.py "$DATA_ZIP" "$WORK/game-data"

# libSDL2 (Emscripten port) is provided by emcc. The original program uses
# blocking SDL timing and emscripten_sleep(), so Asyncify is necessary.
# Source's file.c reads from /data and config.c writes to IDBFS-mounted /saves.
# IMPORTANT: we compile the fork rather than the unmodified native OpenTyrian.
shopt -s nullglob
sources=("$SOURCE"/src/*.c)
if (( ${#sources[@]} == 0 )); then
  echo 'No C sources found' >&2; exit 1
fi

emcc "${sources[@]}" \
  -O2 -std=gnu99 -DNDEBUG -DTARGET_EMSCRIPTEN \
  '-DOPENTYRIAN_VERSION="web"' \
  -sUSE_SDL=2 \
  -sASYNCIFY=1 -sASYNCIFY_STACK_SIZE=262144 \
  -sSTACK_SIZE=1048576 \
  -sINITIAL_MEMORY=134217728 -sALLOW_MEMORY_GROWTH=1 \
  -sFORCE_FILESYSTEM=1 -sEXPORTED_RUNTIME_METHODS=FS \
  -sASSERTIONS=1 \
  -lidbfs.js -lm \
  --preload-file "$WORK/game-data@/data" \
  --shell-file web/shell.html \
  -o dist/index.html

# Keep corresponding GPL source and exact revision alongside the binary.
cp "$SOURCE/COPYING" dist/COPYING.txt
SOURCE_REPO="$SOURCE_REPO" git -C "$SOURCE" rev-parse HEAD > dist/source-commit.txt
python3 - "$SOURCE" <<'PY'
from pathlib import Path
import sys, zipfile
s = Path(sys.argv[1]); out = Path('dist/source-code.zip')
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    for p in [*s.glob('src/**/*'), s/'COPYING', s/'Makefile.emscripten', s/'shell.html']:
        if p.is_file(): z.write(p, p.relative_to(s))
    for p in [*Path('scripts').glob('*'), Path('web/shell.html')]:
        if p.is_file(): z.write(p, 'site/' + str(p))
PY

touch dist/.nojekyll
printf 'Build successful: %s\n' "$PWD/dist/index.html"
