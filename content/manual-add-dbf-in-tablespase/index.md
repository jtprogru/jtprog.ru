---
categories: howto
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/dreamwolf97d61e)'
  image: howto.png
  relative: false
date: "2017-11-21T17:26:35+03:00"
tags:
- oracledb
- centos
- orcl_data
title: '[HowTo] Ручное добавление файлов данных в табличной пространство в CentOS 7'
type: post
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
