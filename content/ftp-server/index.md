---
categories: howto
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: howto.png
  relative: false
date: "2015-02-02T17:25:00+03:00"
tags:
- vsftpd
- ubuntu
- ftp
- ftp server
- installation
- configuration
- linux
- networking
- security
- file transfer
title: '[HowTo] Поднимаем FTP-сервер vsFTPd+Ubuntu 14.04'
type: post
description: "Руководство по быстрой установке и базовой настройке FTP-сервера vsFTPd на Ubuntu 14.04 для предоставления доступа локальным пользователям с разграничением прав."
keywords: ["vsftpd ubuntu 14.04", "установка ftp сервера linux", "настройка vsftpd", "ftp server configuration", "ubuntu ftp", "secure ftp", "file transfer protocol", "vsftpd configuration file", "linux networking"]
---

Давным-давно... Хотя... Короче говоря понадобился нам для рабочих нужд нормальный FTP-сервер. Долго шли к такому решению и все же приняли его. Да и вообще FTP-сервер штука полезная во многих ситуациях.

Довольно быстрый гуглеж дал понять, что самым лучшим в моей ситуации был выбор в пользу `vsFTPd`. Такой выбор основан на следующем: Во-первых, машина, на которую планируется ставить `vsFTPd` работает на базе Ubuntu 14.04 LTS (конечно же серверная); Во-вторых, отсутствие опыта поднятия FTP-сервера, а `vsFTPd` позиционируют как простое решение.

Начнем по порядку. Все действия по установке софта и работе в консоли Ubuntu  я начинаю с проверки обновлений. После чего ставлю необходимый софт.

```bash
sudo -s apt-get update && apt-get upgrade apt-get install vsftpd
```

Я всегда начнаю установку приложений с обновления системы и всех приучаю к этому. Эта привычка дает возможность держать систему в чистоте и актуальности. И вообще это полезно.

В общем почитав маны, форумы, etc, я пришел к выводу, что проще будет настроить доступ для локальных пользователей, ограничив им права доступа. Выбор пал в сторону локальных пользователей по двум причинам: Первое, это проще; Второе, круг доступа лиц абсолютно не велик. Плюсом к этому ограничение по доступу к файлам и папкам на чтение/запись и систематический ручной (именно самостоятельно посмотреть логи и увидеть что/где/куда и за каким собственно хреном произошло) мониторинг логов демона. Процесс конфигурирования занял довольно долгое время по причине незнания и постоянного просмотра [OpenNet.ru](http://www.opennet.ru/base/net/vsftpd_overview.txt.html) на предмет понять, что делает каждый параметр в конфигурационном файле. Обзор статьи с возможностями дал гораздо больше, чем все остальные самопальные мануалы по настройке и конфигурированию. По итогу был выбран следующий вариант организации доступа к файлам: Индивидуальный файл конфигурации для каждого пользователя; Создано два локальных пользователя - первый с правом записи, второй только с правом чтения. Оба пользователя имеют домашние каталоги в папке `/home`. Пример листинга основного конфигурационного файла лежащего по адресу `/etc/vsftpd.conf`:

```bash
listen=YES # Включаем слушание демоном всех интерфейсов 
anonymous_enable=NO # Явно отключаем доступ для анонимных пользователей
local_enable=YES # Разрешить доступ локальным пользователям
write_enable=YES # Разрешить писать локальным пользователям 
local_umask=002 # Маска файлов/папок при создании 
dirmessage_enable=NO # Отключаем сообщения в папках 
use_localtime=YES # Использовать локальное время сервера (актуально для логирования)
xferlog_enable=YES # Включаем логирование 
connect_from_port_20=YES # Разрешаем доступ по 20-ому порту
data_connection_timeout=600 # Таймаут соединения 
chroot_local_user=YES # Чрутить локальных пользователей (запираем в домашнем каталоге) 
chroot_list_enable=YES # Включаем чрут-лист 
chroot_list_file=/etc/vsftpd/vsftpd_users # Расположение чрут-листа
secure_chroot_dir=/var/run/vsftpd/empty # Имя пустого каталога без возможности записи для пользователя ftp 
user_config_dir=/etc/vsftpd # Директория с конфигами для пользователей
pam_service_name=vsftpd # Указываем имя PAM сервиса для vsftpd
```

Не особо много параметров, а что и для чего думаю и так ясно из комментариев, в противном случае RTFM! Далее пример индивидуально конфигурационного файла для одного из пользователей:

```bash
local_root=/home/usver # Расположение локального каталога для пользователя
write_enable=YES # Разрешаем ему писать в этот каталог 
local_umask=022 # Маска создаваемых файлов/папок 
chroot_local_user=YES # Чрутим пользователя в его каталоге 
passwd_chroot_enable=YES # Пользователь запирается в каталоге указанном в /etc/passwd 
secure_chroot_dir=/home/usver # Имя пустого каталога без возможности записи для пользователя ftp (указал на всякий случай)
```

В файле `/etc/vsftpd/vsftpd_users` указываем нужных пользователей по одному на строчку. Собственно на этом все. После сохранения всех файлов и осмысления проделанного набираем в консоли:

```bash
service vsftpd restart
```

Демон `vsftpd` перезагружается и... Профит! На этом все сделано. Это основная и примитивная конфигурация сервера FTP для простоты и быстроты. За остальным RTFM вам в помощь!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
