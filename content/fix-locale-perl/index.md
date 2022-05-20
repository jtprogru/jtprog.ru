---
title: "[Ubuntu] Fix locale Perl"
date: 2016-08-08T10:34:00+03:00
draft: false
slug: '/fix-locale-perl/'
categories: "howto"
tags: ['locale', 'perl', 'linux']
comments: true
noauthor: false
share: true
type: "post"
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

