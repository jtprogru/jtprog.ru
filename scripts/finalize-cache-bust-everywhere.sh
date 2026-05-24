#!/usr/bin/env bash
# finalize-cache-bust-everywhere.sh
#
# Доводит cache-bust для обложек до конца: применяет тот же `?v=<mtime>`
# не только в og:image / twitter:image (это уже сделано прошлым скриптом),
# но и в in-page <img> внутри <figure class="post-cover">. Это нужно,
# чтобы XPath-правило IV-шаблона `cover: $body//figure[…post-cover…]`
# забирало <img src=...> с актуальным cache-bust и не упиралось в
# залипший кеш Telegram image-proxy.
#
# Что меняется:
#   - layouts/_partials/static_cache_bust.html  — новый returnable
#     partial-helper, который вычисляет `?v=<mtime>` для static-файла
#   - layouts/_partials/cover_og_image.html     — теперь использует helper
#   - layouts/_partials/post_cover.html         — приклеивает helper к
#     in-page <img src=...>
#
# Условие: предыдущий finalize-cache-bust.sh уже отработан (og:image
# на проде уже с ?v=…).
#
# После успеха:
#   cd ~/Work/github/jtprogru/hugo-mishka && git push origin main
#   cd ~/Work/github/jtprogru/jtprog.ru   && git push origin main
#   деплой
#
# В редакторе шаблона на instantview.telegram.org — Reload по проблемной
# ссылке. `Resource fetch failed` должно исчезнуть.

set -euo pipefail

HUGO_MISHKA="${HOME}/Work/github/jtprogru/hugo-mishka"
JTPROG="${HOME}/Work/github/jtprogru/jtprog.ru"

say() { printf "\n\033[1;36m== %s ==\033[0m\n" "$*"; }

# ---------- 1. hugo-mishka ----------
say "hugo-mishka: cleanup stale sandbox artifacts"
cd "${HUGO_MISHKA}"
find .git -name "*.lock" -print -delete 2>/dev/null || true
find .git/objects -name "tmp_obj_*" -print -delete 2>/dev/null || true

say "hugo-mishka: ensure main is clean and up-to-date"
git checkout main
git pull --ff-only origin main 2>/dev/null || true

say "hugo-mishka: branch + commit cache-bust everywhere"
git checkout -b feature/cover-cache-bust-everywhere

git add layouts/_partials/static_cache_bust.html \
        layouts/_partials/cover_og_image.html \
        layouts/_partials/post_cover.html
git status --short

git commit -m "feat(cover): apply ?v=<mtime> cache-bust to in-page <img> too

Telegram's Instant View XPath rule that picks the cover from the page
(\`cover: \$body//figure[…post-cover…]\`) grabs the literal <img src=...>
from the rendered HTML, which until now had no cache-bust on static
covers. Result: even after the og:image fix, IV still tried to fetch
the bare URL, hit the image-proxy's stuck cache, and reported
'Resource fetch failed'.

Refactor the cache-bust logic into a tiny returnable helper
\`static_cache_bust.html\` and use it from both:
  - cover_og_image.html (already applied; now via the helper)
  - post_cover.html     (newly applied to the static-cover branch)

All three places — og:image, twitter:image, in-page <img> — now emit
the same URL with ?v=<unix-mtime>, so updating the cover file on disk
busts the IV proxy cache via every channel."

say "hugo-mishka: merge feature into main (--no-ff)"
git checkout main
git merge --no-ff feature/cover-cache-bust-everywhere \
  -m "Merge branch 'feature/cover-cache-bust-everywhere'"
git branch -d feature/cover-cache-bust-everywhere

# ---------- 2. jtprog.ru ----------
say "jtprog.ru: cleanup stale sandbox locks in submodule"
cd "${JTPROG}"
find .git/modules/themes/mishka -name "*.lock" -print -delete 2>/dev/null || true

say "jtprog.ru: discard sandbox copies inside submodule (will be replaced via local fetch)"
(
  cd themes/mishka
  rm -f layouts/_partials/static_cache_bust.html
  git checkout -- layouts/_partials/cover_og_image.html \
                  layouts/_partials/post_cover.html 2>/dev/null || true
)

say "jtprog.ru: bump submodule themes/mishka via local fetch"
(
  cd themes/mishka
  git fetch "${HUGO_MISHKA}" main
  git checkout main
  git merge --ff-only FETCH_HEAD
  git log --oneline -1
)

say "jtprog.ru: branch + commit submodule pointer bump"
git checkout -b chore/bump-mishka-cache-bust-everywhere
git add themes/mishka
git status --short

git commit -m "chore(theme): bump mishka with cover cache-bust everywhere"

git checkout main
git merge --ff-only chore/bump-mishka-cache-bust-everywhere
git branch -d chore/bump-mishka-cache-bust-everywhere

say "done. log summary:"
echo
echo "--- hugo-mishka main ---"
( cd "${HUGO_MISHKA}" && git log --oneline -3 )
echo
echo "--- jtprog.ru main ---"
( cd "${JTPROG}" && git log --oneline -3 )
echo
cat <<EOF

Готово. Осталось:
  cd ${HUGO_MISHKA} && git push origin main
  cd ${JTPROG}      && git push origin main

После деплоя:
  1. Открой в редакторе IV-шаблона проблемную ссылку → Reload.
  2. Убедись, что preview diff больше не показывает голый URL без ?v=.
  3. В Saved Messages кинь URL — превью должно быть с обложкой,
     IV-страница тоже с обложкой и без 'Resource fetch failed'.
EOF
