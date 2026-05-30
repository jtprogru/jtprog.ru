#!/usr/bin/env bash
# indexnow-full.sh
#
# Разовый сабмит ВСЕХ URL сайта в IndexNow (в отличие от indexnow.sh,
# который шлёт только дельту по git diff). Источник правды — sitemap.xml:
# тянем корневой /sitemap.xml, разворачиваем sitemap-index (если он такой),
# дедуплицируем и шлём одним POST'ом.
#
# Когда это вообще уместно:
#   - после миграции домена / массового пересоздания URL;
#   - после крупного рефактора permalinks;
#   - первый «прогрев» нового индекса (Bing/Yandex/Seznam/Naver).
# В обычной жизни — НЕ запускать: IndexNow рассчитан на дельты, регулярные
# «полные» сабмиты участники протокола вправе игнорировать.
#
# Ключ берётся из env INDEXNOW_KEY (как в indexnow.sh) и публикуется
# по https://jtprog.ru/<KEY>.txt (static/<KEY>.txt в репо).
set -euo pipefail

BASE="https://jtprog.ru"
HOST="jtprog.ru"
SITEMAP="${SITEMAP_URL:-$BASE/sitemap.xml}"
ENDPOINT="${INDEXNOW_ENDPOINT:-https://api.indexnow.org/indexnow}"

KEY="${INDEXNOW_KEY:-}"
if [ -z "$KEY" ]; then
  echo "ERROR: INDEXNOW_KEY is empty" >&2
  exit 1
fi
KEYLOC="$BASE/$KEY.txt"

if [ ! -f "static/$KEY.txt" ]; then
  echo "::warning::static/$KEY.txt is missing — IndexNow key verification will fail"
fi

# Достаёт <loc>...</loc> из stdin (sitemap или sitemap-index)
extract_locs() {
  grep -oE '<loc>[^<]+</loc>' | sed -E 's|</?loc>||g'
}

urls_file="$(mktemp)"
trap 'rm -f "$urls_file"' EXIT

echo "Fetching $SITEMAP ..."
curl -fsSL "$SITEMAP" | extract_locs | while IFS= read -r loc; do
  [ -n "$loc" ] || continue
  case "$loc" in
    *sitemap*.xml)
      # вложенный sitemap из sitemap-index — разворачиваем
      curl -fsSL "$loc" | extract_locs
      ;;
    *)
      printf '%s\n' "$loc"
      ;;
  esac
done | sort -u > "$urls_file"

count="$(wc -l < "$urls_file" | tr -d '[:space:]')"
if [ "$count" -eq 0 ]; then
  echo "ERROR: no URLs extracted from sitemap" >&2
  exit 1
fi

# IndexNow limit — 10000 URL за один запрос. Если когда-нибудь упрёмся —
# здесь нужно будет резать на батчи; пока сайт сильно меньше, шлём одним.
if [ "$count" -gt 10000 ]; then
  echo "ERROR: $count URLs exceeds IndexNow per-request limit (10000)" >&2
  exit 1
fi

echo "IndexNow: submitting $count URL(s) from sitemap"

payload="$(jq -R . "$urls_file" | jq -s \
  --arg host "$HOST" --arg key "$KEY" --arg kl "$KEYLOC" \
  '{host: $host, key: $key, keyLocation: $kl, urlList: .}')"

code="$(curl -sS -o /tmp/indexnow_full_resp.txt -w '%{http_code}' \
  -X POST "$ENDPOINT" \
  -H 'Content-Type: application/json; charset=utf-8' \
  --data-binary "$payload" || echo "000")"

if [ "$code" = "200" ] || [ "$code" = "202" ]; then
  echo "IndexNow: OK (HTTP $code)"
  exit 0
else
  echo "ERROR: IndexNow submit returned HTTP $code" >&2
  cat /tmp/indexnow_full_resp.txt 2>/dev/null >&2 || true
  echo >&2
  exit 1
fi
