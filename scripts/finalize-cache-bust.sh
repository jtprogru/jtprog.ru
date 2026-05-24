#!/usr/bin/env bash
# finalize-cache-bust.sh
#
# Доделывает работу после finalize-og-image.sh: коммитит дополнительную
# правку в cover_og_image.html — cache-bust по mtime для static-обложек.
#
# Что делает:
#   1. В hugo-mishka:
#      - чистит залипшие .git-локи от sandbox;
#      - на feature/og-image-cache-bust коммитит обновлённый
#        cover_og_image.html;
#      - merge --no-ff в main, удаляет feature-ветку.
#   2. В jtprog.ru:
#      - чистит локи в submodule;
#      - копирует свежий cover_og_image.html из standalone-клона
#        в submodule, чтобы оба клона хранили одинаковый SHA;
#      - на chore/bump-mishka-cache-bust бампит указатель submodule;
#      - merge --no-ff в main, удаляет ветку.
#
# Условие: предыдущий скрипт finalize-og-image.sh уже отработан.
#
# После успеха:
#   cd ~/Work/github/jtprogru/hugo-mishka && git push origin main
#   cd ~/Work/github/jtprogru/jtprog.ru   && git push origin main
#
# Дальше задеплоить сайт. После деплоя:
#   - открыть в редакторе шаблона любую ссылку → Reload → og:image теперь
#     будет с ?v=<mtime>, и IV-proxy сделает по нему свежий запрос;
#   - превью с обложкой должно начать стабильно рендериться.

set -euo pipefail

HUGO_MISHKA="${HOME}/Work/github/jtprogru/hugo-mishka"
JTPROG="${HOME}/Work/github/jtprogru/jtprog.ru"

say() { printf "\n\033[1;36m== %s ==\033[0m\n" "$*"; }

# ---------- 1. hugo-mishka ----------
say "hugo-mishka: cleanup stale sandbox artifacts"
cd "${HUGO_MISHKA}"
find .git -name "*.lock" -print -delete 2>/dev/null || true
find .git/objects -name "tmp_obj_*" -print -delete 2>/dev/null || true

say "hugo-mishka: branch + commit cache-bust"
git checkout main
git pull --ff-only origin main 2>/dev/null || true
git checkout -b feature/og-image-cache-bust

git add layouts/_partials/cover_og_image.html
git status --short

git commit -m "feat(og): append ?v=<mtime> cache-bust to static cover URLs

Telegram's Instant View image proxy (ivwebcontent.telegram.org) maintains
its own opaque cache keyed by URL. When the origin replies with 304 Not
Modified, the proxy expects to reuse the previously fetched body — but
under some circumstances it loses the body and silently fails to recover,
surfacing as 'Resource fetch failed: …png' inside the rendered IV page.

For covers that live in /static/ (and therefore can't be processed by
Hugo Pipes), append ?v=<unix-mtime> to the og:image / twitter:image URL.
Updating the file on disk now naturally bumps the URL, forcing the IV
proxy (and any other downstream cache) to fetch a fresh body. Hugo
Resource covers (Page Bundle / assets/) already get a content-hashed
URL from .Resize, so they don't need any extra handling.

External http(s) URLs and pages without a cover are left untouched."

say "hugo-mishka: merge feature into main (--no-ff)"
git checkout main
git merge --no-ff feature/og-image-cache-bust -m "Merge branch 'feature/og-image-cache-bust'"
git branch -d feature/og-image-cache-bust

# ---------- 2. jtprog.ru ----------
say "jtprog.ru: cleanup stale sandbox locks in submodule"
cd "${JTPROG}"
find .git/modules/themes/mishka -name "*.lock" -print -delete 2>/dev/null || true

say "jtprog.ru: bump submodule themes/mishka via local fetch"
(
  cd themes/mishka
  git fetch "${HUGO_MISHKA}" main
  git checkout main
  git merge --ff-only FETCH_HEAD
  git log --oneline -1
)

say "jtprog.ru: branch + commit submodule pointer bump"
git checkout -b chore/bump-mishka-cache-bust
git add themes/mishka
git status --short

git commit -m "chore(theme): bump mishka with og:image cache-bust"

git checkout main
git merge --ff-only chore/bump-mishka-cache-bust
git branch -d chore/bump-mishka-cache-bust

say "done. log summary:"
echo
echo "--- hugo-mishka main ---"
(cd "${HUGO_MISHKA}" && git log --oneline -3)
echo
echo "--- jtprog.ru main ---"
(cd "${JTPROG}" && git log --oneline -3)
echo
cat <<EOF

Готово. Осталось:
  cd ${HUGO_MISHKA} && git push origin main
  cd ${JTPROG}      && git push origin main

После деплоя:
  - открой в редакторе шаблона любую проблемную ссылку → нажми Reload
  - в карточке Link Preview справа должна появиться обложка
  - в Saved Messages кинь URL — превью с обложкой
EOF
