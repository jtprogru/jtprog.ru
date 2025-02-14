---
categories: howto
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: howto.png
  relative: false
date: "2020-08-14T17:42:54+03:00"
tags:
- mysql
- max connections
- linux
title: '[HowTo] Максимальное количество коннектов'
type: post
---
Привет, `%username%`! Рано или поздно при работе с MySQL возникает ошибка `too many connections`. Пофиксить ее можно легко и даже без перезапуска сервиса, изменив всего один параметр - `max_connections`, тем самым увеличив количество разрешенных коннектов.

По умолчанию параметр `max_connections` установлен в `100` - это его дефолтное значение даже если он не указан в конфигурационном файле MySQL. Посмотреть текущее значение данного параметра можно просто подключившись в консоль `mysql` и выполив одну из следующих команд:

```sql
show variables like "max_connections";
# or
select @@max_connections;
```

Вывод данной команды будет примерно такой (дефолтные значение `mysql`):

```sql
+-----------------+-------+
| Variable_name   | Value |
+-----------------+-------+
| max_connections | 100   |
+-----------------+-------+
```

Поднять значение например до `500` можно следующим образом: запустить консоль `mysql` например от пользователя `root` и выполнить следующую команду:

```sql
set global max_connections = 500;
```

Изменения вступят в силу незамедлительно, но автоматически сбросятся при следующем перезапуске MySQL. Для включения на постоянной основе данного параметра необходимо отредактировать конфигурационный файл `my.cnf`. В CentOS/RedHat он расположен в `/etc/my.cnf`.

Под секцией `[mysqld]` добавьте следующую строку:

```sql
max_connections = 500;
```

Теперь при следующем перезапуске MySQL данный параметр будет считан из конфигурационного файла. На этом всё! Profit!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
