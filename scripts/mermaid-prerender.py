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
SCRIPTS_DIR = pathlib.Path(__file__).resolve().parent

# Каждой mermaid-диаграмме генерим две версии — под light и dark CSS-темы
# сайта. Render hook темы mishka вставляет обе и переключает видимость
# через `:root[data-theme="..."]`. Имена: <hash>.svg (light), <hash>.dark.svg.
#
# Цветовая палитра задаётся через mermaid-config.{light,dark}.json — там
# themeVariables, согласованные с CSS-переменными темы сайта (см.
# themes/mishka/assets/css/modules/00-vars.css). Чтобы избежать тёмных
# блоков и плохого контраста, используем mermaid theme=base и переопределяем
# все основные переменные вручную.
VARIANTS = (
    ("",      SCRIPTS_DIR / "mermaid-config.light.json"),
    (".dark", SCRIPTS_DIR / "mermaid-config.dark.json"),
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
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    force = "--force" in sys.argv
    rendered = skipped = 0
    for md in sorted(CONTENT_DIR.rglob("*.md")):
        text = md.read_text(encoding="utf-8")
        for block in MERMAID_RE.findall(text):
            code = block.strip()
            h = hash_block(code)
            rel_md = md.relative_to(REPO_ROOT)
            for suffix, config_file in VARIANTS:
                out = OUT_DIR / f"{h}{suffix}.svg"
                label = "dark" if suffix else "light"
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
    print(f"\nDone. rendered={rendered}, cached={skipped}, total={rendered + skipped}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
