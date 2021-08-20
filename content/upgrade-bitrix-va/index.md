---
title: "[Work] Обновление Bitrix VA"
date: 2021-08-20T22:47:51+03:00
categories: "Work"
tags: ["bitrix", "work"]
type: "post"
author: "jtprogru"
showToc: false
TocOpen: false
draft: false
hidemeta: false
disableShare: true
cover:
    image: "cover.jpg"
    alt: "Bitrix"
    caption: "Bitrix управление сайтом"
    relative: false
comments: false
---

Привет, `%username%`! Это старая заметка о процедуре обновления Bitrix VA до версии PHP 7.4. Но вдруг кому-то будет полезно, так что пусть тут живет.

Процедура обновления Bitrix Virtual Appliance на базе CentOS 7 выполняется согласно штатному обновлению ОС CentOS 7, а так же согласно штатному обновлению PHP до версии 7.4.

Перед выполнением всех работ необходимо создать Snapshot средствами системы виртуализации для обеспечения возможности отката в случае возникновения ошибок.
Для обновления PHP до версии 7.4 необходимо выполнить команды:

```shell
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://rpms.remirepo.net/enterprise/remi-release-7.rpm
```

Данные пакеты могут быть уже установлены. Дальше нам необходимо включить репозиторий содержащий PHP 7.4 в файле `/etc/yum.repos.d/remi-php74.repo`:

```ini
[remi-php74]
name=Remi's PHP 7.4 RPM repository for Enterprise Linux 7 - $basearch
#baseurl=http://rpms.remirepo.net/enterprise/7/php74/$basearch/
#mirrorlist=https://rpms.remirepo.net/enterprise/7/php74/httpsmirror
mirrorlist=http://cdn.remirepo.net/enterprise/7/php74/mirror
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-remi

[remi-php74-debuginfo]
name=Remi's PHP 7.4 RPM repository for Enterprise Linux 7 - $basearch - debuginfo
baseurl=http://rpms.remirepo.net/enterprise/7/debug-php74/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-remi

[remi-php74-test]
name=Remi's PHP 7.4 test RPM repository for Enterprise Linux 7 - $basearch
#baseurl=http://rpms.remirepo.net/enterprise/7/test74/$basearch/
#mirrorlist=https://rpms.remirepo.net/enterprise/7/test74/httpsmirror
mirrorlist=http://cdn.remirepo.net/enterprise/7/test74/mirror
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-remi

[remi-php74-test-debuginfo]
name=Remi's PHP 7.4 test RPM repository for Enterprise Linux 7 - $basearch - debuginfo
baseurl=http://rpms.remirepo.net/enterprise/7/debug-test74/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-remi
```

Дальше выполняем стандартное обновление системы:

```shell
yum update -y && yum clean all
```

После обновления всех пакетов, необходимо выполнить перезапуск демона отвечающего за исполнение скриптов PHP – в нашем случае это Apache:

```shell
systemctl reload httpd.service
```

Так же необходимо внести правки в конфигурацию MySQL в соответствии с требованиями Bitrix24. В файл `my.cnf` необходимо добавить параметр:

```ini
innodb_strict_mode=OFF
```

Данный параметр либо отсутствует в конфигурационном файле, либо присутствует с дефолтным значением ON. После внесения правок с MySQL его необходимо перезапустить. Для корректного перезапуска использовать следующие скрипты.

Скрипт проверки конфигурации:

```shell
cat /usr/local/bin/mysqlconfigtest.sh
#!/bin/bash
set -eo pipefail
mysqld --help 2> >( grep -v "starting as" 1>&2 ) > /dev/null
```

Скрипт непосредственно перезапуска демона MySQL:

```shell
cat /usr/local/bin/mysqlreload.sh
#!/bin/bash
set -eo pipefail
/usr/local/bin/mysqlconfigtest.sh && (sleep 1; /usr/bin/systemctl restart mysqld)
```

После всех процедур обновления пакетов желательно (но не обязательно) выполнить полный перезапуск системы для загрузки с новой версией ядра – новое ядро будет установлено вместе со всеми пакетами во время обновления. Так же необходимо проверить работоспособность всех сервисов через административную панель Bitrix24.

---
Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://t.me/jtprogru_chat), а так же подписывайся на [канал](https://t.me/jtprogru_channel).
