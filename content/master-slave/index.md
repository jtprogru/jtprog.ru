---
authorbox: true
categories: OS
comments: true
date: "2020-04-01T23:55:00+03:00"
description: Настройка репликации master-slave на прмиере MySQL 5.7
draft: false
image: ""
lastmod: "2020-04-02T00:00:00+03:00"
share: true
slug: /master-slave/
tags:
- mysql
- replication
- howto
title: '[MySQL] Репликация Master-Slave'
toc: false
type: post
---
Привет, `%username%`! Тут я рассмотрю настройку репликации master-slave в БД MySQL. Процесс установки всех необходимых пакетов не вижу смысла описывать, т.к. подобное можно прочитать в документации. Упомяну лишь то, что в моем случае стоит Percona XtraDB 5.7 на Ubuntu 16.04. 

В моей конфигурации изначально была Galera, которую мне необходимо было выпилить. Для выпиливания необходимо из файла `/etc/mysql/my.cnf` удалить все упоминания переменных начинающихся на `wsrep_` и корректно перезапустить демон `mysql`. Для упрощения схемы представим, что у нас `master` имеет IP `192.168.99.20`, а будущий `slave` имеет IP `192.168.99.30`

#### **Настройка мастера**

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
max_allowed_packet		        = 128M

[isamchk]
key_buffer			            = 16M

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
collation-server		        = utf8_unicode_ci
net-write-timeout		        = 600
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
innodb-flush-neighbors	        = 0
innodb-file-per-table           = 1
innodb-buffer-pool-size         = 2G
innodb-buffer-pool-instances    = 32

# LOGGING #
log-error                       = /var/lib/mysql/mysql-error.log
slow-query-log                  = 1
slow-query-log-file             = /var/lib/mysql/mysql-slow.log
long-query-time                 = 4
log-timestamps			        = SYSTEM

# CUSTOM #
event_scheduler                 = on
group_concat_max_len            = 30000
log_timestamps                  = SYSTEM
log_bin_trust_function_creators = 1
optimizer-search-depth	        = 0
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

#### **Подготовка**

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
> **Важно**:  
> Тут используется флаг `--copy-back` - данные из директории с бэкапом не удаляются. Если вам необходимо перенести данные, то используйте флаг `--move-back` - будет выполнен перенос данных. 

#### **Включение**

Теперь подключим репликацию. Смотримпозицию на слейве в файле:
```bash
cat /root/backupdb/xtrabackup_binlog_info
```

Видим что-то типа такого:
```sql
mysql-bin.000007	456
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

> **Важно**:  
> В случае возникновения ошибки `1236` смотреть статью [тут](https://rtfm.co.ua/mysqlmariadb-репликация-fatal-error-1236/)

```sql
STOP SLAVE;
change master to MASTER_LOG_POS=456;
CHANGE MASTER TO MASTER_LOG_FILE = 'mysql-bin.000007';
START SLAVE;
SHOW SLAVE STATUS;
```
На этом всё! Улыбаемся и пашем!
