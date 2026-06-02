#!/usr/bin/env bash
# indexnow.sh
#
# Готовит для IndexNow (Bing, Yandex, Seznam, Naver и др. участники протокола;
# Google в IndexNow НЕ входит) список страниц, реально изменившихся в пуше.
# Сам POST делает action jtprogru/indexnow в следующем шаге workflow.
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
#   4. Пишет уникальный список в файл и публикует через $GITHUB_OUTPUT
#      переменные `count` и `urls-file` — следующий шаг отдаёт файл в action.
set -euo pipefail

BASE="https://jtprog.ru"

KEY="${INDEXNOW_KEY:-}"
if [ -n "$KEY" ] && [ ! -f "static/$KEY.txt" ]; then
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

urls_file="${RUNNER_TEMP:-/tmp}/indexnow-urls.txt"

git diff --name-only "$BEFORE" "$AFTER" -- content/ | while IFS= read -r f; do
  [ -n "$f" ] || continue
  url="$(resolve_url "$f")"
  [ -n "$url" ] && printf '%s\n' "$url"
done | sort -u > "$urls_file"

count="$(wc -l < "$urls_file" | tr -d '[:space:]')"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  printf 'count=%s\n' "$count" >> "$GITHUB_OUTPUT"
  printf 'urls-file=%s\n' "$urls_file" >> "$GITHUB_OUTPUT"
fi

if [ "$count" -eq 0 ]; then
  echo "IndexNow: no changed pages in content/, nothing to submit"
  exit 0
fi

echo "IndexNow: $count URL(s) ready for submit:"
sed 's/^/  /' "$urls_file"
