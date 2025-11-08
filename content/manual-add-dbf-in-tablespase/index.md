---
title: '[HowTo] Ручное добавление файлов данных в табличной пространство в CentOS 7'
description: "Руководство по добавлению файлов данных в табличное пространство ORCL_DATA в Oracle Database на CentOS 7 с использованием SQLPlus."
keywords:
  - "Oracle DB табличное пространство"
  - "добавление файлов данных Oracle"
  - "SQLPlus команды"
  - "ALTER TABLESPACE"
  - "Oracle CentOS 7"
  - "управление данными Oracle"
  - "dba_data_files"
  - "расширение табличного пространства"
  - "TEMP файлы Oracle"
date: "2017-11-21T17:26:35+03:00"
lastmod: "2017-11-21T17:26:35+03:00"
tags:
  - oracledb
  - centos
  - orcl_data
  - "администрирование БД"
categories:
  - "Базы данных"
cover:
  image: howto.png
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  relative: false
type: post
slug: "manual-add-dbf-in-tablespase"
---

Привет `%username%`! При работе с БД Oracle иногда приходится вручную добавлять файлы данных в табличное пространство `ORCL_DATA`.

Для ручного добавления файла данных в табличной пространство `ORCL_DATA` требуется подключиться к БД из командной строки через `SQLPlus` под владельцем схемы и выполнить:

Получение последнего файла с данными в `ORCL_DATA`:

```sql
select max(d.FILE_NAME) from dba_data_files d where d.TABLESPACE_NAME = 'ORCL_DATA';
```

Добавление следующего файла данных в `ORCL_DATA` (рекомендуется располагать его в папке с существующими файлами и с именем, содержащим следующий по порядку номер):

```sql
ALTER tablespace SOFI_DATA add DATAFILE '/opt/oracle/oradata/orcl/orcl_data2.dbf' SIZE 32M AUTOEXTEND ON NEXT 32M MAXSIZE unlimited;
```

Пример:

Файл как правило находиться в папке `/opt/oracle/oradata/orcl/`. Называется он: `ORCL_DATA.DBF`

При добавлении нужно указать номер нового файла: `ORCL_DATA2.DBF`, `ORCL_DATA3.DBF` и т.д.

Команда для добавления файла #2:

```sql  
ALTER tablespace SOFI_DATA add DATAFILE '/opt/oracle/oradata/orcl/orcl_data2.dbf' SIZE 32M AUTOEXTEND ON NEXT 32M MAXSIZE unlimited;
```

Делаем в терминале:

```bash
sqlplus /nolog
```

```sql
SQL> conn / as sysdba connected 
SQL> ALTER tablespace ORCL_DATA add DATAFILE '/opt/oracle/oradata/orcl/orcl_data2.dbf' SIZE 32M AUTOEXTEND ON NEXT 32M MAXSIZE unlimited; 
Tablespace altered 
SQL> ALTER tablespace SOFI_DATA add DATAFILE '/opt/oracle/oradata/orcl/orcl_data3.dbf' SIZE 32M AUTOEXTEND ON NEXT 32M MAXSIZE unlimited; 
Tablespace altered
```

В папке `/opt/oracle/oradata/orcl/` появятся файлы по порядку:

- `ORCL_DATA.DBF`
- `ORCL_DATA2.DBF`
- `ORCL_DATA3.DBF`

Если не хватит `TEMP` файлов, то следует добавить еще:

```sql
SQL> ALTER tablespace TEMP add TEMPFILE '/opt/oracle/oradata/orcl/temp02.dbf' SIZE 32M AUTOEXTEND ON NEXT 32M MAXSIZE unlimited;
```

На этом всё!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". 
