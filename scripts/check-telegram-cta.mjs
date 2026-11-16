// Run against a built site or hugo server with a post containing telegram-cta:
// node scripts/check-telegram-cta.mjs http://127.0.0.1:1313/posts/yandex-scale-2026/
import assert from 'node:assert/strict';
import puppeteer from 'puppeteer';

const url = process.argv[2] ?? 'http://127.0.0.1:1313/posts/yandex-scale-2026/';
const selector = '.md-content .telegram-cta__link';
const browser = await puppeteer.launch(
  process.env.PUPPETEER_EXECUTABLE_PATH
    ? { executablePath: process.env.PUPPETEER_EXECUTABLE_PATH }
    : { channel: 'chrome' },
);

function luminance(rgb) {
  const channels = rgb.slice(0, 3).map(value => {
    const s = value / 255;
    return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
  });
  return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722;
}

function contrast(foreground, background) {
  const values = [foreground, background].map(color => {
    assert.match(color, /^rgb\(/, `Expected opaque RGB, got ${color}`);
    return luminance(color.match(/[\d.]+/g).map(Number));
  }).sort((a, b) => b - a);
  return (values[0] + 0.05) / (values[1] + 0.05);
}

try {
  const page = await browser.newPage();
  await page.emulateMediaFeatures([{ name: 'prefers-reduced-motion', value: 'reduce' }]);
  await page.goto(url, { waitUntil: 'networkidle0' });
  await page.waitForSelector(selector);
  // Measure settled colors, not intermediate theme-switch transitions.
  await page.addStyleTag({
    content: '*, *::before, *::after { transition: none !important; animation: none !important; }',
  });
  const failures = [];

  for (const width of [1280, 390]) {
    await page.setViewport({ width, height: 900 });
    for (const theme of ['light', 'dark']) {
      await page.evaluate(value => {
        document.documentElement.dataset.theme = value;
        document.documentElement.dataset.themePref = value;
      }, theme);
      for (const state of ['default', 'hover', 'focus']) {
        await page.mouse.move(0, 0);
        await page.$eval(selector, element => element.blur());
        if (state === 'hover') await page.hover(selector);
        if (state === 'focus') {
          await page.keyboard.press('Tab');
          await page.focus(selector);
        }
        const result = await page.$eval(selector, element => {
          const style = getComputedStyle(element);
          const rect = element.getBoundingClientRect();
          return {
            foreground: style.color,
            background: style.backgroundColor,
            decoration: style.textDecorationLine,
            iconColor: getComputedStyle(element.querySelector('svg')).color,
            focused: element.matches(':focus-visible'),
            outlineStyle: style.outlineStyle,
            outlineWidth: parseFloat(style.outlineWidth),
            fits: rect.width > 0 && rect.left >= 0 && rect.right <= innerWidth,
          };
        });
        const ratio = contrast(result.foreground, result.background);
        const label = `${width}px ${theme} ${state}`;
        const checks = [
          [ratio >= 4.5, `text contrast ${ratio.toFixed(2)}:1 < 4.5:1`],
          [result.decoration === 'none', 'prose underline leaks into button'],
          [result.iconColor === result.foreground, 'arrow does not inherit text color'],
          [result.fits, 'button overflows viewport'],
          [state !== 'focus' || (result.focused && result.outlineStyle !== 'none'
            && result.outlineWidth >= 2), 'keyboard focus ring missing'],
        ];
        const errors = checks.filter(([passed]) => !passed).map(([, error]) => error);
        console.log(`${errors.length ? 'FAIL' : 'PASS'} ${label}: ${ratio.toFixed(2)}:1`);
        failures.push(...errors.map(error => `${label}: ${error}`));
      }
    }
  }
  assert.equal(failures.length, 0, failures.join('\n'));
} finally {
  await browser.close();
}
