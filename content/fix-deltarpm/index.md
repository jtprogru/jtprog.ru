---
title: "[CentOS] Delta RPMs disabled"
date: 2019-08-05T12:24:55+03:00
draft: false
slug: '/fix-deltarpm/'
description: 'Устранение ошибки Delta RPMs disabled в CentOS'
categories: "howto"
tags: ['centos', 'yum', 'deltarpm']
comments: true
noauthor: false
share: true
type: "post"
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
