# [jtprog.ru](https://jtprog.ru)

[![CI](https://github.com/jtprogru/jtprog.ru/actions/workflows/main.yml/badge.svg)](https://github.com/jtprogru/jtprog.ru/actions/workflows/main.yml)
![GitHub](https://img.shields.io/github/license/jtprogru/jtprog.ru)
![GitHub issues](https://img.shields.io/github/issues/jtprogru/jtprog.ru?style=plastic)

Личный блог про SRE, DevOps и системное администрирование — [jtprog.ru](https://jtprog.ru).

## Стек

- **[Hugo](https://gohugo.io/)** (Extended, версия из CI: см. `.github/workflows/main.yml`).
- **Тема [`hugo-mishka`](https://github.com/jtprogru/hugo-mishka)** — собственная, подключена submodule'ом в `themes/mishka`.
- **GitHub Actions** + [`jtprogru/hugo-rsync-deployment`](https://github.com/jtprogru/hugo-rsync-deployment) — сборка и `rsync` на VPS.
- Контент — markdown в `content/`, обложки — `assets/covers/`, метаданные проектов — `data/projects.yaml`.

## Структура

```
.
├── content/          # посты + одиночные страницы (about-me, archives, search, projects, donations…)
├── data/             # projects.yaml — источник для блока проектов и /projects/
├── assets/           # обложки и прочее, что должен пайплайнить Hugo
├── static/           # «как есть» — favicon, manifest, robots
├── layouts/          # override'ы поверх темы (если нужны)
├── archetypes/       # шаблоны фронтматтера для `hugo new`
├── scripts/          # хелперы для актуализации постов и cover-pipeline
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

# task-обёртки (см. Taskfile.yml)
task --list
```

> Тема дев-клонируется через symlink `themes/mishka-dev → ~/Work/.../hugo-mishka` и подключается флагом `hugo --theme mishka-dev`. Прод использует pinned-submodule `themes/mishka`.

## Новый пост

```sh
hugo new content/<slug>/index.md
```

Архетип лежит в `archetypes/default.md`. Cover-картинка — рядом с `index.md` (page bundle) **или** в `assets/covers/<slug>.{jpg,png,webp}` (общий).

## Деплой

Любой push в `main` автоматически вызывает workflow `CI`: Hugo билд → `rsync` на VPS → ping Yandex Webmaster → нотификация в Telegram.

Если push не сработал (бывает при outage GitHub Actions) — перезапустить вручную:

```sh
gh workflow run CI               # из CLI
# или открыть https://github.com/jtprogru/jtprog.ru/actions/workflows/main.yml
# и нажать «Run workflow»
```

## Тема

Все правки темы делаю в репо [`hugo-mishka`](https://github.com/jtprogru/hugo-mishka) — он же прикреплён через symlink `themes/mishka-dev`. После публикации правок:

```sh
git -C themes/mishka pull origin main   # или: git submodule update --remote themes/mishka
git add themes/mishka
git commit -m "chore(theme): bump mishka with <что нового>"
```

## Лицензия

Посты блога распространяются по лицензии [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/). Свободно модифицировать и/или распространять — при соблюдении условий:

- указать меня как автора оригинального текста;
- указать адрес оригинального поста на домене [jtprog.ru](https://jtprog.ru), активной ссылкой;
- если вносили изменения — явно указать это (например, «…с изменениями» / «основано на…»);
- указать, что пост распространяется по этой лицензии.

Рекомендованный формат ссылки:

> «Мой личный чек-лист для Linux сервера», &copy; Михаил (jtprogru) Савин, [https://jtprog.ru/linux-checklist/](https://jtprog.ru/linux-checklist/), CC BY-NC-ND 4.0
>
> "My personal checklist for a Linux server", &copy; Mikhail (jtprogru) Savin, [https://jtprog.ru/linux-checklist/](https://jtprog.ru/linux-checklist/), CC BY-NC-ND 4.0

## Кредиты

- Тексты — [Mikhail (jtprogru) Savin](https://savinmi.ru).
- Иллюстрации — [Igan Pol](https://www.behance.net/iganpol).
