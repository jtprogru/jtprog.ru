---
categories: howto
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: howto.png
  relative: false
date: "2020-07-11T02:00:00+03:00"
tags:
- grafana
- ubuntu
- monitoring
- ldap
title: '[HowTo] Установка Grafana 7 на Ubuntu 20.04'
type: post
---
Привет, `%username%`! Немного пробежимся по типичной установке типичной [Grafana 7](https://grafana.com) на типичную [Ubuntu 20.04](https://ubuntu.com). Так же из плюшек у нас будет авторизация по `LDAP` (MS Active Directory). Собственно говоря – погнали!

## Вводные

Я буду устанавливать Grafana на свежеустановленную Ubuntu 20.04 minimal, а в качестве бэкенда для хранения всех настроек буду использовать [PostgreSQL 12](https://www.postgresql.org/about/news/1976/), т.к. в моей практике дефолтная установка Grafana с бэкендом в виде SQLite дает некоторые накладки и глюки – при количестве дашбордов более 50, веб-интерфейс начинает подтормаживать, а авторизация через LDAP падает (коннективити проверял – всё хорошо).

## Подготовка

Ставим (если у тебя по каким-то причинам еще не установлены) данные пакеты:

```bash
sudo apt-get install -y apt-transport-https
sudo apt-get install -y software-properties-common wget
```

Добавляем ключ и репозиторий Grafana:

```bash
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
```

Обновляем все пакеты и устанавливаем Grafana:

```bash
sudo apt-get update
sudo apt-get install grafana nginx
```

## Настройка

Создаем конфигурацию для Nginx (будем использовать хост `graf.jtprog.ru`), для этого создаем файл  `/etc/nginx/sites-available/graf.jtprog.ru.conf` и приводим его к следующему виду:

```bash
server {
  listen 80;
  server_name graf.jtprog.ru;
  location / {
    return 301 https://graf.jtprog.ru$request_uri;
  }
}

server {
  listen  443 ssl;
  include ssl.conf;
  server_name graf.jtprog.ru;
  access_log /var/log/nginx/grafana.access.log json;
  error_log /var/log/nginx/grafana.error.log;
  location / {
    proxy_pass http://127.0.0.1:3001;
    include proxy_params;
  }
}
```

Тут видно, что я использую SSL, настройки для которого подключаются через отдельный файл – мне так проще. Далее нам необходимо включить этот конфиг и проверить:

```bash
sudo ln -s /etc/nginx/sites-available/graf.jtprog.ru.conf /etc/nginx/sites-enabled/graf.jtprog.ru.conf
sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

## PostgreSQL

Теперь нам надо установить БД PostgreSQL 12 (она идет в дефолтных репозиториях и меня устраивает), но делать мы этого не будем – на данном сервере у меня развернут [Zabbix 5.0](/install-zabbix50/), к которому я и установил PostgreSQL. Мы же рассматрим несколько простых команд, которые необходимо выполнить для того, чтобы подружить PostgreSQL и Grafana:

```plsql
CREATE DATABASE grafana;
CREATE USER grafana WITH PASSWORD 'MySecretPassw0rd';
GRANT USAGE ON SCHEMA schema TO grafana;
GRANT SELECT ON schema.table TO grafana;
```

Мы создали схему и пользователя `grafana`.

## Grafana

Теперь настроим все, что требуется для запуска Grafana – делается это через файлик `/etc/grafana/grafana.ini`. Первое что должно быть сделано – выключена возможность регистрироваться. Для начала говорим где у нас будут логи и плагины:

```ini
[paths]
logs = /var/log/grafana
plugins = /var/lib/grafana/plugins
```

Теперь укажем на каком `IP:Port` надо слушать подключения:

```ini
[server]
http_addr = 127.0.0.1
http_port = 3001
```

Теперь, собственно, говорим что у нас есть PostgreSQL:

```ini
[database]
type = postgres
host = 127.0.0.1:5432
name = grafana
user = grafana
password = MySecretPassw0rd
```

Так же я выключаю `Gravatar`:

```ini
[security]
disable_gravatar = true
```

И запрещаю анонимный доступ:

```ini
[users]
allow_sign_up = false
```

На этом пока всё.

> **ВАЖНО**! Если сразу включить авторизацию по LDAP, то при первом входе нельзя будет сменить дефолтный пароль для пользователя `admin`, т.к. в системе (Grafana) установлен не встроенный механизм аутентификации.

## Запуск

Теперь нам надо выполнить первичный тестовый запуск для того, чтобы сменить дефолтный пароль пользователя `admin`. Выполняем:

```bash
sudo nginx -s reload
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
```

После чего идем в браузер и открываем адрес `https://graf.jtprog.ru` – короче тот, который вы настроили у себя. Логинимся в Grafana с дефолтными логином и паролем `admin`/`admin` и сразу же меняем пароль на что-то посложнее и [сгенерированное в консоли](/cli-gen-pass/).

## LDAP

Теперь собственно говоря немного магии в Windows. Вам необходимо создать пользователя в Active Directory (AD), который будет бегать на каждую авторизацию в AD и проверять имеет ли пришедший пользователь права на вход, а если имеет, то какие. Я в AD создал пользователя `grafanauser`, под которым Grafana будет ходить в AD, а так же три группы, которые будут иметь доступ в Grafana в соответствии с имеющимися в Grafana ролями – `Viwer`, `Editor`, `Admin`. После чего создаем файлик `/etc/grafana/ldap.toml` и приводим его к следующему виду:

```toml
[[servers]]
host = "192.168.0.10"
port = 389
use_ssl = false
start_tls = false
ssl_skip_verify = true
# User for access to AD grafanauser
bind_dn = "CN=grafanauser,CN=Users,DC=MYCOM,DC=local"
bind_password = "<password_for_user_gf_auth>"
search_filter = "(sAMAccountName=%s)"
search_base_dns = ["CN=Users,DC=MYCOM,DC=local"]
[servers.attributes]
name = "givenName"
surname = "sn"
username = "cn"
member_of = "memberOf"
email = "email"
[[servers.group_mappings]]
#Данный пример указывает на группу http_grafana, созданная в подразделении Users домена MYCOM.local
#Заменить на свой путь.
group_dn = "CN=grafanaviewer,CN=Users,DC=MYCOM,DC=local"
#Роль группы - может быть Admin, Editor, Viewer. Для каждой роли создается отдельный пункт [[servers.group_mappings]] используя разные группы домена.
org_role = "Viewer"
[[servers.group_mappings]]
group_dn = "CN=grafanaadmin,CN=Users,DC=MYCOM,DC=local"
org_role = "Admin"
[[servers.group_mappings]]
group_dn = "CN=grafanaeditor,CN=Users,DC=MYCOM,DC=local"
org_role = "Editor"
```

Тут мы настроили биндинг групп AD и встроенных ролей Grafana. Исходя из вышеуказанных настроек у нас в AD должно присутствовать три группы:

- `grafanaviewer` – те, кто могу просто посмотреть абсолютно все дашборды;
- `grafanaadmin` – администраторы (*спасибо Кэп*);
- `grafanaeditor` – те, кто могут редактировать дашборды, но не могут трогать глобальные настройки;

Теперь нам необходимо сказать нашей Grafana, что она должна ходить в AD за пользователями. Делается это следующим образом. В файле `/etc/grafana/grafana.ini`, указываем следующие параметры в соответствующем разделе:

```ini
[auth.ldap]
enabled = true
config_file = /etc/grafana/ldap.toml
allow_sign_up = true
; Функционал синхронизации доступен только в Enterprise лицензии
; но я включил и забыл =)
sync_cron = "0/10 * * * *"
active_sync_enabled = true
```

## Завершение

Собственно теперь нам необходимо выполнить только одно:

```bash
sudo systemctls restart grafana-server
```

После чего, идем к виндузятнику и просим добавить нужных пользователей в нужные группы.

> **ВАЖНО**! Пользователи с ролью `Viewer` могут переводить триггеры в статус `Ack`. В кейсе когда в качестве datasource используется Zabbix – такой момент имеет место быть.

На этом всё!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
