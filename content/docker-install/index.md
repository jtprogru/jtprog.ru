---
categories: howto
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: howto.png
  relative: false
date: "2020-08-02T16:10:00+03:00"
tags:
- docker
- docker-compose
- howto
- installation
- ubuntu
- linux
- command line
- apt
- package manager
- containerization
- development environment
title: '[HowTo] Установка Docker на Ubuntu 20.04'
type: post
description: "Пошаговое руководство по установке Docker и Docker Compose на Ubuntu 20.04, включая удаление старых версий, добавление репозиториев и проверку установки."
keywords: ["docker install ubuntu 20.04", "install docker compose", "ubuntu docker", "linux containerization", "how to install docker", "docker guide", "apt get docker", "docker command line", "development environment setup"]
---

Привет, `%username%`! Это небольшая заметка "на память", о том какие шаги необходимо выполнить для установки Docker на свежий сервер с Ubuntu 20.04.

Вопросы в духе "зачем нам докер?" возможно будут рассмотрены в следующих статьях. А тут будет описана просто последовательность шагов по установке Docker и docker-compose для личный нужд так сказать.

Удалить старые версии (на всякий случай, иначе будут проблемы):

```bash
sudo apt-get remove docker docker-engine docker.io containerd runc
```

Обновление пакетов, установка зависимостей:

```bash
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
```

Добавление официального ключа:

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```

Проверка ключа (успокоим внутреннего параноика):

```bash
sudo apt-key fingerprint 0EBFCD88

pub   rsa4096 2017-02-22 [SCEA]
      9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88
uid           [ unknown] Docker Release (CE deb) <docker@docker.com>
sub   rsa4096 2017-02-22 [S]
```

Добавление официального репозитория:

```bash
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
```

Установка демона Docker:

```bash
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

Проверка что Docker установился и запущен. Запуск `hello-world`:

```bash
sudo docker run hello-world
```

Для тех, кому очень надо – ставим еще и `docker-compose` (версия `1.26.2` – последняя актуальная на момент написания статьи):

```bash
sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
```

Даем права на исполнение:

```bash
sudo chmod +x /usr/local/bin/docker-compose
```

Проверяем версию только что установленного `docker-compose`:

```bash
docker-compose --version
docker-compose version 1.26.2, build eefe0d31
```

Мало ли чего, но вот удаление `docker` и `docker-compose`:

```bash
sudo apt-get purge docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker
sudo rm -rf /usr/local/bin/docker-compose
```

На этом всё! Profit!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". 
