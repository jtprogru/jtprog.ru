---
categories: ["Work"]
cover:
  alt: work
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: work.png
  relative: false
date: 2023-10-17T20:58:16+03:00
tags:
- taskfile
- makefile
- YAML
- CLI
title: '[Work] Taskfile'
type: post
description: "Сравнение Taskfile и Makefile для автоматизации DevOps-задач. Примеры конфигураций, плюсы и минусы инструментов."
keywords:
  - "Taskfile vs Makefile"
  - "автоматизация DevOps"
  - "YAML для сборки"
  - "инструменты CLI"
  - "настройка Go-Task"
  - "сравнение систем сборки"
---

Привет, `%username%`! Есть такая примитивная утилита автоматизации жизни любого DevOps и SRE как `make`, которая настраивается через `Makefile` и позволяет делать разные вещи. Но знаешь ли ты про `Taskfile` и утилиту `task`?

## Makefile

Смотри, чтобы не писать каждый раз `docker-compose -f docker-compose.dev.yml up -d`, можно описать эту команду в `Makefile` и вызывать ее чем-то вроде `make run-dev`. Сильно меньше букв писать в консоли, а значит меньше опечаток и быстрее процессы идут. А теперь представим, что-то более рабочее – вот мой простой `Makefile` для типичного проекта на Golang:

```make
SHELL := /bin/bash
.SILENT:
.DEFAULT_GOAL := help

# Global vars
export SYS_GO=$(shell which go)
export SYS_GOFMT=$(shell which gofmt)
export SYS_DOCKER=$(shell which docker)

export BINARY_DIR=dist
export BINARY_NAME=app

include .env
export $(shell sed 's/=.*//' .env)

.PHONY: run.cmd
## Run as go run cmd/app/main.go
run.cmd: cmd/app/main.go
	$(SYS_GO) run cmd/app/main.go

.PHONY: run.bin
## Run as binary
run.bin: build.bin
	source .env && ./$(BINARY_DIR)/$(BINARY_NAME)

.PHONY: run.dc
## Run in Docker
run.dc:
	$(SYS_DOCKER) compose up -d --build

.PHONY: down.dc
## Down Docker compose
down.dc:
	$(SYS_DOCKER) down -v

.PHONY: install-deps
## Install all requirements
install-deps: go.mod
	$(SYS_GO) mod tidy

.PHONY: build.bin
## Build bin file from go
build.bin: cmd/app/main.go
	$(SYS_GO) mod download && CGO_ENABLED=0 $(SYS_GO) build -o ./$(BINARY_DIR)/$(BINARY_NAME) cmd/app/main.go

.PHONY: fmt
## Run go fmt
fmt:
	$(SYS_GOFMT) -s -w .

.PHONY: vet
## Run go vet ./...
vet:
	$(SYS_GO) vet ./...

.PHONY: clean
## Clean all artifacts
clean:
	rm -rf $(BINARY_DIR)

.PHONY: test.short
## Run short test
test.short:
	$(SYS_GO) test --short -coverprofile=cover.out -v ./...

.PHONY: test.coverage
## Run test coverage
test.coverage:
	$(SYS_GO) tool cover -func=cover.out

.PHONY: test
## Run all test
test:
	make test.short && make test.coverage

.PHONY: swag
## Run swag
swag:
	swag init -g internal/app/app.go

.PHONY: lint
## Run golangci-lint
lint:
	golangci-lint -v run --out-format=colored-line-number

.PHONY: gen
## Run mockgen
gen:
	mockgen -source=internal/service/service.go -destination=internal/service/mocks/mock.go
	mockgen -source=internal/repository/repository.go -destination=internal/repository/mocks/mock.go

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
```

Все, что происходит в этом `Makefile` по командам довольно просто. Единственное, от чего может начать дергаться глаз – команда `help`. Ее я писал не сам, а нашел на просторах интернета и просто перекладываю из проекта в проект. А иногда полностью беру этот `Makefile` и тащу "as-is" – у меня в gist'e сохранен для этих целей.

## Taskfile

`Taskfile` (а точнее `Taskfile.yml`) – это отличная замена стандартному и, довольно часто, не читаемому Makefile'y. Для начала работы необходимо установить утилиту `task` – в моем случае это Homebrew:

```shell
brew install go-task/tap/go-task
```

Об установке на любые другие системы достаточно подробно написано в официальной [документации](https://taskfile.dev/installation/).

Давай попробуем прошлый наш `Makefile` переписать на новый лад. Создадим `Taskfile.yml` и положим в него такое содержимое:

```yaml
# yaml-language-server: $schema=https://taskfile.dev/schema.json
---
version: "3"

set:
  - pipefail

silent: false

env:
  BINARY_DIR: dist
  BINARY_NAME: app

tasks:
  default:
    silent: true
    cmds:
      - task --list --color

  run:cmd:
    desc: Run with go run cmd/app/main.go
    deps:
	    - install
	    - fmt
    preconditions:
      - test -f cmd/app/main.go
      - test -f $(which go)
    cmds:
      - go run cmd/app/main.go
    dotenv:
      - '.env'
  
  run:dc:
    desc: Run with docker-compose
    deps:
	    - down:dc
    preconditions:
      - test -f $(which docker-compose)
    cmds:
      - docker-compose up -d --build
  
  down:dc:
    desc: Down docker-compose serrvices
    preconditions:
      - test -f $(which docker-compose)
    cmds:
      - docker-compose down -v
  
  install:
    desc: Install all dependencies
    preconditions:
      - test -f $(which go)
      - test -f go.mod
      - test -f go.sum
    cmds:
      - go mod tidy
  
  fmt:
    desc: Run gofmt with fix
    preconditions:
      - test -f $(which gofmt)
    cmds:
      - gofmt -s -w .
  
  vet:
    desc: Run go vet
    preconditions:
      - test -f $(which go)
    cmds:
      - go vet ./...
  
  build:bin:
    desc: Build binary from golang sources
    deps:
	    - clean
    preconditions:
      - test -f cmd/app/main.go
      - test -f $(which go)
      - test -d $BINARY_DIR || mkdir $BINARY_DIR
    cmds:
      - go mod download
      - CGO_ENABLED=0 go build -o ./$BINARY_DIR/$BINARY_NAME cmd/app/main.go

  clean:
    desc: Clean all artifacts
    cmds:
      - rm -rf ./$BINARY_DIR
  
  test:short:
    desc: Run short tests
    preconditions:
      - test -f $(which go)
    cmds:
      - go test --short -coverprofile=cover.out -v ./...
    dotenv:
      - '.env'

  test:coverage:
    desc: Run test coverage
    preconditions:
      - test -f $(which go)
    cmds:
      - go tool cover -func=cover.out
    dotenv:
      - '.env'
  
  tests:
    desc: Run all tests
    cmds:
      - task: test:short
      - task: test:coverage
    dotenv:
      - '.env'

  swag:
    desc: Run swag
    preconditions:
      - test -f internal/app/app.go
      - test -f $(which swag)
    cmds:
      - swag init -g internal/app/app.go

  lint:
    desc: Run golangci-lint
    preconditions:
      - test -f $(which golangci-lint)
    cmds:
      - golangci-lint -v run --out-format=colored-line-number
  
  gen:
    desc: Run mockgen
    preconditions:
      - test -f $(which mockgen)
      - test -f internal/service/service.go
      - test -f internal/repository/repository.go
    cmds:
      - mockgen -source=internal/service/service.go -destination=internal/service/mocks/mock.go
      - mockgen -source=internal/repository/repository.go -destination=internal/repository/mocks/mock.go
```

Выглядит так, словно можно сделать компактнее, и это правильное ощущение. Я сделал достаточно простой вариант – просто в лоб переписал так, как есть. А теперь давай я сделаю более компактный вариант:


```yaml
# yaml-language-server: $schema=https://taskfile.dev/schema.json
---
version: "3"

set:
  - pipefail

silent: false

vars:
  BINARY_DIR: dist
  BINARY_NAME: app

tasks:
  default:
    silent: true
    cmds:
      - task --list --color

  precs:
    desc: All pre-checks
    cmds:
      - test -f $(which docker-compose)
      - test -f $(which gofmt)
      - test -f cmd/app/main.go
      - test -d {{ .BINARY_DIR }} || mkdir {{ .BINARY_DIR }}
      - test -f $(which go)
      - test -f internal/app/app.go
      - test -f $(which swag)
      - test -f $(which golangci-lint)
      - test -f $(which mockgen)
      - test -f internal/service/service.go
      - test -f internal/repository/repository.go
      - test -f go.mod
      - test -f go.sum
    silent: true
    internal: true

  run:cmd:
    desc: Run with go run cmd/app/main.go
    deps:
      - install
      - fmt
    cmds:
      - go run cmd/app/main.go
    dotenv:
      - '.env'

  run:dc:
    desc: Run with docker-compose
    deps:
      - down:dc
    cmds:
      - docker-compose up -d --build

  down:dc:
    desc: Down docker-compose serrvices
    deps:
      - precs
    cmds:
      - docker-compose down -v

  install:
    desc: Install all dependencies
    deps:
      - precs
    cmds:
      - go mod tidy

  fmt:
    desc: Run gofmt with fix
    deps:
      - precs
    cmds:
      - gofmt -s -w .

  vet:
    desc: Run go vet
    deps:
      - precs
    cmds:
      - go vet ./...

  build:bin:
    desc: Build binary from golang sources
    deps:
      - precs
      - clean
    cmds:
      - go mod download
      - CGO_ENABLED=0 go build -o ./{{ .BINARY_DIR }}/{{ .BINARY_NAME }} cmd/app/main.go

  clean:
    desc: Clean all artifacts
    cmds:
      - rm -rf ./{{ .BINARY_DIR }}

  test:short:
    desc: Run short tests
    deps:
      - precs
    cmds:
      - go test --short -coverprofile=cover.out -v ./...
    dotenv:
      - '.env'

  test:coverage:
    desc: Run test coverage
    deps:
      - precs
    cmds:
      - go tool cover -func=cover.out
    dotenv:
      - '.env'

  tests:
    desc: Run all tests
    cmds:
      - task: test:short
      - task: test:coverage
    dotenv:
      - '.env'

  swag:
    desc: Run swag
    deps:
      - precs
    cmds:
      - swag init -g internal/app/app.go

  lint:
    desc: Run golangci-lint
    deps:
      - precs
    cmds:
      - golangci-lint -v run --out-format=colored-line-number

  gen:
    desc: Run mockgen
    deps:
      - precs
    cmds:
      - mockgen -source=internal/service/service.go -destination=internal/service/mocks/mock.go
      - mockgen -source=internal/repository/repository.go -destination=internal/repository/mocks/mock.go
```

Вот теперь данный файл выглядит сильно проще, тем не менее всегда можно улучшить. Замечу, что задача `precs` является сборником всех `preconditions`, а чтобы не отвлекать в общем списке, данная задача помечена флагом `internal`. 

## Плюсы и минусы

Для начала подсветим плюсы и минусы для Makefile'ов.

Плюсы Makefile:

1. Широкое распространение – Makefile является стандартным инструментом сборки и автоматизации в мире программирования. Множество проектов и систем уже используют Makefile, поэтому разработчику может быть удобно использовать их знакомый формат;
2. Интеграция с средствами компиляции – Makefile часто используется для автоматизации сборки программного обеспечения, и он может легко интегрироваться с различными средствами компиляции и сборки, такими как GCC, Clang или CMake.

Минусы Makefile:

1. Синтаксическая сложность – Синтаксис Makefile не всегда интуитивно понятен, особенно для новых разработчиков. Ошибки в Makefile могут быть трудными для отладки и исправления.

Теперь давай посмотрим на плюсы и минусы Taskfile'ов.

Плюсы Taskfile:

1. Простота использования – Taskfile имеет простой и интуитивно понятный синтаксис. Он облегчает описание и запуск задач без необходимости изучения сложных правил и синтаксических конструкций;
2. Читабельность и наглядность – Каждая цель описывается в YAML достаточно просто и лаконично;

Минусы Taskfile:

1. Зависимость от утилиты task – ее гарантированно необходимо ставить отдельно;
2. Относительная новизна – Taskfile является относительно новым форматом и не так широко распространен, как Makefile.

### Сравнительная табличка

|**№**|**Критерий**|**Makefile**|**Taskfile**|
|:--:|:--|:--:|:--:|
|1.|Распространенность|+|-|
|2.|Переменные|+|+|
|3.|Шаблонизация|-|+|
|4.|Встроенный help|-|+|
|5.|Ветвления|+|+|
|6.|Внутренние команды|-|+|
|7.|Разделение на несколько файлов|+|+|

## Итоги

В целом, выбор между Makefile и Taskfile зависит от конкретной ситуации и предпочтений разработчика, а также решений конкретной команды. Если вы работаете с проектом, который уже использует Makefile, то наиболее разумным будет придерживаться этого формата. В нашей команде было принято решение перейти от Makefile к Taskfile ради повышения читаемости и наглядности скриптов автоматизации.

Ну и да, не стоит забывать про то, что большинство DevOps/SRE – это YAML-девелоперы, которым читать YAML сильно привычнее, нежели bash-/make-скрипты.

PS: Данную статью можно считать расширенным дополнением моей простенькой [презентации](https://jtprogru.github.io/taskfiles/), которую я показывал команде.

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". 
