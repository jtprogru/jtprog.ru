---
title: "[PostgreSQL] Работаем руками"
date: 2018-07-12T16:15:04+03:00
draft: false
slug: '/psql-cli/'
categories: "DevOps"
tags: ['postgres', 'pgsql', 'cli']
comments: true
noauthor: false
share: true
type: "post"
---

Привет, `%username%`! Иногда бывает необходимо поработать ручками с базой данных PostgreSQL, но не для всех бывает очевидно что и как там делать. Поэтому ниже будет список из нескольких полезных примеров команд, которые помогу быстро разобраться и начать. Главное помнить: не тестируйте на production-серверах!

Начнем с простого, а именно коннекта к базе данных PostgreSQL под самым главным пользователем `postgres`:
```bash
psql -U postgres -p SecretPassword
```
После этой команды нас встретит приветствие PostgreSQL. Далее мы вольны делать абсолютно всё (в пределах разумного). Для начала посмотрим список всех баз данных которые у нас крутятся на сервере. Делается это следующим образом:
```sql
postgres=# \l
```

или
```sql
postgres=# \list
```

На вывод нам поступит список всех БД которые созданы на сервере, после чего мы можем подключиться к нужной нам базе и работать с ней - для примера посмотрим все таблицы в ней:
```sql
postgres=# \connect testdb 
testdb=# \dt
```

Как можно догадаться из примера - до знака решетки (`#`) у нас будет наименование базы данных с которой мы сейчас работаем. Подключившись к базе `testdb` мы посмотрели все таблицы в этой БД. Далее мы можем посмотреть самую большую таблицу в БД:
```sql
SELECT relname AS "table_name", relpages AS "size_in_pages" FROM pg_class ORDER BY relapses DESC LIMIT 1;
```

В результате нам будет показана самая большая таблица (размер указывается в страницах):

| table_name | size_in_pages |
| :---|:---------------|
| testtb1 | 299211 |

Следующий вопрос: как посмотреть размер все базы данных. Ответ - легко:
```sql
SELECT pg_database_size( 'testdb' );
```

В результате нам покажется размер всей БД:

| pg_database_size |
|:---:|
| 27641546936 |


И снова размер нам представлен в непонятном виде, но мы можем легко это исправить следующим образом:
```sql
SELECT pg_size_pretty( pg_database_size( 'testdb' ) );
```

Результат:

| pg_size_pretty |
|:---:|
|26 GB|

Логичным продолжением будет просмотр всех БД в таком нормально виде:
```sql
SELECT pg_database.datname as "database_name", pg_size_pretty(pg_database_size(pg_database.datname)) as size FROM pg_database ORDER by pg_database_size(pg_database.datname) DESC;
```

Результат:

| database_name | size|
|:---|---:|
|sampledb | 45 GB|
|loremdb_001 | 21 GB|
| ipsumdb | 3358 MB |

Посмотрим размер таблицы в базе данных:
```sql
SELECT pg_size_pretty( pg_total_relation_size( 'testtb1' ) );
```

Результатом будет размер таблицы `testtable1`, включая индексы. Результат будет отображен сразу в удобном для чтения формате, а не в байтах.

|pg_size_pretty|
|:---:|
|4872 MB |

Если вам нужно узнать размер таблицы без индексов, тогда следует выполнить такой запрос:
```sql
SELECT pg_size_pretty( pg_relation_size( 'testtb1' ) );
```

Результат:

| pg_size_pretty |
|:---:|
| 2338 MB |

Как узнать текущую версию сервера PostgreSQL?
```sql
SELECT version();
```

Результат будет подобным этому:

| version |
|:---:|
| PostgreSQL 9.3.1 on x86_64-unknown-linux-gnu, compiled by gcc (Debian 4.7.2-5) 4.7.2, 64-bit|

Как выполнить SQL-файл в PostgreSQL?  

Для данной цели существует специальная команда в консольной утилите:
```sql
\i /path/to/file.sql
```

Где `/path/to/file.sql` — это путь к вашему SQL-файлу. Обратите внимание, что он должен лежать в доступной для чтения пользователя `postgres` директории.

Как показать структуру, индексы и прочие элементы выбранной таблицы в PostgreSQL?  
Для данной цели существует специальная команда в консольной утилите:
```sql
\d testtb1
```
Где `testtb1` — имя таблицы  
Результат:

|Table "public.testtb1" |||
|---|---|---|
|Column|Type| Modifiers|
|begin_ip | ip4 | not null|
|end_ip | ip4 | not null|
|begin_num | bigint | not null|
| end_num | bigint | not null|
| country_code | character(2) | not null|
| country_name | character varying(255) | not null|
| ip_range | ip4r ||
| Indexes: |||
|"testtable1_iprange_index" gist (ip_range) WITH (fillfactor=100)|||
|||

Как отобразить время выполнения запроса в консольной утилите PostgreSQL?
```sql
\timing
```

После чего все запросы станут отображаться в консольной утилите со временем выполнения.  
Отключаются эти уведомления точно так же, как и включаются — вызовом:
```sql
\timing
```

Как отобразить все команды консольной утилиты PostgreSQL?
```sql
\?
```
Это наверное самый важный пункт, т.к. любой `DBA` должен знать как вызвать эту справку! Далее будет несколько примеров более сложных запросов, которые так же могу предоставить ту или иную информацию. Например для сопоставления `OID` номеров и имен баз и таблиц в `contrib` есть утилита `oid2name`.

Для просмотра размера таблиц для текущей базы:
```sql
SELECT relname AS name, relfilenode AS oid, (relpages * 8192 / (1024*1024))::int as size_mb, reltuples as count FROM pg_class WHERE relname NOT LIKE 'pg%' ORDER BY relpages DESC;
```

Для просмотра общего размера баз можно использовать скрипт:
```bash
#!/bin/sh
oid2name=/usr/local/pgsql/bin/oid2name
pg_data_path=/usr/local/pgsql/data/base 
{
	$oid2name| grep '='| while read oid delim name; do
		size=`du -s $pg_data_path/$oid|cut -f1` 
		echo "$size $name"
	done
}|sort -rn
```

Если нужно без индексов, тогда запрос другой:
```sql
SELECT pg_size_pretty( pg_relation_size( 'table' ) ); 
```
|pg_size_pretty|
|:---:|
|1341 MB|

Полный размер таблицы и сопутствующих индексов:
```sql
SELECT pg_total_relation_size('table_name');
```

Размер столбцов:
```sql
SELECT pg_column_size('column_name') FROM 'testtb1';
```

Состояние всех настроек можно посмотреть через функцию `pg_show_all_settings()`.

Думаю на этом можно пока притормозить. На первое время хватит и этих данных. На этом всё!
