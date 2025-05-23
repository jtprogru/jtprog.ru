---
title: '[HowTo] Настройка memcached в Битрикс'
description: "Инструкция по интеграции memcached в Битрикс для кэширования данных: редактирование конфигурационных файлов, проверка работоспособности и оптимизация производительности."
keywords:
  - "Битрикс memcached"
  - "кэширование данных"
  - "настройка кэша"
  - "BX_CACHE_TYPE"
  - "CPHPCache"
  - "bitrix/.settings.php"
  - "оптимизация сайта"
  - "панель производительности"
  - "PHP кэширование"
date: "2020-01-13T19:48:58+03:00"
lastmod: "2020-01-13T19:48:58+03:00"
tags:
  - bitrix
  - memcached
  - "оптимизация"
  - "веб-разработка"
categories:
  - HowTo
cover:
  image: howto.png
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  relative: false
type: post
slug: "memcached-bitrix"
---

Привет, `%username%`! Немного поговорим о том, что такое `memcached` и как его включить для Битрикса.

`Memcached` - это программное обеспечение, которое используется для кэширования данных, требующих при генерации большого количества ресурсов; к примеру, запрос к базе данных. Использование `memcached` позволяет при помощи оптимизации повысить производительность, а значит, уменьшить время отклика сервера для того, чтобы страницы сайта загружались быстрее.

Принцип действия прост: в оперативной памяти сервера, который доступен по сетевому протоколу,  хранятся определенные данные, доступ к которым осуществляется через ключ или имя. Поэтому `memcached` иногда определяют как хэш-таблицу, которая используется для кэширования страничного кода, результатов запросов к базам данных и так далее.

Как правило, данную технологию советуют использовать на нагруженных проектах, поэтому она используется на таких крупных ресурсах, как Wikipedia, Facebook и других.

В `bitrix/php_interface/dbconn.php` добавляем:

```php
define("BX_CACHE_TYPE", "memcache");
define("BX_CACHE_SID", $_SERVER["DOCUMENT_ROOT"]."#логин");
define("BX_MEMCACHE_HOST", "127.0.0.1");
define("BX_MEMCACHE_PORT", "11211");
```

В `bitrix/.settings.php` добавляем:

```php
'cache' => array(
    'value' => array(
        'type' => 'memcache',
        'memcache' => array(
            'host' => '127.0.0.1',
            'port' => '11211',
        ),
        'sid' => $_SERVER["DOCUMENT_ROOT"]."#логин"
    ),
    'readonly' => false,
),
```

Либо создаем в `bitrix/.settings_extra.php` и добавляем:

```php
return array (
  'cache' => array(
     'value' => array (
        'type' => 'memcache',
        'memcache' => array(
            'host' => '127.0.0.1',
            'port' => '11211'
        ),
        'sid' => $_SERVER["DOCUMENT_ROOT"]."#логин"
     ),
  ),
);
```

Скрипт для проверки работоспособности:

```php
require($_SERVER["DOCUMENT_ROOT"]."/bitrix/modules/main/include/prolog_before.php");
$cache = new CPHPCache();
if ($cache->InitCache(3600, '12356356gt' , '/' )) {
    echo "cache";
    $res = $cache->GetVars();
    $arResult = $res['arResult'];
} elseif ($cache->StartDataCache()) {
    echo "no cache";
    $arResult = array(1,2,3,4,5);
    $cache->EndDataCache(array("arResult" => $arResult));
}
```

Также пройдя `Рабочий стол` -> `Настройки` -> `Производительность` -> `Панель производительности`, во вкладке `Битрикс (оптимально)`, в пункте `Хранение кеша` должен быть указан `memcache`.

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
