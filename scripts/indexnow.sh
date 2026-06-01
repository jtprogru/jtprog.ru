#!/usr/bin/env bash
# indexnow.sh
#
# Шлёт в IndexNow (Bing, Yandex, Seznam, Naver и др. участники протокола;
# Google в IndexNow НЕ входит) список страниц, реально изменившихся в пуше.
#
# Как работает:
#   1. Берёт диапазон коммитов BEFORE..AFTER (из env, по умолчанию HEAD~1..HEAD).
#   2. git diff --name-only по content/ → изменённые файлы.
#   3. Маппит каждый файл в канонический URL по схеме сайта:
#        content/posts/<dir>/...   → /posts/<slug|dir>/   (любой файл бандла,
#                                     включая обложки → URL самого поста)
#        content/posts/_index.md   → /posts/
#        content/<name>.md         → /<slug|name>/
#      slug читается из YAML-frontmatter (90/143 поста его переопределяют);
#      схема сверена с `hugo list all` на всех страницах сайта.
#   4. Передаёт уникальный список в `indexnow submit --stdin` (CLI
#      https://github.com/jtprogru/indexnow), который и делает POST.
#
# Ключ IndexNow публичен по дизайну: лежит в static/<KEY>.txt и отдаётся
# с https://jtprog.ru/<KEY>.txt. Значение передаётся через env INDEXNOW_KEY.
#
# Шаг неблокирующий: CLI запускается с `--fail-on never`, плюс сам вызов
# обёрнут в `|| true`, чтобы не ронять статус деплоя (нотификации post-deploy
# — fire-and-forget).
set -euo pipefail

BASE="https://jtprog.ru"
HOST="jtprog.ru"
ENDPOINT="${INDEXNOW_ENDPOINT:-https://api.indexnow.org/indexnow}"

KEY="${INDEXNOW_KEY:-}"
if [ -z "$KEY" ]; then
  echo "::warning::INDEXNOW_KEY is empty, skipping IndexNow submit"
  exit 0
fi
KEYLOC="$BASE/$KEY.txt"

if [ ! -f "static/$KEY.txt" ]; then
  echo "::warning::static/$KEY.txt is missing — IndexNow key verification will fail"
fi

AFTER="${AFTER:-HEAD}"
BEFORE="${BEFORE:-}"
ZERO="0000000000000000000000000000000000000000"
if [ -z "$BEFORE" ] || [ "$BEFORE" = "$ZERO" ] || ! git cat-file -e "${BEFORE}^{commit}" 2>/dev/null; then
  if git cat-file -e "${AFTER}~1^{commit}" 2>/dev/null; then
    BEFORE="${AFTER}~1"
  else
    BEFORE="$(git hash-object -t tree /dev/null)" # empty tree → diff = all files
  fi
fi

# slug из первого ---...--- YAML-блока файла (с тримом кавычек/пробелов/слэшей)
fm_slug() {
  awk '
    NR==1 && /^---[[:space:]]*$/ { inblock=1; next }
    inblock && /^---[[:space:]]*$/ { exit }
    inblock && /^slug:[[:space:]]*/ {
      sub(/^slug:[[:space:]]*/, "")
      gsub(/^["'"'"']+|["'"'"']+$/, "")
      gsub(/[[:space:]]+$/, "")
      gsub(/^\/+|\/+$/, "")
      print
      exit
    }
  ' "$1"
}

# content-путь → канонический URL ("" если страница не резолвится / удалена)
resolve_url() {
  local f="$1" dir name slug index
  case "$f" in
    content/posts/_index.md)
      echo "$BASE/posts/"
      ;;
    content/posts/*/*)
      dir="${f#content/posts/}"; dir="${dir%%/*}"
      index="content/posts/$dir/index.md"
      [ -f "$index" ] || return 0   # бандл удалён — не сабмитим
      slug="$(fm_slug "$index")"
      echo "$BASE/posts/${slug:-$dir}/"
      ;;
    content/*.md)
      name="$(basename "$f" .md)"
      [ "$name" = "_index" ] && { echo "$BASE/"; return 0; }
      [ -f "$f" ] || return 0       # страница удалена — не сабмитим
      slug="$(fm_slug "$f")"
      echo "$BASE/${slug:-$name}/"
      ;;
    *) : ;;
  esac
}

urls_file="$(mktemp)"
trap 'rm -f "$urls_file"' EXIT

git diff --name-only "$BEFORE" "$AFTER" -- content/ | while IFS= read -r f; do
  [ -n "$f" ] || continue
  url="$(resolve_url "$f")"
  [ -n "$url" ] && printf '%s\n' "$url"
done | sort -u > "$urls_file"

count="$(wc -l < "$urls_file" | tr -d '[:space:]')"
if [ "$count" -eq 0 ]; then
  echo "IndexNow: no changed pages in content/, nothing to submit"
  exit 0
fi

echo "IndexNow: submitting $count URL(s):"
sed 's/^/  /' "$urls_file"

if ! command -v indexnow >/dev/null 2>&1; then
  echo "::warning::indexnow CLI not found in PATH — skipping submit"
  exit 0
fi

indexnow submit --stdin \
  --host "$HOST" \
  --key "$KEY" \
  --key-location "$KEYLOC" \
  --endpoint "$ENDPOINT" \
  --fail-on never \
  < "$urls_file" || echo "::warning::indexnow submit exited non-zero"

exit 0
