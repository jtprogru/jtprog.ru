---
categories: howto
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: howto.png
  relative: false
date: "2020-07-10T02:00:00+03:00"
tags:
- zabbix
- ubuntu
- monitoring
- zbx
title: '[HowTo] Установка Zabbix 5.0 на Ubuntu 20.04'
type: post
---
Привет, `%username%`! Данная статья - обычный пересказ официальной документации [Zabbix](https://www.zabbix.com/download?zabbix=5.0&os_distribution=ubuntu&os_version=20.04_focal&db=postgresql&ws=nginx) и не содержит в себе ничего магического. Да и процесс установки уже мною освещался ранее на [CentOS](https://jtprog.ru/install-zabbix-centos/) и [Ubuntu](https://jtprog.ru/install-zabbix-ubuntu/).

Ставить буду максимально свежую версию (на момент написания статьи) Zabbix на такую же свежую Ubuntu Server 20.04.

> **ВАЖНО**! Все дальнейшие действия на сервере выполняются из под учетной записи `root`.

## Добавление Zabbix репозитория

Предполагается, что установка выполняется на чистую систему, поэтому для начала обновим текущие пакеты в системе.

```bash
apt update
apt upgrade -y
```

Добавим репозиторий Zabbix и обновим информацию о доступных пакетах:

```bash
wget https://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.0-1+focal_all.deb
dpkg -i zabbix-release_5.0-1+focal_all.deb
apt update
```

## Установка Zabbix-server

Я буду ставить Zabbix для PostgreSQL, потому что так удобно мне. Так же сразу ставим Nginx и WEB-интерфейс для

```bash
apt install zabbix-server-pgsql zabbix-frontend-php php7.2-pgsql zabbix-nginx-conf zabbix-agent -y
```

## Готовим PostgreSQL

Для начала создадим пользователя:

```bash
sudo -u postgres createuser --pwprompt zabbix
```

Нас попросят дважды ввести пароль для нового пользователя `zabbix` - собственно говоря вводим дважды одно и тоже и всё. Далее создадим базу, которую будет использовать Zabbix:

```bash
sudo -u postgres createdb -O zabbix -E Unicode -T template0 zabbix
```

Выполним подготовку базы для Zabbix - создадим необходимые таблицы:

```bash
zcat /usr/share/doc/zabbix-server-pgsql/create.sql.gz | sudo -u zabbix psql zabbix
```

## Настройка Zabbix-server

После всех вышеописанных процедур необходимо указать Zabbix-server'у с какой БД он работает и как к ней подключиться. Делается это просто - в файле `/etc/zabbix/zabbix_server.conf` необходимо отредактировать следующие параметры:

```ini
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=zabbix
```

> ВАЖНО! В конфигурационном файле пароль для доступа к БД хранится в открытом виде в параметре `DBPassword`

## Запуск

Предварительно проверяем настройки для Nginx в этом файлике `/etc/zabbix/nginx.conf`. Правим там `listen` и `server_name`. А так же не забываем указать часовой пояс в этом файлике `/etc/zabbix/php-fpm.conf`

Следующим этапом запускаем Zabbix-server, Nginx, PHP-FPM (он поставился автоматически).

```bash
sudo systemctl restart zabbix-server zabbix-agent nginx php7.4-fpm
sudo systemctl enable zabbix-server zabbix-agent nginx php7.4-fpm
```

Далее идем в любой доступный браузер и настраиваем через WEB-UI, всё что требуется настроить – добавляем хосты/группы/шаблоны и всё то, ради чего это затевалось.

## WEB-UI

Собственно говоря тут все просто. Открываем наш сервер по DNS/IP - в зависимости от того, как настроили, в браузере и - Next->Next->Next =)

Дальше нам доступен стандартный пользователь для входа в web-интерфейс с логином `Admin` и паролем `zabbix`. Собственно входим в web-ui и пользуемся как можем.

## Итог

Теперь необходимо настроить авторизацию по LDAP – но там всё очень просто. На это всё!

---
Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).
