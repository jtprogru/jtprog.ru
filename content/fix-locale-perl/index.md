---
categories: howto
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/dreamwolf97d61e)'
  image: howto.png
  relative: false
date: "2016-08-08T10:34:00+03:00"
tags:
- locale
- perl
- linux
title: '[HowTo] Fix locale Perl'
type: post
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
