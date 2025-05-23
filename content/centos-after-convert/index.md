---
categories: OS
cover:
  alt: OS
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: OS.png
  relative: false
date: "2018-09-25T12:12:00+03:00"
tags:
- centos
- converter
- vmware
- boot
- grub
- network
- networking
- troubleshooting
- virtualization
- vmware converter
title: '[OS] Исправляем работу конвертера'
type: post
description: "Руководство по устранению проблем с загрузчиком Grub и сетевыми интерфейсами в виртуальной машине CentOS после конвертации с помощью VMware Center Converter Standalone."
keywords: ["centos vmware converter", "ошибки загрузки centos", "проблемы сети centos", "исправление grub", "настройка сети linux", "vmware troubleshooting", "виртуализация centos", "конвертация виртуальных машин", "сетевые интерфейсы linux"]
---

Привет, `%username%`! Сейчас мы будем исправлять [последствия работы](https://jtprog.ru/error-converter-standalone/) VMware Center Converter Standalone на клоне. Если не знаешь, то можно только угадать. Нас ждут проблемы с загрузкой и сетевыми интерфейсами. Исправляется все очень просто.

##### Проблемы загрузки

Первое что нам необходимо сделать перед включением свежей виртуальной машины, это отключить в её настройках сетевой интерфейс. После отключения сетевого интерфейса смело включаем нашу виртуалку и продолжаем эротическую эпопею. После того как вы включили вашу виртуозку, можете открыть консоль (которая через клиент VMware) и вполне вероятно, что вы увидите сообщение (простите - не заскринил) о том, что ваш загрузчик Grub не может выполнить команду `:`. Да, именно двоеточие. Дело в том, что при конвертации VMware имеет прямой рутовый доступ к системе и вносит некоторые необходимые изменения для корректной работы *новой системы*. Для исправления этого косяка необходимо открыть файл:

```bash
vim /boot/grub2/grub.cfg
```

И удалить оттуда все строки начинающиеся на с двоеточия, а их там может быть не мало. После чего сохранить все изменения и всё. Готово!

##### Проблемы сетевых интерфейсов

В работе с сетевыми интерфейсами так же всё относительно просто. Для начала, на моем физическом сервере (с которого снимался клон) присутствовало два сетевых интерфейса объединенных в `team0`-интерфейс. А на виртуальном сервере (на целевом) мне необходим был только один интерфейс, о чем я конвертеру и сообщил при конвертации. Поскольку при конвертации все сетевые интерфейсы, включая `team0`, остались в системе, мне необходимо было это исправить и заставить работать через единственный интерфейс. На удивление все получилось довольно просто. Я удалил файлы конфигурации лишних интерфейсов (включая `team0`) и проверил как оно работает. И работает отлично. Для конфигурирования сетевых интерфейсов пришлось воспользоваться утилитой `nmtui` и обычным текстовым редактором `vim`.

Через утилиту `nmtui` мы удаляем лишние сетевые интерфейсы из системы, а с помощью `vim` мы вносим правильные настройки в нужный нам сетевой интерфейс. Можно воспользоваться и одной утилитой, но через `nmtui` ИМХО удаление интерфейсов происходит более корректно по отношению к системе, потому что *`NetworkManager`* там стоит по дефолту и пытается рулить всей сетью.

Собственно на этом всё. Как видно всё оказалось не так страшно как казалось ;)

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
