#!/usr/bin/env bash
# finalize-og-image.sh
#
# Завершает workflow по фиче «auto-resize cover для og:image».
#
# Что делает:
#   1. В hugo-mishka:
#        - чистит залипшие .git-локи и tmp-объекты из sandbox;
#        - на feature/og-image-auto-resize коммитит cover_og_image.html +
#          правки opengraph.html / twitter_cards.html;
#        - merge --no-ff в main и удаляет feature-ветку.
#   2. В jtprog.ru:
#        - чистит залипшие локи в submodule themes/mishka;
#        - откатывает тестовые правки внутри submodule;
#        - на feature/optimize-og-static-covers коммитит пересохранённые
#          static/*.png;
#        - merge --no-ff в main и удаляет feature-ветку.
#   3. Bump submodule themes/mishka → main hugo-mishka:
#        - локальный fetch из standalone-клона hugo-mishka, чтобы SHA
#          совпали и не пришлось ничего пушить заранее;
#        - merge --ff-only в submodule до того же коммита;
#        - в jtprog.ru — отдельный commit с обновлённым указателем submodule.
#
# Безопасность:
#   - скрипт ничего не пушит в origin;
#   - все merge — локальные --no-ff;
#   - hugo.yaml (твой dev-switch theme: mishka-dev) и themes/mishka-dev НЕ
#     трогаются.
#
# После успеха:
#   cd ~/Work/github/jtprogru/hugo-mishka && git push origin main
#   cd ~/Work/github/jtprogru/jtprog.ru   && git push origin main
#   (и потом не забыть прогнать @WebpageBot по нескольким ссылкам).

set -euo pipefail

HUGO_MISHKA="${HOME}/Work/github/jtprogru/hugo-mishka"
JTPROG="${HOME}/Work/github/jtprogru/jtprog.ru"

say() { printf "\n\033[1;36m== %s ==\033[0m\n" "$*"; }

# ---------- 1. hugo-mishka ----------
say "hugo-mishka: cleanup stale sandbox artifacts"
cd "${HUGO_MISHKA}"
find .git -name "*.lock" -print -delete 2>/dev/null || true
find .git/objects -name "tmp_obj_*" -print -delete 2>/dev/null || true

say "hugo-mishka: ensure we're on feature branch"
# sandbox мог успеть переключиться на feature-ветку; страхуемся.
if ! git rev-parse --verify feature/og-image-auto-resize >/dev/null 2>&1; then
    git checkout -b feature/og-image-auto-resize
else
    git checkout feature/og-image-auto-resize
fi

say "hugo-mishka: stage and commit"
git add layouts/_partials/cover_og_image.html \
        layouts/_partials/opengraph.html \
        layouts/_partials/twitter_cards.html
git status --short

git commit -m "feat(og): auto-resize cover image for og:image via Hugo Pipes

Add new returnable partial cover_og_image.html that resolves Params.cover.image
as a Hugo resource (Page Bundle via .Resources.GetMatch, then global assets/
via resources.Get) and runs .Resize \"1200x q85\" when width exceeds 1200px.
Fallback to absURL for covers in static/ or external URLs.

opengraph.html and twitter_cards.html now both consume the same partial, so
the OG image URL is computed once and width/height are propagated as the
actual processed dimensions instead of frontmatter-declared ones.

This prevents Telegram from silently dropping covers that exceed soft pixel
limits and avoids the grayscale+alpha (LA mode) PNG issue. Backwards-
compatible: existing posts with static covers fall through to the previous
absURL behaviour."

say "hugo-mishka: merge feature into main (--no-ff)"
git checkout main
git merge --no-ff feature/og-image-auto-resize -m "Merge branch 'feature/og-image-auto-resize'"
git branch -d feature/og-image-auto-resize

HUGO_MISHKA_NEW_SHA="$(git rev-parse HEAD)"
say "hugo-mishka: main is now at ${HUGO_MISHKA_NEW_SHA}"

# ---------- 2. jtprog.ru — static PNGs ----------
say "jtprog.ru: cleanup stale sandbox locks in submodule"
cd "${JTPROG}"
find .git/modules/themes/mishka -name "*.lock" -print -delete 2>/dev/null || true

say "jtprog.ru: revert sandbox test files in submodule"
(
  cd themes/mishka
  rm -f layouts/_partials/cover_og_image.html
  git checkout -- layouts/_partials/opengraph.html \
                  layouts/_partials/twitter_cards.html
)

say "jtprog.ru: branch for static cover optimization"
git checkout -b feature/optimize-og-static-covers

say "jtprog.ru: stage only static/*.png — НЕ трогаем hugo.yaml и themes/mishka-dev"
git add static/*.png
git status --short

git commit -m "chore(static): optimize cover images for telegram og previews

Convert all category cover PNGs from grayscale+alpha (LA mode) to RGB and
cap longest side at 1200px. Telegram link-preview parser silently drops
LA-mode PNGs and rejects images above its pixel-count soft-limit, so the
old cover assets never produced an og:image preview when articles were
shared.

Most-affected sources:
  - howto.png:                      4657x3784 RGBA, 626 KB → 1200x975  RGB, 148 KB
  - education-theory-and-practice:  2.3 MB RGBA            → 955 KB    PNG-8 (256 colors)
  - 13 other category covers:       LA mode                → RGB, ~120-200 KB

URLs are unchanged; posts referencing /devops.png etc. keep working."

say "jtprog.ru: merge into main (--no-ff)"
git checkout main
git merge --no-ff feature/optimize-og-static-covers -m "Merge branch 'feature/optimize-og-static-covers'"
git branch -d feature/optimize-og-static-covers

# ---------- 3. Bump submodule themes/mishka ----------
say "jtprog.ru: bump submodule themes/mishka via local fetch"
(
  cd themes/mishka
  # local fetch — без необходимости пушить hugo-mishka заранее.
  git fetch "${HUGO_MISHKA}" main
  git checkout main
  git merge --ff-only FETCH_HEAD
  git log --oneline -1
)

say "jtprog.ru: branch + commit submodule pointer bump"
git checkout -b chore/bump-mishka-og-image
git add themes/mishka
git status --short

git commit -m "chore(theme): bump mishka with og:image auto-resize partial

Pulls feat(og): auto-resize cover image for og:image via Hugo Pipes from
hugo-mishka main."

git checkout main
git merge --ff-only chore/bump-mishka-og-image
git branch -d chore/bump-mishka-og-image

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

После деплоя — прогони @WebpageBot по нескольким ссылкам, например:
  https://jtprog.ru/slo-as-architecture-blueprint/
  https://jtprog.ru/how-read-qr-code/
  https://jtprog.ru/burn-rate-is-not-speed/
EOF
