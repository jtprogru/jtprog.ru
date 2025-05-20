---
categories: howto
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: howto.png
  relative: false
date: "2016-08-08T10:34:00+03:00"
tags:
- locale
- perl
- linux
- ubuntu
- troubleshooting
- error
- localization
- command line
title: '[HowTo] Fix locale Perl'
type: post
description: "Решение проблемы с настройками локали Perl в Ubuntu Server 14.04, которая приводит к предупреждениям и ошибкам при обновлении системы, с использованием команды locale-gen."
keywords: ["fix locale perl", "ubuntu locale error", "perl warning setting locale failed", "locale-gen ubuntu", "linux localization", "troubleshooting ubuntu", "perl locale settings", "command line howto"]
---

Привет, `%username%`! В последнее время заметил на всех сервера под управлением `Ubuntu Server 14.04` одну общую проблему. При попытке обновиться стандартными средствами выдается ошибка настройки локализации. Быстрый гуглеж выдает вот такое примитивное решение.

Собственно вот такой код вам может выдать консоль при попытке обновить систему:  

```bash
perl: warning: Setting locale failed. 
perl: warning: Please check that your locale settings:
    LANGUAGE = (unset),
    LC_ALL = (unset),
    LC_CTYPE = "ru_RU.UTF-8",
    LANG = "en_US.UTF-8" 
 are supported and installed on your system. 
perl: warning: Falling back to the standard locale ("C").
```

Такая ошибка лечится простой командой по переопределению локалей:

```bash
sudo locale-gen ru_RU ru_RU.UTF-8 en_US en_US.UTF-8
```

На этом все!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
