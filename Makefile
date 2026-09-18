SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -ec

export ENV ?= development

-include .env
-include $(ENV)/.env
-include $(HOME)/.env

CONFIG    ?= hugo.yaml
LOG_LEVEL ?= debug
PORT      ?= 1313
HOST      ?= 127.0.0.1

# Прод-сборка и деплой. Значения переопределяются из окружения — CI передаёт
# их из секретов, локально они не нужны и не используются.
PUBLIC_DIR   ?= public
HUGO_PROD    ?= --minify
DEPLOY_KEY   ?= $(HOME)/.ssh/id_rsa_deploy
DEPLOY_PORT  ?= 22
# --delay-updates: все обновлённые файлы кладутся во временный каталог и
# переставляются на место одним махом в конце. Без него сайт на время
# заливки полуразобран, и краулер (Telegram кэширует и отрицательный
# результат — навсегда, до ручного флаша через @WebpageBot) может
# застать 404 на странице или обложке.
RSYNC_ARGS   ?= --archive --compress --delete --delay-updates

.DEFAULT_GOAL := help

.PHONY: help prec build build-prod serve new new-page update-theme \
        mermaid-render mermaid-check math-render math-check math-prune \
        cover-rasterize stamp-commit robots deploy

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*## ' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

prec:
	@command -v hugo >/dev/null || { echo "hugo not found"; exit 1; }

build: prec cover-rasterize ## Build static site (с черновиками, для локальной проверки)
	hugo -D -E -F

# Ровно то, что раньше зашивалось в hugo-arguments у deploy-экшена. Без -D/-E/-F:
# черновики, отложенные и протухшие посты в прод не едут.
build-prod: prec cover-rasterize ## Production build into public/ (no drafts, minified)
	hugo --config $(CONFIG) --destination $(PUBLIC_DIR) $(HUGO_PROD)

# copyright в hugo.yaml содержит плейсхолдер @@@COMMIT@@@. Правит файл на месте,
# поэтому только в одноразовом чекауте CI — локально затрёт конфиг в рабочем дереве.
stamp-commit: ## Substitute @@@COMMIT@@@ in $(CONFIG) with the current short SHA (CI only)
	@test -n "$(CI)" || { echo "stamp-commit правит $(CONFIG) на месте — только в CI (CI=1)"; exit 1; }
	sed -i -e "s/@@@COMMIT@@@/$$(git rev-parse --short HEAD)/g" $(CONFIG)

# robots.txt лежит в content/, но как отдельный output не собирается:
# enableRobotsTXT выключен, чтобы Hugo не перетирал его своим шаблоном.
robots: ## Copy content/robots.txt into the built site
	cp content/robots.txt $(PUBLIC_DIR)/robots.txt

deploy: ## rsync built site to the VPS (needs DEPLOY_USER/HOST/DEST)
	@test -n "$(DEPLOY_USER)" -a -n "$(DEPLOY_HOST)" -a -n "$(DEPLOY_DEST)" \
		|| { echo "нужны DEPLOY_USER, DEPLOY_HOST, DEPLOY_DEST"; exit 1; }
	@test -d "$(PUBLIC_DIR)" || { echo "нет $(PUBLIC_DIR) — сначала make build-prod"; exit 1; }
	rsync $(RSYNC_ARGS) \
		-e "ssh -i $(DEPLOY_KEY) -p $(DEPLOY_PORT) -o StrictHostKeyChecking=accept-new" \
		$(PUBLIC_DIR)/ "$(DEPLOY_USER)@$(DEPLOY_HOST):$(DEPLOY_DEST)/"

serve: prec cover-rasterize ## Run local development server with hugo
	hugo server -D -E -F --bind $(HOST) --port $(PORT) --baseURL "http://$(HOST):$(PORT)" --noHTTPCache --ignoreCache --gc --renderStaticToDisk --forceSyncStatic --logLevel $(LOG_LEVEL) --minify --watch --printMemoryUsage --templateMetricsHints --templateMetrics --disableFastRender --renderStaticToDisk --printUnusedTemplates --printPathWarnings --printI18nWarnings --cleanDestinationDir --config ./$(CONFIG) --theme "mishka-dev"

new: prec ## Create new post from archetype (usage: make new SLUG=my-post)
	@test -n "$(SLUG)" || { echo "usage: make new SLUG=my-post"; exit 1; }
	hugo new content/posts/$(SLUG)/index.md

new-page: prec ## Create new standalone page from archetype (usage: make new-page SLUG=my-page)
	@test -n "$(SLUG)" || { echo "usage: make new-page SLUG=my-page"; exit 1; }
	hugo new --kind page content/$(SLUG).md

update-theme: prec ## Update all git submodules - now is only themes/mishka
	@command -v git >/dev/null || { echo "git not found"; exit 1; }
	git submodule update --init --recursive --remote

mermaid-render: ## Pre-render mermaid blocks from content/**/*.md to assets/mermaid/<sha256>.{svg,dark.svg,png}
	@command -v python3 >/dev/null || { echo "python3 not found"; exit 1; }
	@command -v npx >/dev/null || { echo "npx not found"; exit 1; }
	python3 scripts/mermaid-prerender.py

# Пост без пререндера молча уезжает на runtime-ветку render hook'а: тянет
# mermaid с CDN и рисует схему в цветах, которые никто не проверял. Ловим в CI.
mermaid-check: ## Fail if any mermaid block has no pre-rendered svg/png
	@command -v python3 >/dev/null || { echo "python3 not found"; exit 1; }
	python3 scripts/mermaid-prerender.py --check

# LaTeX-формулы. KaTeX рисует их в браузере, а Instant View никакого JS не
# исполняет — без растра в IV уезжает сырой TeX. Растр лежит в assets/math/
# и коммитится (в CI нет Chromium, там работает только math-check).
math-render: ## Pre-render LaTeX formulas from content/**/*.md to assets/math/<sha256>.png
	@command -v node >/dev/null || { echo "node not found"; exit 1; }
	@test -d node_modules || npm ci
	node scripts/math-prerender.mjs

math-check: ## Fail if any LaTeX formula has no pre-rendered png
	@command -v node >/dev/null || { echo "node not found"; exit 1; }
	node scripts/math-prerender.mjs --check

math-prune: ## Drop pre-rendered formula PNGs that no post references anymore
	@command -v node >/dev/null || { echo "node not found"; exit 1; }
	node scripts/math-prerender.mjs --prune

# Растр — сборочный артефакт, а не контент: в репозитории лежит только .svg,
# PNG рисуется перед каждой сборкой. Поэтому цель стоит в зависимостях build,
# build-prod и serve, а не вызывается руками.
cover-rasterize: ## Rasterize SVG covers to PNG for og:image (social parsers do not render SVG)
	@command -v rsvg-convert >/dev/null || { echo "rsvg-convert not found: brew install librsvg"; exit 1; }
	bash scripts/cover-rasterize.sh
