---
title: '[DevOps] Партицирование таблиц в PostgreSQL'
description: "Пошаговое руководство по секционированию больших таблиц в PostgreSQL с использованием триггеров, наследования и управления последовательностями"
keywords:
  - postgres партицирование
  - секционирование таблиц
  - оптимизация postgres
  - триггеры postgresql
  - управление большими данными
date: "2018-07-16T16:27:55+03:00"
lastmod: "2018-07-16T16:27:55+03:00"
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

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". 
