---
categories: howto
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: howto.png
  relative: false
date: "2019-08-05T12:24:55+03:00"
tags:
- centos
- yum
- deltarpm
- error
- troubleshooting
- package manager
- linux
- command line
- howto
title: '[HowTo] Delta RPMs disabled'
type: post
description: "Решение ошибки \"Delta RPMs disabled because /usr/bin/applydeltarpm not installed\" при работе с пакетным менеджером YUM в CentOS, включая поиск и установку необходимого пакета."
keywords: ["centos yum error", "delta rpms disabled", "applydeltarpm not installed", "yum provides", "yum install deltarpm", "troubleshooting centos", "package manager linux", "fix yum error", "centos howto"]
---

Привет, `%username%`! Продолжаем исправлять косяки, которые периодически возникают при работе с менеджером пакетов `YUM`.

Иногда при обновлении пакетов в Centos появляется ошибка следующего вида:

```bash
Delta RPMs disabled because /usr/bin/applydeltarpm not installed.
```

Узнаём какой пакет предоставляет приложение `/usr/bin/applydeltarpm` с помощью команды:

```bash
yum provides '*/applydeltarpm'
```

Результат выполнения команды:

```bash
deltarpm-3.6-3.el7.x86_64 : Create deltas between rpms
Repo : base
Matched from:
Filename : /usr/bin/applydeltarpm

deltarpm-3.6-3.el7.x86_64 : Create deltas between rpms
Repo : @base
Matched from:
Filename : /usr/bin/applydeltarpm
```

И устанавливаем необходимые пакет:

```bash
yum install deltarpm
```

На этом все! Profit!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
