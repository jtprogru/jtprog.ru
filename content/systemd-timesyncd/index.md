---
title: "[Linux] Настраиваем systemd-timesyncd"
date: 2020-11-27T20:20:00+03:00
categories: 'Work'
tags: ["systemd", "timesyncd"]
type: 'post'
author: "jtprogru"
description: "Настройка штатного механизма синхронизации времени systemd-timesyncd"
showToc: false
TocOpen: false
draft: false
hidemeta: false
disableShare: false
# cover:
#     image: "<image path/url>"
#     alt: "<alt text>"
#     caption: "<text>"
#     relative: false
comments: false
---

Привет, `%username%`! Для синхронизации времени в Linux традиционно используется `ntpd` как стандарт де-факто, но есть альтернатива в виде `systemd-timesyncd`. Посмотрим как оно настраивается и включается, а `ntpd` забудем и удалим.

С `ntpd` все довольно просто: ставится пакет `ntp`, настраивается файл конфигурации `/etc/ntp.conf` и включается служба через `systemctl start ntp`, далее с помощью утилиты `ntpstat` проверяем синхронизацию локальных часов с удаленным сервером. 

Стоит так же заметить, что с помощью `ntpd` можно еще и выступать в качестве сервера времени для других. То есть `ntpd` принимает входящие соединения и если его некорректно настроить, то он может стать участником DDoS-атаки (см. [NTP amplification attack (CVE-2013-5211)](https://blog.programs74.ru/how-to-use-systemd-timesyncd/#)).

Во всех дистрибутивах с `systemd` есть встроенная альтернатива `ntpd` — `systemd-timesyncd`. Так же следует дать [вот эту ссылку](https://chrony.tuxfamily.org/comparison.html), где есть детальное сравнение 3-х реализаций демонов синхронизации времени.

Удаляем лишнее:

```bash
sudo apt-get remove ntp ntpstat --purge
sudo apt autoremove
```

Обязательно следует удалить `ntpd` или `chronyd` до запуска `systemd-timesyncd` иначе последний не будет синхронизировать время, а за данную проверку отвечает файл `/lib/systemd/system/systemd-timesyncd.service.d/disable-with-time-daemon.conf` в котором прописан список бинарников, при наличии которых в системе демон `systemd-timesyncd` не будет работать.

Настроим уже `systemd-timesyncd`, а для этого в файл `/etc/systemd/timesyncd.conf` пропишем список серверов времени и приведем его к такому виду:

```bash
cat /etc/systemd/timesyncd.conf


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
# See timesyncd.conf(5) for details.

[Time]
NTP=192.168.0.11 192.168.0.12 ntp1.stratum2.ru ntp1.stratum1.ru
FallbackNTP=ntp.ubuntu.com
#RootDistanceMaxSec=5
#PollIntervalMinSec=32
#PollIntervalMaxSec=2048
```

Смотрим текущий статус синхронизации часов:

```bash
sudo timedatectl status
```

Результат:

```bash
      Local time: Fri 2020-11-27 20:22:14 MSK
  Universal time: Fri 2020-11-27 17:22:14 UTC
        RTC time: Fri 2020-11-27 17:22:14
       Time zone: Europe/Moscow (MSK, +0300)
 Network time on: yes
NTP synchronized: yes
 RTC in local TZ: no
```

В строке `NTP synchronized` может стоять `no` если синхронизация часов по `ntp` до этого не была настроена вообще или `yes`, если до этого часы синхронизировались с помощью `ntpd`.

Включаем использование `systemd-timesyncd` для синхронизации времени:

```bash
sudo timedatectl set-ntp true
```

Включаем и перезапускаем службу systemd-timesyncd:

```bash
sudo systemctl enable --now systemd-timesyncd.service
sudo systemctl restart systemd-timesyncd.service
```

Проверяем статус:

```bash
sudo systemctl status systemd-timesyncd.service

● systemd-timesyncd.service - Network Time Synchronization
   Loaded: loaded (/lib/systemd/system/systemd-timesyncd.service; enabled; vendor preset: enabled)
  Drop-In: /lib/systemd/system/systemd-timesyncd.service.d
           └─disable-with-time-daemon.conf
   Active: active (running) since Fri 2020-11-27 20:25:36 MSK; 6s ago
     Docs: man:systemd-timesyncd.service(8)
 Main PID: 7181 (systemd-timesyn)
   Status: "Synchronized to time server 192.168.0.11:123 (192.168.0.11)."
    Tasks: 2 (limit: 4915)
   Memory: 860.0K
      CPU: 37ms
   CGroup: /system.slice/systemd-timesyncd.service
           └─7181 /lib/systemd/systemd-timesyncd

Nov 27 20:25:36 mixitnew systemd[1]: Starting Network Time Synchronization...
Nov 27 20:25:36 mixitnew systemd[1]: Started Network Time Synchronization.
Nov 27 20:25:36 mixitnew systemd-timesyncd[7181]: Synchronized to time server 192.168.0.11:123 (192.168.0.11).
```

Через несколько минут можно проверить с помощью `timedatectl` состояние синхронизации:

```bash
sudo timedatectl status


      Local time: Fri 2020-11-27 20:26:33 MSK
  Universal time: Fri 2020-11-27 17:26:33 UTC
        RTC time: Fri 2020-11-27 17:26:34
       Time zone: Europe/Moscow (MSK, +0300)
 Network time on: yes
NTP synchronized: yes
 RTC in local TZ: no
```

Значение в строке `NTP synchronized` должно измениться на `yes`

Если `systemd-timesyncd` не синхронизирует часы, то прежде всего проверьте настройки межсетевого экрана на предмет разрешения исходящих подключений на `123` порт по протоколу `UDP`.

Детальную информацию о состоянии синхронизации времени можно посмотреть командой:

```bash
sudo timedatectl timesync-status
```

Утилиту `timedatectl` так же можно использовать для смены часового пояса, пример выведем список временных зон:

```bash
sudo timedatectl list-timezones
```

Установим временную зону Europe/Moscow:

```bash
sudo timedatectl set-timezone Europe/Moscow
```

Проверим:

```bash
date
```

Результат:

```bash
Fri Nov 27 20:31:52 MSK 2020
```

`MSK` свидетельствует об установке нашей зоны (`Europe/Moscow` это `UTC+03`)

На этом все! Profit!

UPD: На Ansible Galaxy есть моя ролька для автоматизации – [jtprogru.configure_timesyncd](https://galaxy.ansible.com/jtprogru/configure_timesyncd).

---
Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).
