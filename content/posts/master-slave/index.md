---
aliases:
  - '/master-slave/'
title: 'Репликация Master-Slave'
description: "Пошаговая настройка Master-Slave репликации в MySQL с использованием Percona XtraDB на Ubuntu: конфигурация серверов, резервное копирование и управление репликацией."
keywords:
  - "MySQL репликация"
  - "Master-Slave настройка"
  - "Source-Replica настройка"
  - "Percona XtraDB"
  - "Ubuntu MySQL"
  - "xtrabackup"
  - "настройка my.cnf"
  - "CHANGE MASTER"
  - "CHANGE REPLICATION SOURCE"
  - "SHOW SLAVE STATUS"
  - "SHOW REPLICA STATUS"
  - "GTID"
  - "MySQL InnoDB Cluster"
  - "PostgreSQL logical replication"
  - "Patroni"
  - "восстановление бэкапа"
date: "2020-04-01T23:55:00+03:00"
lastmod: "2026-05-15T20:00:00+03:00"
tags:
  - mysql
  - replication
  - howto
  - "администрирование БД"
categories: ["HowTo"]
cover:
  image: howto.png
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  relative: false
type: post
slug: "master-slave"
---

Привет, `%username%`! Тут я рассмотрю настройку репликации master-slave в БД MySQL. Процесс установки всех необходимых пакетов не вижу смысла описывать, т.к. подобное можно прочитать в документации. Упомяну лишь то, что в моем случае стоит Percona XtraDB 5.7 на Ubuntu 16.04.

> 🔄 **Обновлено 2026-05-15**: Терминология `master/slave` в индустрии сменилась на `source/replica` (MySQL) и `primary/standby` (PostgreSQL). SQL-команды `CHANGE MASTER TO` / `START SLAVE` / `SHOW SLAVE STATUS` deprecated с MySQL 8.0.22 (октябрь 2020) в пользу `CHANGE REPLICATION SOURCE TO` / `START REPLICA` / `SHOW REPLICA STATUS`. Инструкцию ниже не переписываю — она работает на Percona/MySQL 5.7 как историческая. В конце добавил раздел про то, как репликация устроена сейчас.

В моей конфигурации изначально была Galera, которую мне необходимо было выпилить. Для выпиливания необходимо из файла `/etc/mysql/my.cnf` удалить все упоминания переменных начинающихся на `wsrep_` и корректно перезапустить демон `mysql`. Для упрощения схемы представим, что у нас `master` имеет IP `192.168.99.20`, а будущий `slave` имеет IP `192.168.99.30`

## **Настройка мастера**

Правим `/etc/mysql/my.cnf` на master-сервере и приводим его примерно к такому виду:

```bash
[client]
port                            = 3306
socket                          = /var/run/mysqld/mysqld.sock
default-character-set           = utf8

[mysqld_safe]
socket                          = /var/run/mysqld/mysqld.sock
nice                            = 0

[mysqldump]
quote-names
max_allowed_packet              = 128M

[isamchk]
key_buffer                      = 16M

[mysqld]
skip-character-set-client-handshake
skip-external-locking
skip-name-resolve
innodb-autoinc-lock-mode        = 1
user                            = mysql
default-storage-engine          = InnoDB
socket                          = /var/run/mysqld/mysqld.sock
server-id                       = 1
bind-address                    = 0.0.0.0
port                            = 3306
tmpdir                          = /mnt/ramdisk
explicit-defaults-for-timestamp = 1
basedir                         = /usr
lc-messages-dir                 = /usr/share/mysql
character-set-server            = utf8
collation-server                = utf8_unicode_ci
net-write-timeout               = 600
wait-timeout                    = 300
interactive-timeout             = 3600
default-time-zone               = SYSTEM
thread-stack                    = 192K
sort-buffer-size                = 8M
read-rnd-buffer-size            = 4M
read-buffer-size                = 4M
join-buffer-size                = 32M

# MyISAM #
key-buffer-size                 = 128M
myisam-recover-options          = FORCE,BACKUP

# SAFETY #
max-allowed-packet              = 16M
max-connect-errors              = 1000000
sql-mode                        = ""
sysdate-is-now                  = 1
innodb                          = FORCE

# DATA STORAGE #
datadir                         = /var/lib/mysql

# BINARY LOGGING #
log-bin                         = /var/lib/mysql/mysql-bin
expire-logs-days                = 14
sync-binlog                     = 1

# REPLICATION #
binlog-format                   = mixed
binlog-checksum                 = crc32
log-slave-updates               = true

# CACHES AND LIMITS #
tmp-table-size                  = 2G
max-heap-table-size             = 2G
query-cache-type                = 0
query-cache-size                = 8M
max-connections                 = 500
thread-cache-size               = 1025
open-files-limit                = 2000000
table-definition-cache          = 8192
table-open-cache                = 8192


# INNODB #
innodb-file-per-table
innodb-flush-method             = O_DIRECT
innodb-log-files-in-group       = 2
innodb-log-file-size            = 512M
innodb-log-buffer-size          = 64M
innodb-flush-log-at-trx-commit  = 2
innodb-flush-neighbors          = 0
innodb-file-per-table           = 1
innodb-buffer-pool-size         = 2G
innodb-buffer-pool-instances    = 32

# LOGGING #
log-error                       = /var/lib/mysql/mysql-error.log
slow-query-log                  = 1
slow-query-log-file             = /var/lib/mysql/mysql-slow.log
long-query-time                 = 4
log-timestamps                  = SYSTEM

# CUSTOM #
event_scheduler                 = on
group_concat_max_len            = 30000
log_timestamps                  = SYSTEM
log_bin_trust_function_creators = 1
optimizer-search-depth           = 0
transaction-isolation           = READ-COMMITTED

pid-file                        = /var/run/mysql/mysql.pid
symbolic-links                  = 0

[sst]
progress                        = 1
time                            = 1
rlimit                          = 200m
```

> **Важно**! При копировании этого конфига учитывайте параметры своей системы - есть шанс сделать хуже, чем было! За подробностями в google и официальную документацию.

Рестартуем `mysql`:

```bash
systemctl restart mysql
```

Даем права на репликацю для пользователя `repl`:

```sql
GRANT REPLICATION SLAVE ON *.*  TO 'repl'@'192.168.99.20' IDENTIFIED BY 'pAssw0rd';
```

На мастере делаем бэкап с помощью `xtrabackup`:

```bash
#!/bin/bash
PASSWORD="rootpassword"
# Снимаем бэкап
xtrabackup --backup --user=root --password=${PASSWORD} --target-dir=/root/backupdb/ --slave-info
# Догоняем его до актуального состояния
xtrabackup --user=root --password=${PASSWORD}  --prepare --target-dir=/root/backupdb/ --slave-info
```

## Подготовка

Копируем на слейв бэкап БД и файл `/etc/my.cnf`:

```bash
rsync -avpP -e ssh /root/backupdb/ root@192.168.99.30:/root/backupdb/
scp /etc/my.cnf root@192.168.99.30:/etc/mysql/my.cnf
```

Правим на слэйве в файле `/etc/mysql/my.cnf` параметр `server-id` - он должен быть отличным от мастера:

```bash
server-id                      = 2
```

Идем на слейв и останавливаем `mysql`:

```bash
mysqladmin -u root -p shutdown all
```

Вычищаем старую базу:

```bash
rm -rf /var/lib/mysql/*
```

Копируем новую, скопированную с мастера и применяем права и стартуем слейв:

```bash
innobackupex --defaults-file=/etc/mysql/my.cnf --copy-back /root/backupdb/
chown -R mysql:mysql /var/lib/mysql
systemctl restart mysql
```

> **Важно**: Тут используется флаг `--copy-back` - данные из директории с бэкапом не удаляются. Если вам необходимо перенести данные, то используйте флаг `--move-back` - будет выполнен перенос данных.

## Включение

Теперь подключим репликацию. Смотримпозицию на слейве в файле:

```bash
cat /root/backupdb/xtrabackup_binlog_info
```

Видим что-то типа такого:

```sql
mysql-bin.000007    456
```

Заходим в консоль `mysql` и подключаем репликацию:

```sql
CHANGE MASTER TO MASTER_HOST='192.168.99.20', MASTER_USER='repl', MASTER_PASSWORD='repl', MASTER_LOG_FILE='mysql-bin.000007', MASTER_LOG_POS=456;
START SLAVE;
```

В моём случае отключены `GTID`, но если вы всё же их включите то команду можно ввести такую:

```sql
CHANGE MASTER TO MASTER_HOST='192.168.99.20', MASTER_USER='repl', MASTER_PASSWORD='repl', MASTER_AUTO_POSITION=1;
```

Смотрим статус:

```sql
SHOW SLAVE STATUS;
```

> **Важно**: В случае возникновения ошибки `1236` смотреть статью [тут](https://rtfm.co.ua/mysqlmariadb-репликация-fatal-error-1236/)

```sql
STOP SLAVE;
change master to MASTER_LOG_POS=456;
CHANGE MASTER TO MASTER_LOG_FILE = 'mysql-bin.000007';
START SLAVE;
SHOW SLAVE STATUS;
```

## Как репликация устроена сейчас (2026)

Инструкция выше работает, но она про конкретный кейс 2020-го года: Percona 5.7, ручная настройка binlog-позиции, выпиливание Galera. Если ты только начинаешь и не привязан к легаси — вот что надо знать.

### Терминология

С 2020 года индустрия (включая MySQL, MariaDB, PostgreSQL, Redis, MongoDB) перешла на нейтральные термины:

| Старое | Новое |
|--------|-------|
| master | source (MySQL) / primary (PostgreSQL, Redis) |
| slave | replica (MySQL) / standby (PostgreSQL) / secondary (MongoDB) |
| master-slave replication | source-replica replication |

Старая терминология ещё встречается в legacy-конфигах и старой документации — понимать обе версии полезно.

### MySQL 8.x: новые SQL-команды

Начиная с MySQL 8.0.22 (октябрь 2020) команды переименованы, старые остались как алиасы с пометкой `deprecated`:

| Старое | Новое |
|--------|-------|
| `CHANGE MASTER TO MASTER_HOST=…` | `CHANGE REPLICATION SOURCE TO SOURCE_HOST=…` |
| `START SLAVE` | `START REPLICA` |
| `STOP SLAVE` | `STOP REPLICA` |
| `SHOW SLAVE STATUS` | `SHOW REPLICA STATUS` |
| `RESET SLAVE` | `RESET REPLICA` |

GTID (Global Transaction Identifier) стал де-факто стандартом для новых инсталляций — позиционная репликация через `binlog file + position` (как в инструкции выше) применяется реже.

### MySQL InnoDB Cluster и Group Replication

Для production в 2026-м обычная пара «один source + один replica» — это минимум. Чаще встретишь:

- **Group Replication** — multi-source репликация с автоматическим failover. До 9 нод в группе, синхронная репликация в кворуме.
- **InnoDB Cluster** — готовая обвязка из MySQL Server + Group Replication + MySQL Router + AdminAPI. Поднимается через `dba.createCluster()` в `mysqlsh`.
- **MySQL Operator for Kubernetes** — если живёшь в k8s, кластер поднимается манифестом.

Для proxying/sharding обычно ставят перед кластером **ProxySQL**, для координации failover — **Orchestrator**.

### PostgreSQL: logical replication и Patroni

В PostgreSQL ландшафт развивался параллельно:

- **Streaming replication** (с PG 9.0) — аналог классической MySQL-репликации, primary шлёт WAL на standby.
- **Logical replication** (с PG 10, стабильна с PG 14, мейнстрим с PG 16/17) — реплицировать можно отдельные таблицы, отдельные схемы, между разными мажорными версиями. Бесценно для миграций без даунтайма.
- **[Patroni](https://github.com/patroni/patroni)** — стандартная production-обвязка для HA: etcd/consul для consensus, автоматический failover, REST API для health-чеков.
- **[pgBouncer](https://www.pgbouncer.org/)** — connection pooler, обязателен для любой более-менее нагруженной инсталляции.
- **[pg_auto_failover](https://github.com/citusdata/pg_auto_failover)** — альтернатива Patroni с отдельным monitor-узлом.

В Kubernetes для PG живёт несколько операторов: **CloudNativePG**, **Zalando Postgres Operator**, **Crunchy Postgres Operator**.

### Что менять в инструкции выше, если повторяешь её на свежей MySQL 8.x

Минимальные правки в SQL-командах:

```sql
-- Создание пользователя для репликации
CREATE USER 'repl'@'%' IDENTIFIED BY 'pAssw0rd';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';

-- Подключение реплики
CHANGE REPLICATION SOURCE TO
    SOURCE_HOST = '192.168.99.20',
    SOURCE_USER = 'repl',
    SOURCE_PASSWORD = 'pAssw0rd',
    SOURCE_AUTO_POSITION = 1;   -- GTID
START REPLICA;

-- Мониторинг
SHOW REPLICA STATUS\G
```

И не забудь в `my.cnf` включить GTID: `gtid_mode = ON` и `enforce_gtid_consistency = ON` на обеих нодах перед стартом.

### TL;DR апдейта

Терминология сменилась — `source/replica` или `primary/standby`. Для MySQL новых установок используй GTID + `CHANGE REPLICATION SOURCE TO`. Для production смотри в сторону **InnoDB Cluster** (MySQL) или **Patroni + CloudNativePG** (PostgreSQL), а не вручную поднятой пары. Один-в-один по позиционным binlog'ам в 2026-м — это либо легаси, либо очень специфический кейс.

На этом всё! Улыбаемся и пашем!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". 
