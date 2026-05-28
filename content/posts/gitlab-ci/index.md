---
aliases:
  - '/gitlab-ci/'
categories: ["DevOps"]
cover:
  alt: devops
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: devops.png
  relative: false
date: "2020-11-05T23:00:00+03:00"
lastmod: "2026-05-15T20:00:00+03:00"
tags:
- gitlab-ci
- devops
- hugo
- ci-cd
- automation
- deployment
- static site
- markdown
- docker
- rsync
title: 'GitLab-CI – делаем себе просто'
type: post
description: "Описание простой схемы автоматизации CI/CD для статического сайта на Hugo с использованием GitLab CI, Docker и rsync для деплоя."
keywords: ["gitlab ci", "hugo", "ci/cd", "автоматизация деплоя", "статический сайт", "docker", "rsync", "gitlab pipeline", "devops", "markdown blog", "gitlab 17", "gitlab components", "rules workflow", "ci_id_tokens", "oidc gitlab"]
---

Привет, `%username%`! Я решил вернуться к генераторам статических сайтов. На просторах данного блога я уже писал о переезде с [Wordpress на Hugo](https://jtprog.ru/posts/gohugo/). В сентябре я решил дать Wordpress'у второй шанс, но увы и ах.

> 🔄 **Обновлено 2026-05-15**: схема в посте всё ещё работает на современных GitLab-инсталляциях, но в синтаксисе CI-файла за 5-6 лет накопились deprecation'ы. Сам я уже переехал на [GitHub Actions](/posts/github-actions/), но если ты на GitLab — внизу добавил блок [«Что обновить под GitLab 17»](#что-обновить-под-gitlab-17) с конкретными правками: `only/except` → `rules`, `master` → `main`, актуальные образы, CI Components, `!reference` и OIDC через `id_tokens` вместо base64-ключей в переменных.

Короче я решил основательно упороться, придумать некоторые костыли, приправить их велосипедами и сделал следующую схему:

1. Установил себе локально [Hugo](https://gohugo.io);

2. Завел на [GitLab](https://gitlab.com) репозиторий с Markdown файлами статей своего бложика (включая и эту);

3. Подключил к репе CI;

Идеологически получилось следующее. Создается директория для будущей статьи, в которую кладется заготовленный шаблонный файлик с именем `index.md`. После чего файлик сразу открывается в моем редакторе для Markdown – `Mark Text`. Делается это вот таким скриптиком:

```bash
#!/usr/bin/env bash
set -e

BLOG_PATH="/Users/jtprog/workplace/blog"

post_name=$1

cd "${BLOG_PATH}"

hugo new "${post_name}/index.md"

open -a "Mark Text" ${BLOG_PATH}/content/${post_name}/index.md

exit 0
```

Его я положил в отдельную директорию, которая добавлена в `$PATH`, а запускается это вот так:

```bash
hugo-new.sh "my-new-post-in-blog"
```

Строка `my-new-post-in-blog` сразу считается URL'ом для данного поста.

В настройках репозитория добавлены переменные:

1. `SSH_PRIVATE_KEY` – приватный ключ для доступа по ssh/rsync/scp;

2. `SSH_USER` – пользователь под которым подключаемся;

3. `SSH_HOST` – хост куда подключаемся;

4. `REMOTE_PATH` – куда на удаленном хосте кладем файлики;

**Важно:** добавлять приватный ключик можно как угодно, но кмк правильнее его добавлять как `Masked` переменную. Тут есть нюанс: после генерации нового ключа, его необходимо перевести в `base64`, т.к. именно такой формат может быть `Masked`. Сделать это можно следующим способом:

```bash
cat .ssh/gitlabci | base64 -w0 ; echo
```

Соответственно обратная "расшифровка" ключа у нас происходит уже внутри контейнера при сборке.

Так же я добавил `Dockerfile`, который, по сути, нужен только для генерации статики и отправки изменений на [хостинг](https://fozzy.com/aff.php?aff=1116). Его содержимое довольно простое:

```dockerfile
FROM ubuntu:20.04

LABEL maintainer="mail@jtprog.ru"

LABEL version="1.0"

WORKDIR /site

COPY . /site/

ARG SSH_PRIVATE_KEY
ARG SSH_USER
ARG SSH_HOST
ARG REMOTE_PATH

RUN DEBIAN_FRONTEND=noninteractive apt-get -y update \
    && apt-get install -y openssh-client hugo rsync git \
    && rm -rf /var/cache/apt/* \
    && mkdir -p /root/.ssh \
    && echo "Host *\n\tStrictHostKeyChecking no\n\n" > /root/.ssh/config \
    && cat /root/.ssh/config && chmod 700 /root/.ssh \
    && ssh-keyscan -p 22 ${SSH_HOST} > /root/.ssh/known_hosts \
    && git submodule update --remote --merge \
    && echo "Генерирование страниц началось" && hugo \
    && echo "${SSH_PRIVATE_KEY}" |  tr -d ' ' | base64 --decode > /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa && cat /root/.ssh/id_rsa \
    && cp ./content/.htaccess ./public/.htaccess && cp ./content/robots.txt ./public/robots.txt \
    && echo "Запуск rsync" && rsync -avz -e "ssh -i ~/.ssh/id_rsa" --progress --delete public/ ${SSH_USER}@${SSH_HOST}:${REMOTE_PATH} \
    && echo "Завершён деплой"

```

Я запускаю сборку image на базе данного файла и совершенно не сохраняю его – он мне не нужен.

Для сборки подключается `.gitlab-ci.yml` с довольно простым содержимым:

```yaml
image: docker:19.03.12

services:
  - docker:19.03.12-dind

variables:
  CI_DEBUG_TRACE: "false"
  GIT_SUBMODULE_STRATEGY: recursive
  DOCKER_DRIVER: overlay

deploy fozzy:
  stage: build
  script:
    - docker build --build-arg SSH_PRIVATE_KEY="${SSH_PRIVATE_KEY}" --build-arg SSH_USER="${SSH_USER}" --build-arg SSH_HOST="${SSH_HOST}" --build-arg REMOTE_PATH="${REMOTE_PATH}" --cache-from $CI_REGISTRY_IMAGE:latest --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --tag $CI_REGISTRY_IMAGE:latest .
  only:
    - master

```

А дальше по пушу в ветку `master` у меня автоматически запускается все вышеописанное, а примерно через 1.5-2 минуты статья оказывается опубликованной.

О том, что правильно или не правильно тут сделано я не готов рассуждать. И местами мне немного стыдно. Но данная схема работает для меня, она воспроизводима, она может работать не только у меня.

## Что обновить под GitLab 17

Идея схемы (Docker → Hugo → rsync) не устарела, но GitLab за пять с лишним лет успел задепрекейтить часть синтаксиса и притащить новые механизмы, которые упрощают жизнь. Если ты сейчас собираешься повторить — вот по чему пройтись.

### `only/except` → `rules` / `workflow`

`only`/`except` помечены как deprecated ещё в GitLab 14 (2021). В пайплайнах 2026-го используется либо `rules:` на уровне job'ы, либо глобальный `workflow.rules:`:

```yaml
# было
deploy:
  only:
    - master

# стало
deploy:
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

Или централизованно для всего пайплайна:

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

Не забудь — основной ветке сейчас обычно `main`, а не `master`.

### Образы Docker

В исходнике `docker:19.03.12` + `docker:19.03.12-dind` — 19.03 EOL давно. Сейчас актуальны 24-26.x:

```yaml
image: docker:26
services:
  - docker:26-dind
```

Для самой сборки контейнера в CI всё чаще ставят kaniko или buildah вместо DinD — не требуется привилегированный runner. Канонический [kaniko-пример из docs.gitlab.com](https://docs.gitlab.com/ee/ci/docker/using_kaniko.html) ставится почти one-line.

Базовый образ `ubuntu:20.04` в Dockerfile тоже стоит подтянуть до `24.04` (или вообще `debian:12-slim`).

### Components — переиспользование между проектами

С GitLab 16.6 (GA в 17.0) появились [CI/CD Components](https://docs.gitlab.com/ee/ci/components/) — переиспользуемые куски пайплайна, версионируемые как git-ссылки:

```yaml
include:
  - component: gitlab.com/jtprogru/ci-components/hugo-deploy@1.2.0
    inputs:
      hugo-version: "0.161"
      remote-host: $SSH_HOST
```

Идея — вынести «общую часть» (сборка/тесты/деплой) в отдельный component-проект, а основной `.gitlab-ci.yml` сделать максимально тонким. Это альтернатива тому, что раньше делали через `include: project:` или копипасту YAML между репами.

### `!reference` для DRY внутри одного файла

С GitLab 13.9 есть [!reference](https://docs.gitlab.com/ee/ci/yaml/yaml_optimization.html#reference-tags) — позволяет ссылаться на отдельную часть другого job'а/блока, не дублируя YAML:

```yaml
.deploy-script:
  script:
    - echo "Building..."
    - hugo --minify
    - rsync -avz public/ ${SSH_USER}@${SSH_HOST}:${REMOTE_PATH}

deploy production:
  script:
    - !reference [.deploy-script, script]
    - curl https://hooks.jtprog.ru/notify
```

Это гибче, чем классический `extends:`, потому что цеплять можно не job целиком, а конкретный массив (`script`, `before_script`, `rules`).

### OIDC и `id_tokens` вместо ключей в переменных

В исходнике приватный SSH-ключ хранится как base64 в Masked variable. Для SSH-деплоя это всё ещё рабочий подход, но если ты ходишь в облака (AWS, GCP, Azure, Vault) — сейчас осмысленно использовать [OIDC `id_tokens`](https://docs.gitlab.com/ee/ci/cloud_services/), а не долгоживущие секреты:

```yaml
deploy:
  id_tokens:
    AWS_TOKEN:
      aud: https://gitlab.com
  script:
    - aws sts assume-role-with-web-identity \
        --role-arn $AWS_ROLE_ARN \
        --web-identity-token $AWS_TOKEN \
        --role-session-name gitlab-deploy
    - aws s3 sync public/ s3://my-bucket/
```

Тут GitLab выдаёт короткоживущий JWT, который облако принимает по trust-relationship — никаких access-key'ев в переменных проекта.

Для Vault аналогично — `vault.read_secret_data` через JWT.

### File-type variables вместо base64

Если SSH-ключ всё-таки нужен файлом — есть штатный [`File`-тип переменной](https://docs.gitlab.com/ee/ci/variables/#use-file-type-cicd-variables):

```yaml
variables:
  SSH_PRIVATE_KEY:
    description: "private key, type=File"

deploy:
  script:
    - chmod 600 $SSH_PRIVATE_KEY     # переменная — путь к временному файлу
    - rsync -e "ssh -i $SSH_PRIVATE_KEY" -avz public/ $SSH_USER@$SSH_HOST:$REMOTE_PATH
```

Не надо ничего декодировать из base64 в самом Dockerfile/скрипте — GitLab сам кладёт значение в файл и подставляет путь.

### TL;DR апдейта

Если повторяешь схему сегодня:

1. Везде `main`, не `master`.
2. `rules:`/`workflow.rules:` вместо `only/except`.
3. Образы Docker — 26.x, либо вообще на kaniko/buildah.
4. SSH-ключ — `File`-переменная. Для облаков — OIDC `id_tokens`.
5. Если есть несколько проектов с похожими пайплайнами — заводи [Components](https://docs.gitlab.com/ee/ci/components/) и подключай через `include: component:`.
6. Для DRY внутри одного файла — `!reference`.

И отдельно: сам я на текущий момент держу деплой блога на GitHub Actions (см. соседний пост [про мой GitHub Actions](/posts/github-actions/) и [рассказ про инфру блога](/posts/gohugo/#что-изменилось-с-2019-го)). GitLab-CI всё ещё отличный инструмент, особенно если у тебя self-hosted экземпляр — просто я ушёл туда, где лежит сам репозиторий.

На это всё! Если есть замечания – велком в [чат](https://ttttt.me/jtprogru_chat)!
