#!/usr/bin/env python3
"""
mermaid-prerender — оффлайн-генератор SVG для mermaid-блоков в постах.

Зачем: чтобы не таскать ~330 KB mermaid.esm с jsdelivr на клиенте.
Render hook темы mishka (layouts/_default/_markup/render-codeblock-mermaid.html)
ищет SVG по sha256(code) в assets/mermaid/<hash>.svg и встраивает его inline,
если найден. Если нет — fallback на runtime mermaid bundle.

Запуск (вручную или через `task mermaid:render`):

    python3 scripts/mermaid-prerender.py

Скрипт:
  • Обходит content/**/*.md
  • Для каждого mermaid-блока считает sha256 от trimmed-кода
  • Если assets/mermaid/<hash>.svg уже есть — skip
  • Иначе вызывает mmdc (через npx) и сохраняет SVG

Зависимости (ставятся автоматически через npx):
  • Node.js (>= 18)
  • @mermaid-js/mermaid-cli — тянется первый раз через npx, кэшируется
"""

import hashlib
import os
import pathlib
import re
import subprocess
import sys
import tempfile

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT_DIR = REPO_ROOT / "content"
OUT_DIR = REPO_ROOT / "assets" / "mermaid"

MERMAID_RE = re.compile(r"```mermaid\n(.*?)\n```", re.DOTALL)

MMDC = [
    "npx", "-y",
    "-p", "@mermaid-js/mermaid-cli",
    "mmdc",
]
MMDC_COMMON = ["--quiet", "--backgroundColor", "transparent"]

# Каждой mermaid-диаграмме генерим две версии — под light и dark CSS-темы
# сайта. Render hook темы mishka вставляет обе и переключает видимость
# через `:root[data-theme="..."]`. Имена: <hash>.svg (light), <hash>.dark.svg.
#
# Палитра берётся из темы, а не из локальной копии. Раньше рядом лежали свои
# scripts/mermaid-config.{light,dark}.json, и это была вторая независимая
# палитра: она отстала от BRANDING 0.2 и рисовала схемы тёплыми, пока сайт
# уже был в catppuccin. Конфиги темы генерятся из тех же токенов, что и CSS
# (mishka-ds/scripts/gen-mermaid-theme.mjs), поэтому пререндер и runtime-
# фолбэк дают одинаковые цвета по построению.
THEME_MERMAID_DIR = REPO_ROOT / "themes" / "mishka" / "assets" / "mermaid"
VARIANTS = (
    ("",      THEME_MERMAID_DIR / "mermaid-config.json"),
    (".dark", THEME_MERMAID_DIR / "mermaid-config.dark.json"),
)


def hash_block(code: str) -> str:
    return hashlib.sha256(code.encode("utf-8")).hexdigest()


def render_block(
    code: str, out_path: pathlib.Path, config_file: pathlib.Path, svg_id: str
) -> None:
    with tempfile.NamedTemporaryFile(
        "w", suffix=".mmd", delete=False, encoding="utf-8"
    ) as tmp:
        tmp.write(code)
        tmp_path = tmp.name
    try:
        subprocess.run(
            [*MMDC, "-i", tmp_path, "-o", str(out_path),
             *MMDC_COMMON, "--configFile", str(config_file),
             "--svgId", svg_id],
            check=True,
        )
    finally:
        os.unlink(tmp_path)


def main() -> int:
    for _, config_file in VARIANTS:
        if not config_file.exists():
            print(
                f"нет конфига {config_file.relative_to(REPO_ROOT)} — "
                "подтяни сабмодуль темы: make update-theme",
                file=sys.stderr,
            )
            return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    force = "--force" in sys.argv
    # --check ничего не рисует и не требует npx: только проверяет, что каждому
    # блоку в контенте соответствует пара SVG. Для CI.
    check = "--check" in sys.argv
    rendered = skipped = missing = 0
    for md in sorted(CONTENT_DIR.rglob("*.md")):
        text = md.read_text(encoding="utf-8")
        for block in MERMAID_RE.findall(text):
            code = block.strip()
            h = hash_block(code)
            rel_md = md.relative_to(REPO_ROOT)
            for suffix, config_file in VARIANTS:
                out = OUT_DIR / f"{h}{suffix}.svg"
                label = "dark" if suffix else "light"
                if check:
                    if out.exists():
                        skipped += 1
                    else:
                        missing += 1
                        print(f"  ✗ {rel_md}: {h[:8]} [{label}] — нет {out.name}")
                    continue
                # Unique svg id avoids CSS cascade conflicts when both light
                # and dark SVGs are inlined on the same page. Without this,
                # mmdc emits id="my-svg" for every file, and the second
                # <style> block (#my-svg .node rect{...}) overrides the
                # first — so on a light page you'd see dark colors.
                svg_id = f"m-{h[:12]}-{label}"
                if out.exists() and not force:
                    print(f"  · {rel_md}: {h[:8]} [{label}]  (cached)")
                    skipped += 1
                    continue
                tag = "re-rendering" if out.exists() else "rendering"
                print(f"  → {rel_md}: {h[:8]} [{label}]  ({tag}...)")
                render_block(code, out, config_file, svg_id)
                rendered += 1
    if check:
        if missing:
            print(
                f"\nНе хватает {missing} SVG. Прогони: make mermaid-render",
                file=sys.stderr,
            )
            return 1
        print(f"\nOK. Все {skipped} SVG на месте.")
        return 0
    print(f"\nDone. rendered={rendered}, cached={skipped}, total={rendered + skipped}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
