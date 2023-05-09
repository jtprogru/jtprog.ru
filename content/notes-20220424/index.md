---
categories: Notes
cover:
  alt: notes
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: notes.png
  relative: false
date: "2022-04-24T14:30:18+03:00"
tags:
- заметкинаполях
- apt
- apt-key
- ubuntu
title: '[Notes] Заметки на полях 24.04.2022'
type: post
---

Привет, `%username%`! Сегодня я решил пересобрать свой домашний стенд из старенького ноутбука и переустановить на
нем K8s, а заодно и обновить Ubuntu до свежей Ubuntu 22.04 LTS. После чистки начали появляться ошибки при попытке
обновить систему. Ниже о том, как это исправить.

Пример ошибки при обновлении в Ubuntu 22.04 LTS:

```bash
sudo apt update
...
All packages are up to date.
W: https://download.docker.com/linux/ubuntu/dists/jammy/InRelease: Key is stored in legacy trusted.gpg
keyring (/etc/apt/trusted.gpg), see the DEPRECATION section in apt-key(8) for details.
```

Посмотреть список всех публичных ключей для подписи с выхлопом:

```bash
sudo apt-key list
Warning: apt-key is deprecated. Manage keyring files in trusted.gpg.d instead (see apt-key(8)).
/etc/apt/trusted.gpg
--------------------
pub   rsa4096 2017-02-22 [SCEA]
      9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88
uid           [ unknown] Docker Release (CE deb) <docker@docker.com>
sub   rsa4096 2017-02-22 [S]
...
```

Экспортируем ключи:

```bash
sudo apt-key export 0EBFCD88 | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.pub
```

Важно: `0EBFCD88` это последние 8 символов отпечатка публичного ключа.

Правим source lists:

```bash
vim /etc/apt/sources.list.d/docker.list
```

Который изначально выглядит вот так:

```ini
deb [arch=amd64] https://download.docker.com/linux/ubuntu jammy stable
# deb-src [arch=amd64] https://download.docker.com/linux/ubuntu jammy stable
```

А после наших правок должен выглядеть вот так:

```ini
deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/docker.pub] https://download.docker.com/linux/ubuntu jammy stable
# deb-src [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/docker.pub] https://download.docker.com/linux/ubuntu jammy stable
```

Да, тут мы просто указали путь до открытого ключа, который ранее экспортировали. Аналогичное редактирование
необходимо провести для всех остальных проблемных репозиториев.

Ответ на вопрос возникновения такой ошибки кроется в самой ошибке, а так же в man’e. Если открыть нужный раздел
man’a который предлагается в ошибке, то в секции Deprecation можно увидеть “как теперь надо делать”:

```bash
man 8 apt-key
```

То есть, старый вариант больше не подходит и в скором времени будет выпелен (не просто ж так оно в deprecated перенесено):

```bash
wget -qO- https://myrepo.example/myrepo.asc | sudo apt-key add -
```

Теперь же нужно выполнять следующее:

```bash
wget -qO- https://myrepo.example/myrepo.asc | sudo tee /etc/apt/trusted.gpg.d/myrepo.asc
```

Собственно вот и всё. Пойду дальше переделывать стенд, настраивать раннер для запуска тестов ролей Ansible и пройчий маразм.

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).
