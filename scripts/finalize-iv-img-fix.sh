#!/usr/bin/env bash
# finalize-iv-img-fix.sh
#
# Финал по фиче «совместимость с Telegram Instant View»: убираем <p>-обёртку
# вокруг одиночных картинок и приклеиваем cache-bust к in-page <img> из
# render-image hook.
#
# Что меняется:
#   В hugo-mishka:
#     - layouts/_default/_markup/render-image.html — fallback-ветка (static
#       и внешние URL) теперь приклеивает ?v=<mtime> к src через тот же
#       static_cache_bust.html helper.
#
#   В jtprog.ru:
#     - hugo.yaml — markup.goldmark.parser.wrapStandAloneImageWithinParagraph:
#       false. Goldmark больше не оборачивает одиночные картинки в <p>;
#       render-image hook отдаёт сразу <figure>, и IV перестаёт ругаться
#       «<img> is not supported in <p>».
#     - submodule themes/mishka — bump на новый main hugo-mishka.
#
# Условие: предыдущие два скрипта (finalize-og-image.sh и
# finalize-cache-bust-everywhere.sh) уже отработаны.
#
# После успеха:
#   cd ~/Work/github/jtprogru/hugo-mishka && git push origin main
#   cd ~/Work/github/jtprogru/jtprog.ru   && git push origin main
#   деплой
#
# Проверка после деплоя:
#   - в редакторе IV-шаблона на проблемной странице (например,
#     https://jtprog.ru/how-read-qr-code/) — Reload.
#   - ошибка «Element <img> is not supported in <p>» должна исчезнуть.
#   - PREVIEW справа должен корректно рендерить IV.

set -euo pipefail

HUGO_MISHKA="${HOME}/Work/github/jtprogru/hugo-mishka"
JTPROG="${HOME}/Work/github/jtprogru/jtprog.ru"

say() { printf "\n\033[1;36m== %s ==\033[0m\n" "$*"; }

# ---------- 1. hugo-mishka: cache-bust в render-image hook ----------
say "hugo-mishka: cleanup stale sandbox artifacts"
cd "${HUGO_MISHKA}"
find .git -name "*.lock" -print -delete 2>/dev/null || true
find .git/objects -name "tmp_obj_*" -print -delete 2>/dev/null || true

say "hugo-mishka: ensure main is clean"
git checkout main
git pull --ff-only origin main 2>/dev/null || true

say "hugo-mishka: branch + commit render-image cache-bust"
git checkout -b feature/render-image-cache-bust

git add layouts/_default/_markup/render-image.html
git status --short

git commit -m "feat(markup): apply static cache-bust in render-image fallback

The render-image hook's fallback branch (used for static-served files and
external URLs that aren't page-bundle resources) now appends ?v=<mtime>
to the src for static files via the shared static_cache_bust.html helper.

Without this, in-page inline images like /qr_labeled.png get cached by
Telegram's IV image-proxy and stick there even after the file changes,
manifesting as 'Resource fetch failed' inside the rendered IV page.
External http(s) URLs are left untouched."

say "hugo-mishka: merge feature into main (--no-ff)"
git checkout main
git merge --no-ff feature/render-image-cache-bust \
  -m "Merge branch 'feature/render-image-cache-bust'"
git branch -d feature/render-image-cache-bust

# ---------- 2. jtprog.ru: hugo.yaml + submodule bump ----------
say "jtprog.ru: cleanup stale sandbox locks in submodule"
cd "${JTPROG}"
find .git/modules/themes/mishka -name "*.lock" -print -delete 2>/dev/null || true

say "jtprog.ru: discard any sandbox copies inside submodule"
(
  cd themes/mishka
  git checkout -- layouts/_default/_markup/render-image.html 2>/dev/null || true
)

say "jtprog.ru: bump submodule themes/mishka via local fetch"
(
  cd themes/mishka
  git fetch "${HUGO_MISHKA}" main
  git checkout main
  git merge --ff-only FETCH_HEAD
  git log --oneline -1
)

# --- Commit 1: hugo.yaml fix ---
say "jtprog.ru: branch + commit hugo.yaml goldmark fix"
git checkout -b chore/disable-standalone-image-paragraph

# Стейджим ТОЛЬКО hugo.yaml — submodule пойдёт следующим коммитом
git add hugo.yaml
git status --short

git commit -m "chore(config): disable wrapStandAloneImageWithinParagraph

Goldmark by default wraps a paragraph containing only a single image
into <p>...</p>, which is invalid HTML when the render-image hook
returns <figure> (resulting in <p><figure><img></figure></p>) and is
explicitly rejected by Telegram Instant View with
\"<img> is not supported in <p>\".

Disable the wrap so the render-image hook output flows in at the
block level."

# --- Commit 2: submodule bump ---
say "jtprog.ru: commit submodule pointer bump"
git add themes/mishka
git status --short

git commit -m "chore(theme): bump mishka with render-image cache-bust"

git checkout main
git merge --no-ff chore/disable-standalone-image-paragraph \
  -m "Merge branch 'chore/disable-standalone-image-paragraph'"
git branch -d chore/disable-standalone-image-paragraph

say "done. log summary:"
echo
echo "--- hugo-mishka main ---"
( cd "${HUGO_MISHKA}" && git log --oneline -3 )
echo
echo "--- jtprog.ru main ---"
( cd "${JTPROG}" && git log --oneline -5 )
echo
cat <<EOF

Готово. Осталось:
  cd ${HUGO_MISHKA} && git push origin main
  cd ${JTPROG}      && git push origin main

После деплоя:
  1. Открой https://instantview.telegram.org/my/jtprog.ru/?url=https://jtprog.ru/how-read-qr-code/
  2. Нажми Reload в ORIGINAL.
  3. Ошибка «<img> is not supported in <p>» должна уйти.
  4. PREVIEW справа должен показать корректный Instant View.

Если в шаблоне у тебя ещё стоит правило @split_parent: //p/img —
его можно теперь убрать, оно уже не нужно (картинки и так вне <p>).
EOF
