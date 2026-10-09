#!/usr/bin/env bash
# Compile the game with a fixed Emscripten toolchain without installing emsdk.
set -Eeuo pipefail
cd "$(dirname "$0")/.."
if ! command -v docker >/dev/null 2>&1; then
  echo 'Docker is required. Install Docker or use Emscripten directly with scripts/build.sh.' >&2
  exit 1
fi
IMAGE="${EMSDK_IMAGE:-emscripten/emsdk:4.0.12}"
docker run --rm \
  -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
  -v "$PWD:/src" -w /src \
  "$IMAGE" bash -euc '
    bash scripts/build.sh
    python3 -m unittest discover -s tests -p "test_*.py"
    chown -R "$HOST_UID:$HOST_GID" dist .work
  '
