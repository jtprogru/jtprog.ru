#!/usr/bin/env bash
# Финальные шаги миграции jtprog.ru с PaperMod на mishka.
# Запускать из корня репозитория, после того как Claude:
#   - переписал .gitmodules (оставив только запись themes/mishka)
#   - hugo.yaml уже с theme: mishka
#   - Taskfile.yml обновлён
#   - layouts/*.html (оверрайды PaperMod) удалены
#   - создана feature-ветка chore/migrate-to-mishka-theme
#
# В .git/ остался мусор от sandbox (lock-файлы и .broken-папки) — шаг 0 их подчищает.
set -euo pipefail

cd "$(dirname "$0")/.."

# === 0. Cleanup мусора, оставленного Claude в sandbox ===
echo "==> [0/6] Чистка stale lock-файлов и broken-копий..."
find .git -name "*.lock.*" -delete 2>/dev/null || true
find .git -name "*.lock"   -delete 2>/dev/null || true
find .git -name "test_write" -delete 2>/dev/null || true
find .git -name "tmp_obj_*" -delete 2>/dev/null || true
find .git -name "tUGtFa8"  -delete 2>/dev/null || true
rm -rf .git/modules/themes/mishka.broken 2>/dev/null || true
rm -rf themes/mishka.broken 2>/dev/null || true

# === 1. Sanity-check ===
echo "==> [1/6] Sanity-check..."
BRANCH=$(git branch --show-current)
if [[ "$BRANCH" != "chore/migrate-to-mishka-theme" ]]; then
  echo "ОЖИДАЕМАЯ ВЕТКА: chore/migrate-to-mishka-theme, А ТЕКУЩАЯ: $BRANCH" >&2
  echo "Скрипт не продолжит. Переключись на нужную ветку." >&2
  exit 1
fi
echo "    Ветка: $BRANCH"
echo "    .gitmodules:"
cat .gitmodules | sed 's/^/      /'

# === 2. Полностью убрать PaperMod ===
echo "==> [2/6] Удаляю PaperMod..."
git submodule deinit -f themes/PaperMod 2>/dev/null || true
rm -rf themes/PaperMod
rm -rf .git/modules/themes/PaperMod
# .gitmodules уже не содержит PaperMod; убрать его из index:
git rm --cached -f --ignore-unmatch themes/PaperMod || true

# === 3. Подключить mishka как submodule ===
echo "==> [3/6] Подключаю themes/mishka..."
# Если что-то от сломанного clone осталось — почистим
rm -rf themes/mishka 2>/dev/null || true
rm -rf .git/modules/themes/mishka 2>/dev/null || true
git submodule add -b main --force https://github.com/jtprogru/hugo-mishka.git themes/mishka
git submodule update --init --recursive themes/mishka
( cd themes/mishka && git log -1 --oneline )

# === 4. Сборка ===
echo "==> [4/6] Прогоняю hugo --gc --minify..."
hugo --gc --minify

# === 5. Коммит ===
echo "==> [5/6] Стейджу и коммичу..."
git add -A
git status
git commit -m "chore(theme): migrate from PaperMod to mishka

- Removed submodule themes/PaperMod and local layout overrides in layouts/
- Added submodule themes/mishka (jtprogru/hugo-mishka, branch main)
- hugo.yaml: theme switched to mishka
- Taskfile.yml: minor tweaks (HOST formatting, drop duplicate --enableGitInfo)"

# === 6. Merge в main и cleanup ===
echo "==> [6/6] Готово к merge. Выполни вручную (см. Taskfile или ниже):"
cat <<'EOF'

  git checkout main
  git pull origin main
  git merge --no-ff chore/migrate-to-mishka-theme
  git push origin main
  git branch -d chore/migrate-to-mishka-theme

Если предпочитаешь PR — `git push origin chore/migrate-to-mishka-theme && gh pr create --base main --fill`.
EOF
