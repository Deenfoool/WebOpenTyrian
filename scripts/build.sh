#!/usr/bin/env bash
# Build the complete static WebAssembly site; no GitHub Actions required.
set -Eeuo pipefail
cd "$(dirname "$0")/.."

for tool in git curl python3 emcc; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Required tool is missing: %s (or use bash scripts/build-docker.sh)\n' "$tool" >&2
    exit 1
  fi
done

SOURCE_REPO="${SOURCE_REPO:-https://github.com/aescarcha/opentyrian-wasm.git}"
# Fixed revision of the wasm-enabled fork, not a moving main branch.
SOURCE_REV="${SOURCE_REV:-b17ae7174d4a195223f9b6b9dc3f5a1916d06a75}"
WORK="${WORK:-$PWD/.work}"
mkdir -p "$WORK"
WORK="$(cd "$WORK" && pwd)"
SOURCE="$WORK/source"

if [[ ! -d "$SOURCE/.git" ]]; then
  git clone --depth 1 --no-tags "$SOURCE_REPO" "$SOURCE"
fi
if [[ "$(git -C "$SOURCE" rev-parse HEAD)" != "$SOURCE_REV" ]]; then
  git -C "$SOURCE" fetch --depth 1 origin "$SOURCE_REV"
  git -C "$SOURCE" checkout --detach "$SOURCE_REV"
fi
if [[ ! -f "$SOURCE/src/opentyr.c" || ! -f "$SOURCE/COPYING" ]]; then
  echo 'Unsupported OpenTyrian source checkout' >&2
  exit 1
fi

DATA_ZIP="${TYRIAN_ZIP:-$WORK/tyrian2000.zip}"
if [[ ! -f "$DATA_ZIP" ]]; then
  echo 'Downloading the Tyrian 2000 freeware data archive...'
  curl --fail --location --retry 3 --retry-delay 2 --silent --show-error \
    'https://www.camanis.net/tyrian/tyrian2000.zip' -o "$DATA_ZIP"
fi
python3 scripts/prepare_data.py "$DATA_ZIP" "$WORK/game-data"

mkdir -p dist
# Old build products must never be mistaken for newly compiled artifacts.
rm -f dist/index.html dist/index.js dist/index.wasm dist/index.data
shopt -s nullglob
sources=("$SOURCE"/src/*.c)
if (( ${#sources[@]} == 0 )); then
  echo 'No C sources found' >&2
  exit 1
fi

# SDL2 supplies the display, sound and input; Asyncify permits blocking game loops.
# The fork uses /data for resources and /saves for its IDBFS save directory.
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

cp "$SOURCE/COPYING" dist/COPYING.txt
git -C "$SOURCE" rev-parse HEAD > dist/source-commit.txt
python3 - "$SOURCE" <<'PY'
from pathlib import Path
import sys
import zipfile

source = Path(sys.argv[1])
with zipfile.ZipFile('dist/source-code.zip', 'w', zipfile.ZIP_DEFLATED) as z:
    for path in sorted(source.glob('src/**/*')):
        if path.is_file():
            z.write(path, path.relative_to(source))
    for name in ('COPYING', 'Makefile.emscripten', 'shell.html', 'README-WASM.md'):
        path = source / name
        if path.is_file():
            z.write(path, name)
    for path in sorted(Path('scripts').glob('*')):
        if path.is_file():
            z.write(path, 'site/' + str(path))
    for path in (Path('web/shell.html'), Path('tests/check_dist.py'), Path('README.md')):
        z.write(path, 'site/' + str(path))
PY
touch dist/.nojekyll
python3 tests/check_dist.py dist
echo "Build complete: $PWD/dist/index.html"
