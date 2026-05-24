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
VARIANTS = (
    ("",      "default"),   # suffix, mermaid theme
    (".dark", "dark"),
)


def hash_block(code: str) -> str:
    return hashlib.sha256(code.encode("utf-8")).hexdigest()


def render_block(code: str, out_path: pathlib.Path, mermaid_theme: str) -> None:
    with tempfile.NamedTemporaryFile(
        "w", suffix=".mmd", delete=False, encoding="utf-8"
    ) as tmp:
        tmp.write(code)
        tmp_path = tmp.name
    try:
        subprocess.run(
            [*MMDC, "-i", tmp_path, "-o", str(out_path),
             *MMDC_COMMON, "--theme", mermaid_theme],
            check=True,
        )
    finally:
        os.unlink(tmp_path)


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    rendered = skipped = 0
    for md in sorted(CONTENT_DIR.rglob("*.md")):
        text = md.read_text(encoding="utf-8")
        for block in MERMAID_RE.findall(text):
            code = block.strip()
            h = hash_block(code)
            rel_md = md.relative_to(REPO_ROOT)
            for suffix, mermaid_theme in VARIANTS:
                out = OUT_DIR / f"{h}{suffix}.svg"
                label = mermaid_theme
                if out.exists():
                    print(f"  · {rel_md}: {h[:8]} [{label}]  (cached)")
                    skipped += 1
                    continue
                print(f"  → {rel_md}: {h[:8]} [{label}]  (rendering...)")
                render_block(code, out, mermaid_theme)
                rendered += 1
    print(f"\nDone. rendered={rendered}, cached={skipped}, total={rendered + skipped}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
