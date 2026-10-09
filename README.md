# WebOpenTyrian (experimental)

A **browser/WebAssembly build pipeline**, plus a standalone HTML shell and GitHub Pages workflow, for the GPL-2.0 OpenTyrian2000 fork. The upstream C game is **not** reimplemented in JavaScript.

> ⚠️ Status: this repository contains the integration code, **not a verified playable binary**. The actual Emscripten compilation must run in GitHub Actions or on a computer with `emcc`; browser testing is still required.

## Быстрый запуск в своём GitHub

1. Загрузите **всё содержимое** этой папки в пустой репозиторий `Deenfoool/WebOpenTyrian` (включая скрытую папку `.github`), в ветку `main`.
2. Откройте **Settings → Pages → Build and deployment → Source → GitHub Actions**.
3. Откройте **Actions → Build and publish WebOpenTyrian → Run workflow**, если сборка не запустилась автоматически при push.
4. После **зелёной** сборки сайт будет доступен по адресу `https://deenfoool.github.io/WebOpenTyrian/` (с учётом настройки Pages). Архив сайта появится в Artifacts выполнения.

Если сборка красная — смотрите логи Actions. Это экспериментальный порт; успех не гарантирован.

## Локальная сборка (Linux/macOS/WSL)

Нужны Git, Python 3, curl и активированный [Emscripten SDK](https://emscripten.org/docs/getting_started/downloads.html).

```bash
source /path/to/emsdk/emsdk_env.sh
bash scripts/build.sh
python3 tests/check_dist.py dist
python3 -m http.server 8080 --directory dist
```

Откройте `http://localhost:8080`, кликните на игровую область для фокуса и звука. Не открывайте `index.html` через `file://` — браузер заблокирует загрузку `.wasm` и `.data`.

## Что собирается

- Исходники: [aescarcha/opentyrian-wasm](https://github.com/aescarcha/opentyrian-wasm), форк OpenTyrian2000 с поддержкой `__EMSCRIPTEN__` (игровые исходники под GPL-2.0).
- Emscripten компилирует C-код в `index.wasm`, а SDL2 подключает отображение/клавиатуру/звук.
- Включён Asyncify для игры с блокирующими вызовами и `emscripten_sleep`.
- Ресурсы скачиваются при сборке из [архива freeware Tyrian 2000](https://www.camanis.net/tyrian/tyrian2000.zip), нормализуются в lowercase и упаковываются в `index.data` по адресу `/data`.
- Сохранения: IDBFS в `/saves` (IndexedDB), с периодической синхронизацией и отдельной кнопкой.
- Сетевой режим **не** поддерживается. Работа на мобильных устройствах не гарантирована.

## Технические особенности и ограничения

- Upstream форк имеет `Makefile.emscripten`, который ссылается на `web/shell.html`, хотя шаблон расположен в корне проекта. Поэтому здесь используется собственный скрипт и собственный HTML-шаблон.
- Мы **не** храним заранее скомпилированный `.wasm` и оригинальные игровые ресурсы в git.
- Для воспроизводимости сборки нужен пин версии emsdk и исходного коммита; сейчас workflow использует `latest` и актуальную ветку форка. В готовом сайте записан `source-commit.txt` и вложен `source-code.zip`.
- Если нет звука — кликните на canvas. Если сохранение не восстановилось — проверьте браузерный IndexedDB и журнал консоли.
- Интеграция ещё **не проходила реальный запуск через emcc** в среде подготовки: инструмента `emcc` там не было и сеть GitHub недоступна. Проверялись только синтаксис скриптов и локальные тесты обработки ресурсов.

## Лицензия

Исходники OpenTyrian2000 находятся под GPL-2.0 (см. `COPYING.txt` в сгенерированном сайте). Соответствующие исходники и скрипты сборки также кладутся в `source-code.zip`. Данные Tyrian 2000 — отдельно распространяемый freeware-контент, **не** GPL; перед публичной публикацией убедитесь, что их условия разрешают такую дистрибуцию.

Проект основан на [OpenTyrian](https://github.com/opentyrian/opentyrian), [OpenTyrian2000](https://github.com/KScl/opentyrian2000) и [aescarcha/opentyrian-wasm](https://github.com/aescarcha/opentyrian-wasm).
