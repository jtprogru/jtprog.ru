---
categories: howto
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: howto.png
  relative: false
date: "2020-04-09T01:30:00+03:00"
tags:
- haproxy
- centos
- howto
title: '[HowTo] Установка HAProxy на Centos 8'
type: post
---
Привет, `%username%`! Тут мы будем устанавливать свежую стабильную версию `HAProxy` из исходников, т.к. в репах доступна еще 1.8.15.

Чтобы скомпилировать `HAProxy`, нужно будет убедиться, что установлено несколько пакетов из стандартных репозиториев. Один из необходимых пакетов находится в репе `PowerTools`. Включить данный репозиторий можно так:

```bash
dnf config-manager --enable PowerTools
```

После чего нам необходимо установить набор обязательных утилит, которые потребуются при сборке из исходников:

```bash
dnf install gcc openssl-devel readline-devel systemd-devel make pcre-devel tar lua lua-devel
```

Далее идем на официальный [сайт](https://www.haproxy.org) и узнаём последний стабильный релиз, копируем ссылку на архив и скачиваем. В моём случае (*на момент написания этих строк*) последний стабильный `2.1.4`:

```bash
wget http://www.haproxy.org/download/2.1/src/haproxy-2.1.4.tar.gz -O ~/haproxy.tar.gz
```

Распаковываем и переходим в директорию с исходниками:

```bash
tar xzvf ~/haproxy.tar.gz -C ~/
cd haproxy-2.1.4/
```

Далее компилируем и устанавливаем:

```bash
make USE_NS=1 USE_TFO=1 \
USE_OPENSSL=1 USE_ZLIB=1 \
USE_LUA=1 USE_PCRE=1 \
USE_SYSTEMD=1 USE_LIBCRYPT=1 \
USE_THREAD=1 TARGET=linux-glibc \
EXTRA_OBJS="contrib/prometheus-exporter/service-prometheus.o"
make install
```

Создаем пользователя под которым будет запускаться демон `HAProxy`:

```bash
groupadd -g 992 haproxy
useradd -g 992 -u 995 -m -d /var/lib/haproxy -s /sbin/nologin -c haproxy haproxy
```

Теперь нам необходимо создать `SystemD Unit` файл для корректного запуска демона:

```bash
cat /etc/systemd/system/haproxy.service
[Unit]
Description=HAProxy
After=syslog.target network.target

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/haproxy
ExecStart=/usr/local/sbin/haproxy -f $CONFIG_FILE -p $PID_FILE $CLI_OPTIONS
ExecReload=/bin/kill -USR2 $MAINPID
ExecStop=/bin/kill -USR1 $MAINPID

[Install]
WantedBy=multi-user.target
```

Сигнал `USR2` дает команду `HAProxy` перезагрузить свою конфигурацию, не приводя ее в действие. Сигнал `USR1` позволяет процессам закончить то, что они делали до выхода.

Теперь нам необходимо создать environment-файл для HAProxy:

```bash
cat /etc/sysconfig/haproxy
CLI_OPTIONS="-Ws"
CONFIG_FILE=/etc/haproxy/haproxy.cfg
PID_FILE=/var/run/haproxy.pid 
```

Параметр `-Ws` запускает `HAProxy` в режиме, в котором он может уведомить `SystemD`, когда он будет запущен.

После этого необходимо попросить `SystemD` перечитать информацию о демонах:

```bash
systemctl daemon-reload
```

Подготавливаем конфигурацию для `HAProxy`:

```bash
cat /etc/haproxy/haproxy.cfg
global
    daemon
    maxconn 256
    user        haproxy
    group       haproxy
    chroot      /var/lib/haproxy

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend http
    bind *:8000
    default_backend servers

backend servers
    server server 127.0.0.1:81
```

Теперь запускаем `HAProxy` и включаем в автозапуск:

```bash
systemctl start haproxy.service
systemctl enable haproxy.service
```

Так же не забудьте про `firewall-cmd` и открытие портов:

```bash
firewall-cmd --permanent --zone=public --add-port=8000/tcp
firewall-cmd --reload
```

На этом всё! Profit!

> **UPD**: Поправил параметры сборки, для того, чтобы свежесбилженый HAProxy включил поддержку Prometheus

---
Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).
