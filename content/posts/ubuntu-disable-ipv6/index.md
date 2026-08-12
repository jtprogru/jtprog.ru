---
aliases:
  - '/ubuntu-disable-ipv6/'
categories: ["HowTo"]
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: howto.png
  relative: false
date: "2016-08-12T11:54:00+03:00"
lastmod: "2016-08-12T11:54:00+03:00"
tags:
- ipv6
- linux
- ubuntu
- сетевые настройки
- sysctl
title: 'Отключаем IPv6 на сервере'
type: post
description: "Пошаговая инструкция по отключению IPv6 в Ubuntu Server через редактирование sysctl.conf."
keywords:
  - "отключение IPv6 Ubuntu"
  - "настройка сети Linux"
  - "sysctl.conf параметры"
  - "net.ipv6.conf.all.disable_ipv6"
  - "Ubuntu Server 16.04"
  - "проверка отключения IPv6"
---

Возникла потребность отключить использование IPv6 на одном из серверов под управлением Ubuntu Server 16.04.1. Задача довольно простая и легко выполнима в несколько команд. Необходим только доступ к серверу и выполнение команд от имени root'а.

Делается это следующим образом. Логинимся на сервер по `ssh` и получаем `root`.

```bash
ssh -p 22 user@server.example.com
sudo -s
```

Далее открываем в своем любимом редакторе файл `/etc/sysctl.conf`:

```bash
vim /etc/sysctl.conf
```

и в самом конце файла пишем следующие строки:

```bash
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
```

После этого сохраняем изменения и примиряем их для всей системы:

```bash
sysctl -p
```

Результатом выполнения последней команды должен быть вывод в терминал этих строк:

```bash
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
```

Далее, чтобы убедиться что все хорошо выполним:

```bash
cat /proc/sys/net/ipv6/conf/all/disable_ipv6
```

И в терминале нам покажется единичка:

```bash
1
```

Это говорит о том, что все сделано правильно.

Остальные параметры ядра, которые обычно правят там же, — в [«Настройка Linux для HL и защиты от DDoS»](/posts/sysctl-hl/). А типичный симптом, из-за которого IPv6 и выключают, — [Postfix, который ломится наружу по v6](/posts/postfix-ipv4/).

На этом все! Profit!
