#!/usr/bin/env node
/**
 * math-prerender.mjs — пререндер LaTeX-формул из content/**\/*.md в PNG.
 *
 * Зачем: KaTeX рисует формулы в браузере, а Telegram Instant View никакого
 * JS не исполняет — в IV уезжал сырой TeX вида `$$\frac{a}{b}$$`. IV-формат
 * не понимает ни MathML, ни KaTeX-разметку, поэтому единственный способ
 * донести формулу до читателя — растр.
 *
 * Тот же приём уже работает для mermaid и векторных обложек: рядом с
 * оригиналом лежит PNG, а тема кладёт его абсолютный URL в data-png.
 * Render hook `_markup/render-passthrough.html` считает ровно такой же хеш
 * и подцепляет файл из assets/math/.
 *
 * Формат намеренно PNG, а не GIF: GIF в Instant View конвертируется в тип
 * Video и показывается плеером — для формулы это абсурд.
 *
 * Хеш = sha256("<type>|<tex>"), где type = block|inline, а tex — тело
 * формулы без делимитеров, ровно как его отдаёт Hugo в `.Inner`.
 *
 * Все PNG рисуются в 2× (deviceScaleFactor), тема делит размеры пополам,
 * когда отдаёт width/height для инлайновых формул.
 *
 * Запуск: npm ci && node scripts/math-prerender.mjs [--check] [--prune]
 */

import { createHash } from 'node:crypto';
import { createRequire } from 'node:module';
import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const CONTENT_DIR = path.join(ROOT, 'content');
const OUT_DIR = path.join(ROOT, 'assets', 'math');

// Цвета — catppuccin latte, как у mermaid-пререндера: светлая картинка
// одинаково читается и в светлой, и в тёмной теме Telegram.
const BG = '#eff1f5';
const FG = '#4c4f69';
const SCALE = 2;

const CHECK = process.argv.includes('--check');
const PRUNE = process.argv.includes('--prune');

/** Делимитеры passthrough из hugo.yaml. `$...$` намеренно нет: одиночный
 *  доллар в прозе («$48 в год») ловился как формула. */
const PATTERNS = [
  { type: 'block', re: /\$\$([\s\S]+?)\$\$/g },
  { type: 'block', re: /\\\[([\s\S]+?)\\\]/g },
  { type: 'inline', re: /\\\(([\s\S]+?)\\\)/g },
];

const hashOf = (type, tex) =>
  createHash('sha256').update(`${type}|${tex}`, 'utf8').digest('hex');

/** Вырезает fenced- и inline-код, сохраняя длину строки: внутри ``` формула
 *  формулой не является. */
function stripCode(src) {
  return src.replace(/```[\s\S]*?```|`[^`\n]+`/g, (m) => ' '.repeat(m.length));
}

async function* walk(dir) {
  for (const entry of await fs.readdir(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) yield* walk(full);
    else if (entry.isFile() && entry.name.endsWith('.md')) yield full;
  }
}

async function collect() {
  const found = new Map();
  for await (const file of walk(CONTENT_DIR)) {
    const body = stripCode(await fs.readFile(file, 'utf8'));
    for (const { type, re } of PATTERNS) {
      for (const m of body.matchAll(re)) {
        const tex = m[1];
        const hash = hashOf(type, tex);
        if (!found.has(hash)) {
          found.set(hash, { type, tex, file: path.relative(ROOT, file) });
        }
      }
    }
  }
  return found;
}

function pageHtml(katexCss) {
  return `<!doctype html><html><head><meta charset="utf-8">
<style>${katexCss}</style>
<style>
  html, body { margin: 0; padding: 0; background: ${BG}; color: ${FG}; }
  body { font-family: "IBM Plex Sans", system-ui, -apple-system, sans-serif; }
  #stage { display: inline-block; background: ${BG}; }
  #stage.block  { padding: 14px 18px; font-size: 22px; }
  #stage.inline { padding: 2px 3px; font-size: 19px; }
  .katex { color: ${FG}; }
  .katex-display { margin: 0; }
</style></head><body><div id="stage"></div></body></html>`;
}

async function main() {
  const formulas = await collect();
  await fs.mkdir(OUT_DIR, { recursive: true });

  const existing = new Set(
    (await fs.readdir(OUT_DIR).catch(() => [])).filter((f) => f.endsWith('.png')),
  );

  const missing = [...formulas].filter(([hash]) => !existing.has(`${hash}.png`));

  if (CHECK) {
    if (missing.length) {
      console.error(`Нет пререндера для ${missing.length} формул:`);
      for (const [hash, f] of missing) {
        console.error(`  ${f.file}: ${hash}.png — ${f.tex.trim().slice(0, 60)}`);
      }
      console.error('\nЗапусти: make math-render');
      process.exit(1);
    }
    console.log(`math-check: ок, все ${formulas.size} формул пререндерены`);
    return;
  }

  if (missing.length) {
    const katexCss = await fs.readFile(
      require.resolve('katex/dist/katex.min.css'),
      'utf8',
    );
    const katex = require('katex');
    const puppeteer = (await import('puppeteer')).default;

    const browser = await puppeteer.launch({
      headless: true,
      args: ['--no-sandbox', '--font-render-hinting=none'],
    });
    try {
      const page = await browser.newPage();
      await page.setViewport({ width: 1400, height: 400, deviceScaleFactor: SCALE });
      await page.setContent(pageHtml(katexCss), { waitUntil: 'load' });
      await page.evaluateHandle('document.fonts.ready');

      for (const [hash, { type, tex, file }] of missing) {
        const html = katex.renderToString(tex.trim(), {
          displayMode: type === 'block',
          throwOnError: false,
          output: 'html',
        });
        await page.evaluate(
          (h, cls) => {
            const stage = document.getElementById('stage');
            stage.className = cls;
            stage.innerHTML = h;
          },
          html,
          type,
        );
        await page.evaluateHandle('document.fonts.ready');
        const el = await page.$('#stage');
        await el.screenshot({
          path: path.join(OUT_DIR, `${hash}.png`),
          omitBackground: false,
        });
        console.log(`  ${type.padEnd(6)} ${hash.slice(0, 12)}  ${file}`);
      }
    } finally {
      await browser.close();
    }
  }

  const wanted = new Set([...formulas.keys()].map((h) => `${h}.png`));
  const orphans = [...existing].filter((f) => !wanted.has(f));
  if (orphans.length) {
    if (PRUNE) {
      for (const f of orphans) await fs.unlink(path.join(OUT_DIR, f));
      console.log(`Удалено осиротевших PNG: ${orphans.length}`);
    } else {
      console.log(
        `Осиротевших PNG: ${orphans.length} (удалить: make math-prune)`,
      );
    }
  }

  console.log(
    `Формул: ${formulas.size}, отрисовано: ${missing.length}, готово в assets/math/`,
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
