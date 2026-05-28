---
aliases:
  - '/partitioning/'
title: 'Партицирование таблиц в PostgreSQL'
description: "Пошаговое руководство по секционированию больших таблиц в PostgreSQL с использованием триггеров, наследования и управления последовательностями"
keywords:
  - postgres партицирование
  - секционирование таблиц
  - оптимизация postgres
  - триггеры postgresql
  - управление большими данными
  - declarative partitioning
  - partition by range
  - partition by hash
  - pg_partman
  - partition pruning
  - partition-wise joins
date: "2018-07-16T16:27:55+03:00"
lastmod: "2026-05-15T20:00:00+03:00"
tags:
  - postgres
  - pgsql
  - linux
categories: ["DevOps"]
cover:
  image: devops.png
  alt: devops
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  relative: false
type: post
slug: 'partitioning'
---

Привет, `%username%`! Мне понадобилось на работе заняться партицированием одной из таблиц в БД у заказчика. Не буду рассказывать о том, почему именно я выбрал партиционирование т.к. по этому вопросу и так много информации в сети Интернет. Далее в статье будет немного о том, как делается партицирование (секционирование).

> 🔄 **Обновлено 2026-05-15**: схема ниже через `INHERITS` + триггеры — это **legacy-подход**, который работал до PostgreSQL 10. На современных версиях (PG 10+) есть нативное **декларативное партицирование** через `PARTITION BY` — оно проще, быстрее, лучше планировщиком оптимизируется и не требует триггеров вовсе. Старый текст оставлен для тех, кто поддерживает легаси-инсталляции с PG 9.x. Если ты пилишь это с нуля сегодня — иди сразу в раздел [«Декларативное партицирование (PG 16/17)»](#декларативное-партицирование-pg-1617) в конце поста.
>
> Также: `WITH (OIDS=FALSE)` в исходных DDL — с PG 12 (октябрь 2019) этот синтаксис уже **выдаёт ошибку**. OIDs из обычных таблиц вырезали, эти строки нужно просто удалить.

Для начала определимся с понятиями:

> Партицирование (*partitioning*) - это разбиение больших таблиц на логические части по выбранным критериям. Партиционированные или секционированные таблицы призваны улучшить производительнос и управляемость базами данных.

Вроде бы всё понятно. Осталось только понять как разбить таблицу на секции или партиции? В PostgreSQL эта процедура потребует небольших усилий, но оно того стоит!

Представим, что у нас есть таблица (`db.item_pulse`), которая за день может вырасти на несколько сотен тысяч строк (за месяц несколько миллионов). Логичным действием по оптимизации является разбиение на секции. Для упрощения будем дробить по дням (управлять в моем случае так будет немного проще).

Структура у таблицы пусть будет такая:

```sql
CREATE TABLE item_pulse ( "item_p_id" integer NOT NULL, "date" timestamp without tome zone NOT NULL DEFAULT now(), "user_ip" cidr NOT NULL ) WITH ( OIDS=FALSE );
```

Для пониманиия: `ad_id` - это уникальный `ID`, `date` - дата и время сбора метки, `user_ip` - IP-адрес запроса. На этом я думаю хватит для примера, но в реальности количество полей может быть огромным.

Далее нам необходимо создать триггер, который будет срабатывать на каждую вставку в таблицу и создавать новую партицию при необходимости.

Пусть наш триггер будет выглядеть вот таким образом:

```sql
CREATE OR REPLAE FUNCTION item_pulse_insert_trigger() RETURNS trigger AS $BODY$ DECLARE table_master varchar(255) := 'item_pulse'; 
table_part varchar(255) := ''; 
BEGIN 
    -- Даём имя партиции -------------------------------------------------- 
    table_part := table_master || '_y' || date_part( 'year', NEW.date )::text || '_m' || date_part( 'month', NEW.date )::text || '_d' || date_part( 'day', NEW.date )::text; 
    -- Проверяем партицию на существование -------------------------------- 
    PERFORM 1 FROM pg_class WHERE relname = table_part LIMIT 1; 
    -- Если её ещё нет, то создаём -------------------------------------------- 
    IF NOT FOUND THEN 
        -- Cоздаём партицию, наследуя мастер-таблицу -------------------------- 
        EXECUTE ' CREATE TABLE ' || table_part || ' ( ) INHERITS ( ' || table_master || ' ) WITH ( OIDS=FALSE )'; 
        -- Создаём индексы для текущей партиции ------------------------------- 
        EXECUTE ' CREATE INDEX ' || table_part || '_adid_date_index ON ' || table_part || ' USING btree (item_p_id, date)'; 
    END IF;
-- Вставляем данные в партицию -------------------------------------------- 
    EXECUTE ' INSERT INTO ' || table_part || ' SELECT ( (' || quote_literal(NEW) || ')::' || TG_RELNAME || ' ).*'; 
    RETURN NULL; 
END; 
$BODY$ LANGUAGE plpgsql VOLATILE COST 100;
```

Привязываем созданный нами триггер к таблице:

```sql
CREATE TRIGGER item_pulse_insert_triger BEFORE INSERT ON item_pulse FOR EACH ROW EXECUTE PROCEDURE item_pulse_insert_trigger();
```

Теперь таблицы будут создаваться вот такого вида `item_pulse_y<год>_m<месяц>_d<день>` (пример: `item_pulse_y2018_m07_d16`).

В случае если ваши таблици, которые вы собираетесь секциониорвать содержат уникальный `ID`, то его стоит указывать в каждой партиции с указанием `nextval()` от `sequence` мастер-таблицы.

Пусть `sequence` будет описан таким образом:

```sql
CREATE SEQUENCE item_pulse_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 1 CACHE 1;
```

В таком случае в триггере следует написать вот так:

```sql
... 
-- создаём партицию, наследуя мастер-таблицу -------------------------- 
EXECUTE ' CREATE TABLE ' || table_part || ' ( id bigint NOT NULL DEFAULT nextval(''' || table_master || '_id_seq''::regclass), CONSTRAINT ' || table_part || '_id_pk PRIMARY KEY (id) ) INHERITS ( ' || table_master || ' ) WITH ( OIDS=FALSE )';
...
```

А в мастер-таблице в таком случае `id` стоит описать вот так:

```sql
CREATE TABLE item_pulse ( id bigserial NOT NULL, ... CONSTRAINT item_pulse_id_pk PRIMARY KEY (id) ) WITH ( OIDS=FALSE )
```

Вот собственно и всё! На этом имеет смысл завершить.

## Декларативное партицирование (PG 16/17)

В PG 10 (октябрь 2017) завезли нативную декларативную систему партицирования — `PARTITION BY RANGE/LIST/HASH`. Дальше она от релиза к релизу обрастала плюшками: hash-партиционирование, default-партиция, partition pruning во время выполнения, attach/detach concurrently, partition-wise joins, partition-wise aggregates. К 2026-му её можно считать единственным разумным путём.

### Базовый синтаксис: RANGE

Та же таблица `item_pulse`, что в исходнике, но через декларативное:

```sql
CREATE TABLE item_pulse (
    item_p_id  bigserial,
    date       timestamptz NOT NULL DEFAULT now(),
    user_ip    cidr        NOT NULL,
    PRIMARY KEY (item_p_id, date)
) PARTITION BY RANGE (date);
```

Несколько важных нюансов:

- В **первичный ключ** должен входить ключ партицирования (`date`). Без этого PostgreSQL не даст создать PK на партицированной таблице.
- `WITH (OIDS=FALSE)` больше не нужен и не работает.
- `timestamp without time zone` я бы заменил на `timestamptz` — у него меньше граблей с таймзонами клиентов.

Создаём первую партицию:

```sql
CREATE TABLE item_pulse_2026_05
    PARTITION OF item_pulse
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

CREATE INDEX ON item_pulse_2026_05 (item_p_id, date);
```

Никаких триггеров — `INSERT` в `item_pulse` сам уедет в нужную партицию по значению `date`. Если значение не попадает ни в одну партицию, по умолчанию `INSERT` упадёт. Чтобы этого не было — default-партиция:

```sql
CREATE TABLE item_pulse_default
    PARTITION OF item_pulse DEFAULT;
```

В default обычно ничего держать не хотят (она съест partition pruning по всему диапазону), но для отлова «не туда воткнули» полезно.

### LIST и HASH

`LIST` — когда ключ партицирования имеет конечный набор значений (страны, типы событий):

```sql
CREATE TABLE events (
    id bigserial, event_type text, payload jsonb
) PARTITION BY LIST (event_type);

CREATE TABLE events_signup PARTITION OF events FOR VALUES IN ('signup');
CREATE TABLE events_login  PARTITION OF events FOR VALUES IN ('login');
CREATE TABLE events_other  PARTITION OF events DEFAULT;
```

`HASH` (с PG 11) — когда нужно ровное распределение по N бакетам без естественного ключа диапазона:

```sql
CREATE TABLE users (
    id bigserial, email text, created_at timestamptz
) PARTITION BY HASH (id);

CREATE TABLE users_p0 PARTITION OF users FOR VALUES WITH (modulus 8, remainder 0);
CREATE TABLE users_p1 PARTITION OF users FOR VALUES WITH (modulus 8, remainder 1);
-- ... до remainder 7
```

HASH полезен для шардирования нагрузки по диску — но не даёт partition pruning по диапазону, только по точному `WHERE id = ...`.

### pg_partman — автоматизация

Создавать партиции по расписанию руками лень. [pg_partman](https://github.com/pgpartman/pg_partman) — расширение, которое делает это за тебя:

```sql
CREATE EXTENSION pg_partman;

SELECT partman.create_parent(
    p_parent_table => 'public.item_pulse',
    p_control      => 'date',
    p_type         => 'native',
    p_interval     => 'daily',
    p_premake      => 7        -- держать 7 дней наперёд
);
```

Дальше отдельный фоновый job (`run_maintenance_proc()` или внешний cron/Patroni-таймер) каждый день создаёт новые партиции и опционально удаляет старые. Это де-факто стандарт для time-series-данных в PostgreSQL, если ты не хочешь TimescaleDB.

### Partition pruning

Главная польза партицирования — планировщик отрезает партиции, которые точно не нужны для запроса:

```sql
EXPLAIN SELECT * FROM item_pulse WHERE date >= '2026-05-10' AND date < '2026-05-12';
-- В плане: Append → Seq Scan на item_pulse_2026_05, остальные пропущены
```

С PG 11 это работает и **во время выполнения** (`enable_partition_pruning = on` по умолчанию) — то есть параметризованные запросы с `WHERE date = $1` тоже эффективно режут партиции.

### Partition-wise joins и aggregates

С PG 11 (но по умолчанию **выключены**) есть [partition-wise joins](https://www.postgresql.org/docs/current/runtime-config-query.html#GUC-ENABLE-PARTITIONWISE-JOIN) — когда обе таблицы партиционированы одинаково, join делается **попартиционно**, а не «склей всё → джойни». На больших данных может ускорять в разы. Включается в сессии или в `postgresql.conf`:

```sql
SET enable_partitionwise_join = on;
SET enable_partitionwise_aggregate = on;
```

Платится памятью при планировании (рост `work_mem` × число партиций), так что для маленьких баз эффект может быть обратный — мерь.

### Что ещё стоит знать

- **`ATTACH ... CONCURRENTLY`** (с PG 12) — присоединение/отсоединение партиций без полной блокировки. На проде это критично.
- **Foreign keys между партиционированными таблицами** — стабильно работают с PG 12.
- **Глобальный индекс** через всю партицированную таблицу — **до сих пор не сделан**. Каждый индекс физически создаётся на каждой партиции. Это нужно учитывать при операциях `CREATE INDEX` (используй `... CONCURRENTLY`).
- **TimescaleDB** — отдельное расширение, которое строит свою иерархию hypertable+chunk поверх partitioning. Если основной кейс — time-series, и хочется compression, continuous aggregates и retention-политики «из коробки» — посмотри в его сторону.

### TL;DR апдейта

Если ты сегодня делаешь partitioning в PG 14+:

1. Никаких `INHERITS` + триггеров. Только `PARTITION BY`.
2. Ключ партицирования — в PK таблицы.
3. Для time-series — `pg_partman` или TimescaleDB вместо ручных скриптов.
4. Проверь, что `enable_partition_pruning = on` (дефолт), и попробуй включить `partitionwise_join`/`partitionwise_aggregate` под свой workload.

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". 
