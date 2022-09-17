---
author: jtprogru
categories: DevOps
cover:
  alt: devops
  caption: devops
  image: devops.png
  relative: false
date: "2020-11-05T23:00:00+03:00"
description: ""
tags:
- gitlab-ci
- devops
- hugo
- ci-cd
title: '[DevOps] GitLab-CI – делаем себе просто'
type: post
---

Привет, `%username%`! Я решил вернуться к генераторам статических сайтов. На просторах данного блога я уже писал о переезде с [Wordpress на Hugo](https://jtprog.ru/gohugo/). В сентябре я решил дать Wordpress'у второй шанс, но увы и ах.

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

На это всё! Если есть замечания – велком в [чат](https://ttttt.me/jtprogru_chat)!
