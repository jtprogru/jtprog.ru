# [jtprog.ru](https://jtprog.ru)

[![CI](https://github.com/jtprogru/jtprog.ru/actions/workflows/main.yaml/badge.svg)](https://github.com/jtprogru/jtprog.ru/actions/workflows/main.yaml)
[![License: MIT](https://img.shields.io/github/license/jtprogru/jtprog.ru)](LICENSE)
[![Content: CC BY-NC-ND 4.0](https://img.shields.io/badge/content-CC%20BY--NC--ND%204.0-lightgrey)](LICENSE-CONTENT.md)
![GitHub issues](https://img.shields.io/github/issues/jtprogru/jtprog.ru)

Личный блог про SRE, DevOps и системное администрирование — [jtprog.ru](https://jtprog.ru).

## Стек

- **[Hugo](https://gohugo.io/)** (Extended, версия из CI: см. `.github/workflows/main.yaml`).
- **Тема [`hugo-mishka`](https://github.com/jtprogru/hugo-mishka)** — собственная, подключена submodule'ом в `themes/mishka`.
- **GitHub Actions** + [`jtprogru/hugo-rsync-deployment`](https://github.com/jtprogru/hugo-rsync-deployment) — сборка и `rsync` на VPS.
- Контент — markdown в `content/`, обложки — `assets/covers/`, метаданные проектов — `data/projects.yaml`.

## Структура

```txt
.
├── content/          # посты + одиночные страницы (about-me, archives, search, projects, donations, chat-rules, privacy-policy)
├── data/             # projects.yaml — источник для блока проектов и /projects/
├── assets/           # обложки и прочее, что должен пайплайнить Hugo
├── static/           # «как есть» — favicon, manifest, robots
├── layouts/          # override'ы поверх темы (если нужны)
├── archetypes/       # шаблоны фронтматтера для `hugo new`
├── scripts/          # хелперы: lastmod, типографика, mermaid-prerender, IndexNow
├── themes/mishka/    # submodule на hugo-mishka
└── hugo.yaml         # единый конфиг сайта
```

## Локальная разработка

```sh
# зависимости
brew install hugo                            # macOS
# (gohugo.io/installation для Linux/Windows)
git submodule update --init --recursive      # подтянуть тему

# dev-сервер с drafts/future/expired
hugo server -D -E -F

# одноразовый билд
hugo --gc --minify

# make-обёртки (см. Makefile)
make help
```

> Тема дев-клонируется через symlink `themes/mishka-dev → ~/Work/.../hugo-mishka` и подключается флагом `hugo --theme mishka-dev`. Прод использует pinned-submodule `themes/mishka`.

## Новый пост

```sh
hugo new content/posts/<slug>/index.md
# или через make-обёртку:
make new SLUG=<slug>
```

Архетип лежит в `archetypes/posts.md`. Cover-картинка — рядом с `index.md` (page bundle) **или** в `assets/covers/<slug>.{jpg,png,webp}` (общий).

Для одиночной страницы (about-me, donations и т.п.):

```sh
hugo new --kind page content/<slug>.md
# или через make-обёртку:
make new-page SLUG=<slug>
```

Архетип — `archetypes/page.md`.

## Деплой

Любой push в `main` автоматически вызывает workflow `CI`: Hugo билд → `rsync` на VPS → ping Yandex Webmaster → нотификация в Telegram.

Если push не сработал (бывает при outage GitHub Actions) — перезапустить вручную:

```sh
gh workflow run CI               # из CLI
# или открыть https://github.com/jtprogru/jtprog.ru/actions/workflows/main.yaml
# и нажать «Run workflow»
```

## Скрипты

Всё, что лежит в `scripts/`, делится на две группы: регулярные хелперы (живут долго, могут пригодиться завтра) и разовые finalize'ы (фиксируют конкретную миграцию, оставлены для истории).

### Регулярные

| Скрипт | Зачем |
| --- | --- |
| `add_lastmod.py` | Бэкфилл `lastmod` во frontmatter постов (`content/**/index.md`), где он отсутствует — берёт значение из `date`. |
| `mermaid-prerender.py` | Оффлайн-рендер всех ```mermaid```-блоков в SVG → `assets/mermaid/<sha256>.svg`. Render hook темы встраивает их inline; runtime mermaid bundle грузится только если SVG не найден. Запускается через `make mermaid-render`. |
| `typograf.py` | Standalone Python 3 клиент ArtLebedev Typograf (stdlib-only). Используется как модуль из `typografy_md.py` и как CLI. |
| `typografy_md.py` | Прогон Typograf по Markdown с защитой кода, frontmatter, шорткодов, формул, ссылок и list-маркеров — типографируется только проза. |
| `indexnow.sh` | Дельта-сабмит в IndexNow (Bing/Yandex/Seznam/Naver) после деплоя: маппит изменённые файлы под `content/` в канонические URL и шлёт уникальный список. Вызывается из CI; шаг неблокирующий. |
| `indexnow-full.sh` | Разовый сабмит **всех** URL сайта (источник — `sitemap.xml` с разворачиванием sitemap-index). Уместен после миграции домена или массового рефактора permalinks; в CI не дёргать. |

### Разовые finalize'ы (исторические)

Сценарии-склейки, которыми закрывались конкретные фичи: каждый чистит локи sandbox'а, коммитит подготовленные изменения в нужные ветки `hugo-mishka` и `jtprog.ru`, мержит и бампит submodule. Отдельно от своей фичи бессмысленны, но удобны как краткая летопись изменений.

- `migrate-to-mishka.sh` — финальные шаги переезда с PaperMod на mishka.
- `finalize-og-image.sh` — auto-resize обложек под og:image.
- `finalize-cache-bust.sh` — cache-bust по mtime для og:image.
- `finalize-cache-bust-everywhere.sh` — тот же cache-bust для in-page обложек (нужно для Telegram IV).
- `finalize-iv-img-fix.sh` — совместимость с Telegram Instant View: убрать `<p>`-обёртку вокруг одиночных картинок + cache-bust.

## Тема

Все правки темы делаю в репо [`hugo-mishka`](https://github.com/jtprogru/hugo-mishka) — он же прикреплён через symlink `themes/mishka-dev`. После публикации правок:

```sh
git -C themes/mishka pull origin main   # или: git submodule update --remote themes/mishka
git add themes/mishka
git commit -m "chore(theme): bump mishka with <что нового>"
```

## Лицензия

В репозитории две лицензии, потому что код и тексты живут по разным правилам:

- **Код** (конфиги Hugo, layout-override'ы, `scripts/`, CI, Makefile) — [MIT](LICENSE).
- **Тексты постов** из `content/` и **иллюстрации** — [CC BY-NC-ND 4.0](LICENSE-CONTENT.md): копировать можно, коммерчески использовать и переделывать — нет, атрибуция со ссылкой на оригинал обязательна.
- Права на обложки принадлежат мне: старые обложки категорий рисовал [Igan Pol](https://www.behance.net/iganpol) и они выкуплены, обложки к постам я делаю сам.

Подробности и рекомендованный формат ссылки на пост — в [LICENSE-CONTENT.md](LICENSE-CONTENT.md).

