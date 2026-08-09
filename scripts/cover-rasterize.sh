#!/usr/bin/env bash
#
# cover-rasterize.sh — растеризует SVG-обложки постов в PNG рядом с оригиналом.
#
# Зачем: SVG нельзя отдавать в og:image. Ни один соцсеть-парсер его не
# рендерит — ни Facebook, ни Twitter, ни Telegram, ни VK. Пост с векторной
# обложкой шарится вообще без превью, при том что twitter:card заявлен как
# summary_large_image и резервирует место под картинку.
#
# Партиал темы cover_og_image.html ищет растрового соседа с тем же именем
# (cover.svg → cover.png) и отдаёт в OG именно его. Оригинальный SVG
# продолжает использоваться на самой странице — он легче и чётче.
#
# Ширина 2100 — это 2× от viewBox обложек (1050×480), как у уже лежащего в
# репозитории what-happens-when-you-open-website/cover.png. Отдавать такой
# файл в OG напрямую не надо: Hugo сам ужмёт его до 1200px в
# cover_og_image.html, а исходник в 2× остаётся годным для retina.
#
# Идемпотентный и неразрушающий: PNG перерисовывается только если SVG новее,
# и никогда — если существующий PNG крупнее того, что мы бы отрисовали.
#
# Требует rsvg-convert (brew install librsvg).

set -euo pipefail

WIDTH="${COVER_WIDTH:-2100}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v rsvg-convert >/dev/null 2>&1; then
    echo "rsvg-convert не найден. Установи: brew install librsvg" >&2
    exit 1
fi

shopt -s nullglob

converted=0
skipped=0

for svg in "$ROOT"/content/posts/*/cover.svg "$ROOT"/assets/covers/*.svg; do
    png="${svg%.svg}.png"

    if [[ -f "$png" && "$png" -nt "$svg" ]]; then
        skipped=$((skipped + 1))
        continue
    fi

    # Не понижать разрешение уже существующей обложки: её могли отрисовать
    # вручную или в большем масштабе.
    if [[ -f "$png" ]]; then
        existing_w=$(python3 -c "import struct,sys; print(struct.unpack('>I', open(sys.argv[1],'rb').read(20)[16:20])[0])" "$png")
        if ((existing_w >= WIDTH)); then
            echo "  пропуск ${svg#"$ROOT"/}: существующий PNG шире (${existing_w}px)"
            skipped=$((skipped + 1))
            continue
        fi
    fi

    rsvg-convert --width="$WIDTH" --keep-aspect-ratio --format=png \
        --output="$png" "$svg"

    echo "  ${svg#"$ROOT"/} → ${png##*/}"
    converted=$((converted + 1))
done

echo "Обложек перерисовано: $converted, актуальных пропущено: $skipped"
