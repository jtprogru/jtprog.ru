#!make
SHELL := /bin/bash
.SILENT:
.DEFAULT_GOAL := help

name="00000000-init"
host="0.0.0.0"
port="1313"
config="config.yml"

.PHONY: build
## Build static site
build:
	hugo -D --gc --verbose --config ./${config}

.PHONY: new.post
## Create new post content/$(name)/index.md;
## Parametrize by make new name="post-name"
new.post:
	hugo new --kind post "content/$(name)/index.md" --verbose

.PHONY: new.page
## Create new page content/$(name)/index.md;
## Parametrize by make new name="page-name"
new.page:
	hugo new --kind page "content/$(name)/index.md" --verbose

.PHONY: serve
## Run local development server with hugo
serve:
	hugo server -D -E -F --bind ${host} --port ${port} \
		--baseURL "http://${host}:${port}" --noHTTPCache \
		--gc --disableFastRender --verbose --watch --printMemoryUsage \
		--templateMetricsHints --templateMetrics \
		--config ./${config}

.PHONY: list.all
## Show all posts
list.all:
	hugo list all --verbose

.PHONY: list.draft
## Show only drafts
list.draft:
	hugo list drafts --verbose

.PHONY: update.theme
## Update all git submodules - now is only themes/papermod
update.theme:
	git submodule update --init --recursive --remote

.PHONY: help
## Show this help message
help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) == Darwin && echo '--no-init --raw-control-chars')
