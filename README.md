# WebOpenTyrian

Experimental browser port of **OpenTyrian2000** (C + SDL2 → Emscripten/WebAssembly). The repository contains reproducible build and manual GitHub Pages publishing tools, not the original game source.

**Current status:** The `main` branch contains build scripts, not a prebuilt playable game. Publishing needs an actual successful build of `dist/` and browser testing. The code changes alone cannot make the game playable on GitHub Pages.

## Build (recommended: Linux / WSL2 + Docker)

Install Docker, then clone this repository and run:

```bash
git clone https://github.com/Deenfoool/WebOpenTyrian.git
cd WebOpenTyrian
bash scripts/build-docker.sh
python3 -m http.server 8080 --directory dist
```

Open **http://localhost:8080/** in a browser. Do not open `dist/index.html` through `file://`. Docker uses a pinned Emscripten `emscripten/emsdk:4.0.12` image, downloads the pinned upstream commit and the freeware Tyrian 2000 data. A first build requires internet access and Docker.

Alternatively, with Emscripten SDK activated (`emcc` in PATH), run `bash scripts/build.sh` directly. Set `TYRIAN_ZIP=/path/to/tyrian2000.zip` to reuse an existing archive, and `EMSDK_IMAGE` to change the Docker image.

## Deploy to GitHub Pages (no GitHub Actions)

After building and testing locally:

```bash
bash scripts/publish-pages.sh
```

This commits **only the contents of `dist/`** to the separate `gh-pages` branch, and pushes without force. Then visit **Settings → Pages → Build and deployment** and choose **Deploy from a branch → gh-pages → /(root) → Save**.

Expected URL: **https://deenfoool.github.io/WebOpenTyrian/**. Each new release requires rebuilding and rerunning `publish-pages.sh`. The script checks that compiled files exist, but a real browser test is still required.

If publishing from WSL2, ensure `git push` has permission to your GitHub repository. No workflow token or GitHub Actions are used.

## Contents

- `scripts/build.sh` — downloads pinned wasm-enabled fork and freeware data, builds C sources with SDL2/Asyncify, bundles corresponding GPL source.
- `scripts/build-docker.sh` — repeatable containerized compiler entry point.
- `scripts/prepare_data.py` — case normalization and archive integrity checks.
- `scripts/publish-pages.sh` — release publishing from `dist/`.
- `web/shell.html` — browser shell, fullscreen, keyboard, save button, progress and errors.
- `tests/` — offline archive tests and checks of build artifacts.

To run tests without compiling the game:

```bash
python3 -m unittest discover -s tests -p 'test_*.py'
```

## Known limitations

- A working `.wasm` binary and a complete game session **have not been verified** in this environment (the Emscripten compiler and external downloads are not available here).
- The wasm fork uses `/data` for assets and IndexedDB-backed `/saves` for save games. Browser audio requires a user click.
- Mobile and online multiplayer are not validated.
- The original OpenTyrian2000 fork is licensed under GPL-2.0 and source/COPYING are included with the build. Tyrian 2000 resources have separate freeware terms; **verify permission to redistribute them publicly** before pushing `index.data` to Pages.

Sources: [OpenTyrian](https://github.com/opentyrian/opentyrian), [OpenTyrian2000](https://github.com/KScl/opentyrian2000), [wasm-enabled fork](https://github.com/aescarcha/opentyrian-wasm).
