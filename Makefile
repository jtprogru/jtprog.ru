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

.DEFAULT_GOAL := help

.PHONY: help prec build serve new new-page update-theme mermaid-render

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*## ' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

prec:
	@command -v hugo >/dev/null || { echo "hugo not found"; exit 1; }

build: prec ## Build static site
	hugo -D -E -F

serve: prec ## Run local development server with hugo
	hugo server -D -E -F --bind $(HOST) --port $(PORT) --baseURL "http://$(HOST):$(PORT)" --noHTTPCache --ignoreCache --gc --renderStaticToDisk --forceSyncStatic --logLevel $(LOG_LEVEL) --minify --watch --printMemoryUsage --templateMetricsHints --templateMetrics --disableFastRender --renderStaticToDisk --printUnusedTemplates --printPathWarnings --printI18nWarnings --cleanDestinationDir --config ./$(CONFIG) --theme "mishka-dev"

new: prec ## Create new post from archetype (usage: make new SLUG=my-post)
	@test -n "$(SLUG)" || { echo "usage: make new SLUG=my-post"; exit 1; }
	hugo new content/posts/$(SLUG)/index.md

new-page: prec ## Create new standalone page from archetype (usage: make new-page SLUG=my-page)
	@test -n "$(SLUG)" || { echo "usage: make new-page SLUG=my-page"; exit 1; }
	hugo new --kind page content/$(SLUG).md

update-theme: prec ## Update all git submodules - now is only themes/PaperMod
	@command -v git >/dev/null || { echo "git not found"; exit 1; }
	git submodule update --init --recursive --remote

mermaid-render: ## Pre-render mermaid blocks from content/**/*.md to assets/mermaid/<sha256>.svg
	@command -v python3 >/dev/null || { echo "python3 not found"; exit 1; }
	@command -v npx >/dev/null || { echo "npx not found"; exit 1; }
	python3 scripts/mermaid-prerender.py
