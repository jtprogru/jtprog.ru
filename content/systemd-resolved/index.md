---
title: '[Work] Настройка systemd-resolved'
description: 'Пошаговая инструкция по настройке systemd-resolved в Linux: кэширование DNS, интеграция с NSS, настройка /etc/resolv.conf и запуск службы.'
keywords: ['systemd-resolved настройка', 'linux dns cache', 'systemd resolved', 'nss-resolve', 'systemd-resolved конфиг', 'linux dns', 'systemd-resolved инструкция']
date: "2020-11-29T12:00:00+03:00"
lastmod: "2020-11-29T12:00:00+03:00"
tags:
- systemd
- resolved
- systemd-resolved
categories: [Work]
cover:
  image: work.png
  alt: work
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  relative: false
type: post
slug: systemd-resolved
---

Привет, `%username%`! Очень давно я писал о том, как я настраивал [dnsmasq](https://jtprog.ru/domain-zone-dnsmasq/) для настройки локальной зоны. Сейчас мы настроим `systemd-resolved` как локальный кэширующий резолвер.

Его настройку я рассматриваю только потому, что `systemd-resolved` есть в системе (в нормальной свежей системе с systemd).

Для начала установим модуль `nss-resolve` (библиотека `libnss_resolve.so` из пакета `libnss-resolve`) для механизма **Name Service Switch** (`NSS`), который будет вызывать службу `systemd-resolved` для разрешения имён:

```bash
sudo apt install libnss-resolve
```

Установка данного модуля приведет к изменению в файле `/etc/nsswitch.conf`  – строка `hosts: files dns` будет автоматически заменена на следующую:

```ini
...
hosts:          files resolve [!UNAVAIL=return] dns
...
```

Теперь приступим к настройке самого `systemd-resolved`. Содержимое файла `/etc/systemd/resolved.conf` приводим к следующему виду:

```ini
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.
#
# Entries in this file show the compile time defaults.
# You can change settings by editing this file.
# Defaults can be restored by simply deleting this file.
#
# See resolved.conf(5) for details

[Resolve]
DNS=10.20.213.10 10.20.213.20
FallbackDNS=1.1.1.1 8.8.8.8 8.8.4.4
Domains=jtprog.ru jtprog.local
LLMNR=yes
#MulticastDNS=no
#DNSSEC=no
#DNSOverTLS=no
Cache=no-negative
#DNSStubListener=yes
ReadEtcHosts=yes
```

Сделаем магию для совместимости с приложениями, которые не используют библиотечные вызовы, а обращаются к DNS-серверам напрямую, получая их из `/etc/resolv.conf`. Создадим символическую ссылку на файл `/run/systemd/resolve/resolv.conf`, контент которого автоматически генерируется исходя из настроек, заданных нами в `/etc/systemd/resolved.conf`:

```bash
sudo ln -svi /run/systemd/resolve/resolv.conf /etc/resolv.conf
ln: replace '/etc/resolv.conf'? y
'/etc/resolv.conf' -> '/run/systemd/resolve/resolv.conf'
```

Теперь запускаем службу и включаем автозапуск:

```bash
systemctl enable systemd-resolved
systemctl restart systemd-resolved
systemctl status systemd-resolved
```

На этом всё! Profit!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
