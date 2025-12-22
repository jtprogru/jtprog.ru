---
categories: ["Work"]
cover:
  alt: work
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: work.png
  relative: false
date: "2021-04-07T22:31:31+03:00"
tags:
- bitrix
- bitrixvm
- hosting
- nginx
- migration
- backup
- restore
- ssl
- letsencrypt
- certbot
- gzip
- troubleshooting
title: '[Work] Перенос сайта на хостинг с BitrixVM'
type: post
description: "Подробная инструкция по переносу сайта на хостинг с BitrixVM: резервное копирование, восстановление, настройка SSL-сертификата Let's Encrypt с Certbot и решение распространенной проблемы с gzip в Nginx."
keywords: ["перенос сайта bitrix", "хостинг bitrixvm", "миграция bitrix", "резервное копирование bitrix", "восстановление bitrix", "ssl bitrix", "lets encrypt certbot", "настройка nginx gzip", "bitrix troubleshooting", "bitrixvm инструкция"]
---

Привет, `%username%`! У многих хостинг-провайдеров есть тарифные планы для тех "малышей", кому хочется ~~свой бизнес~~ интернет-магазин. Данный тариф представляет из себя максимально минимальную по характеристикам VM с предустановленной CMS Bitrix – стандартное коробочное решение поставляемое авторами данного продукта в виде готовой BitrixVM.

## Задача

Изначально задача звучит довольно просто: перенести готовый сайтик с одного сервера (stage) на другой (prod). Доменное имя уже куплено, хостинг оплачен, доступы везде есть - надо делать.

## Как переносим

Сама процедура выглядит довольно просто. Собственно для полноценного переноса с такими вводными необходимо сделать следующее:

1. Открыть админку битрикса на stage;
2. Перейти в `Настройки` -> `Инструменты` -> `Резервное копирование`;
3. Создать полную копию сайта со всей статикой и включая БД;
4. Скачать полученный(е) архив(ы) себе;
5. Открыть в браузере Битрикс на новом хостинге;
6. В установщике выбрать восстановление из бэкапа и следовать инструкциям;

Это все очень просто, а сложности начинаются потом. Мы убеждаемся в том, что сайт открылся по IP-адресу и работает. Настраиваем vhosts в nginx и проверяем, что сайт открывается корректно по HTTP. После чего мы можем спокойно приступить к настройке SSL-сертификата от Let'sEncrypt – тут все просто, т.к. `certbot` наше всё.

## Ставим `certbot`

Установка `certbot` максимально скучна.

```bash
cd /usr/local/sbin
sudo wget https://dl.eff.org/certbot-auto
```

Дадим боту права на исполнение:

```bash
sudo chmod a+x /usr/local/sbin/certbot-auto
```

Для получения сертификата необходимо выполнить команду с вызовом Certbot'a с определенными параметрами:

```bash
certbot-auto certonly --webroot --agree-tos --email admin@jtprog-magazine.ru -w /home/bitrix/www/ -d jtprog-magazine.ru -d www.jtprog-magazine.ru
```

Где:

- `--webroot` — специальный ключ, повышающий надежность работы Certbot под Nginx;
- `--agree-tos` — автоматическое согласие с Условиями предоставления услуг (Terms of Services);
- `--email admin@jtprog-magazine.ru` — Ваш e-mail. Важно, его нельзя изменить, он требуется для восстановления доступа к домену и для его продления;
- `-w /home/bitrix/www` — указываем корневую директорию сайта основного сайта;
- `-d jtprog-magazine.ru` — через ключ `-d` мы указываем, для каких доменов мы запрашиваем сертификат. Начинать надо c домена второго уровня `jtprog-magazine.ru` и через такой же ключ указывать поддомены, например, `-d www.jtprog-magazine.ru -d lk.jtprog-magazine.ru`;

Скрипт Certbot начнет свою работу, предложит установить дополнительные пакеты – соглашаешься и ждёшь окончания работы.

Конфиги nginx стоит поправить самостоятельно. В файле `/etc/nginx/bx/conf/ssl.conf` правим параметры:

```bash
ssl_certificate     /etc/letsencrypt/live/jtprog-magazine.ru/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/jtprog-magazine.ru/privkey.pem;
```

## Проблемы

Разработчиками/клиентом выполняется проверка сайта на корректность – все кнопочки на местах, админка на месте, картинки правильные и на местах все, навигация работает корректно. Выявляется, что "каталог товаров и категории не работают" – любая категория в браузере открывается с ошибкой:

```bash
‌Can not decode raw data: NSURLErrorDomain: Cannot decode raw data=-1015
```

А в консоли мы видим примерно такой вывод (я пользуюсь [`httpie`](https://httpie.io)):

```bash
https https://jtprog-magazine.ru/catalog/zip-shtory/ --verbose
GET /catalog/zip-shtory/ HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Host: jtprog-magazine.ru
User-Agent: HTTPie/2.4.0



HTTP/1.1 200 OK
Cache-Control: no-store, no-cache, must-revalidate
Connection: keep-alive
Content-Encoding: gzip
Content-Type: text/html; charset=UTF-8
Date: Wed, 07 Apr 2021 16:45:56 GMT
Expires: Thu, 19 Nov 1981 08:52:00 GMT
P3P: policyref="/bitrix/p3p.xml", CP="NON DSP COR CUR ADM DEV PSA PSD OUR UNR BUS UNI COM NAV INT DEM STA"
Pragma: no-cache
Server: nginx/1.16.1
Set-Cookie: PHPSESSID=4p1novjplogou1nee9llqwert5; path=/; HttpOnly
Set-Cookie: CURRENT_CITY=%25D0%25B0; expires=Thu, 07-Apr-2022 22:34:42 GMT; Max-Age=31556926; path=/
Set-Cookie: BITRIX_SM_rover_geoip=somefkngshit; expires=Wed, 14-Apr-2021 16:45:56 GMT; Max-Age=604800; path=/; HttpOnly
Transfer-Encoding: chunked
Vary: HTTPS
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-Powered-By: PHP/7.2.34
X-Powered-CMS: Bitrix Site Manager (651ca9fa6ad144b900fef86e26831111)


http: error: ContentDecodingError: ('Received response with content-encoding: gzip, but failed to decode it.', error('Error -3 while decompressing data: incorrect header check'))
```

И видя такое впервые в жизни ты начинаешь думать, что косяк в настройках `gzip`. Только есть шанс уйти не туда: в дефолтной BitrixVM, которая работает на базе CentOS 7, запускается `httpd` вместо ожидаемого `php-fpm`. Может возникнуть желание поковырять настройки `httpd`, потому что "ну nginx-то работает как калаш" – не делайте этого.

Короче идем в настройки Nginx и выставляем вот такие настройки для `gzip` в файле `/etc/nginx/nginx.conf`:

```bash
gzip on;
gzip_disable "MSIE [1-6]\.";

gzip_vary on;
gzip_min_length 10240;
gzip_proxied any;
gzip_comp_level 5;
gzip_buffers 16 8k;
gzip_http_version 1.1;
gzip_types text/plain text/css application/json application/x-javascript application/javascript text/xml application/xml application/xml+rss text/javascript;
```

После чего смело делаем:

```bash
sudo nginx -t
sudo nginx -s reload
```

И наслаждаемся жизнью... Profit!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". 
