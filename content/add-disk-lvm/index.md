---
title: '[OS] Добавляем диск в lvm без перезагрузки виртуальной машины'
description: "Пошаговая инструкция по добавлению нового диска в LVM на CentOS без перезагрузки виртуальной машины: создание раздела, добавление в volume group и расширение файловой системы."
keywords: ["CentOS", "LVM", "добавить диск", "расширение раздела", "виртуальная машина", "fdisk", "vgextend", "lvextend", "resize2fs", "Linux"]
date: "2018-07-18T12:29:00+03:00"
lastmod: "2018-07-18T12:29:00+03:00"
tags:
  - centos
  - lvm
  - disks
categories: ["OS"]
cover:
  image: OS.png
  alt: OS
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  relative: false
type: post
slug: 'add-disk-lvm'
---

Привет, `%username%`! Есть такая непередаваемая боль, как "заканчивается место на разделе". Давайте рассмотрим как это провернуть на боевом сервере без остановки/перезагрузки и вообще сделаем красиво. Сразу скажу, что тут ничего сложного и с этим сможет справиться любой.

Немного вводной информации для понимания. Есть виртуальная машина на базе CentOS с дисковым пространством на 6.5ТБ (несколько дисков которые лежат на СХД). ОС установлена на LVM. Есть группа дисков огромным объёмом для хранения загружаемых пользователями файлов. Задача стоит такая: расширить раздел для пользовательских загрузок.

Приступим к самому простому варианту. Добавим диск и расширим volume group. Для начала надо подключиться к vCentre/vSphere Client и добавить новый диск (не буду показывать как это делается, потому что это просто). Далее после добавления диска в виртуальную машину нам надо заставить увидеть её этот новый диск. Провреяем сколько у нас сейчас свободного места на разделах:

```bash
df -h
```

После посмотрим какие диски присутствуют в системе:

```bash
fdisk -l
```

Заставим виртуалку просканировать устройства:

```bash
ls -la /sys/class/scsi_host/
echo - - - > /sys/class/scsi_host/host0/scan
echo - - - > /sys/class/scsi_host/host1/scan
echo - - - > /sys/class/scsi_host/host2/scan
echo - - - > /sys/class/scsi_host/host3/scan
```

Количество `host#` у вас может отличаться - у меня их четыре как видно из примера выше. Далее проверяем как называется наш новый диск и появился ли он вообще:

```bash
fdisk -l
```

Далее мы добавляем на наш новый диск раздел (у меня это пусть будет *sdd*):

```bash
# fdisk /dev/sdd
```

Теперь перед нами консольная утилита для работы с дисками. Помощь вызывается по команде `m`. Мы же набираем команду `p` для просмотра текущих настроек диска. Потом добавляем новый раздел на диск командой `n`, после чего соглашаемся со всеми дефолтными значениями. Так же мы можем выбрать тип диска `Linux LVM` используя команду `t` или оставить по дефолту всё как есть. И закончив все настройки запишем их на диск командой `w`.

Теперь можно и расширять дисковое пространство, вот таким образом:

```bash
pvdisplay
pvcreate /dev/sdd1
pvdisplay
```

Посмотрели на диски и увидели какой куда подключен. Далее посмотрим список volume group:

```bash
vgs
```

Посмотрели список volume group и выбрали тот который нам нужен. Теперь добавляем туда наш диск и расширяем объём на размер этого диска:

```bash
vgextend scan_volume /dev/sdd1
lvextend -l+100%FREE /dev/scan_volume/lv
resize2fs /dev/scan_volume/lv
df -h
```

Посмотрев на результаты скромного труда можем довольные налить чаю и отдохнуть. На этом всё!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
