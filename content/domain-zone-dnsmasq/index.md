---
categories: howto
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: howto.png
  relative: false
date: "2015-12-16T10:48:00+03:00"
tags:
- dnsmasq
- dns
- linux
- local development
- web development
- apache2
- wordpress
- hosts file
- networking
title: '[HowTo] Своя доменная зона с dnsmasq'
type: post
description: "Руководство по настройке локальной доменной зоны (*.dev) с помощью dnsmasq на Ubuntu для веб-разработки, включая настройку и интеграцию с виртуальными хостами Apache2."
keywords: ["dnsmasq local domain", "local dns server", "ubuntu dnsmasq", "web development environment", "apache2 virtual host", "local website testing", "linux networking", "dns caching"]
---

Всем привет! Сейчас будем создавать свою собственную доменную зону с помощью dnsmasq на локальном компьютере. Это очень удобно если вы занимаетесь разработкой сайтов или вам часто приходится смотреть какие-либо подобные вещи на локальной машине, а на хостинг не имеет смысла разоряться "ради посмотреть". Будем делать доменную зону `*.dev`. В итоге у нас будут красивые имена сайтов типа `blog.dev` или `mybestcrm.dev`, открывающиеся с локального компьютера.

`dnsmasq` - легковесный DNS, DHCP, TFTP (BOOTP, PXE) сервер.

Установка данного пакета будет производиться на моем ноутбуке с `Ubuntu 14.04.3`, накотором у меня уже установлены `MySQL`, `Apache2`, `phpMyAdmin`.

```bash
sudo apt-get install dnsmasq
```

Добавим в настройки dnsmasq зону `*.dev`, доступную только на локальной машине:

```bash
# sudo vim /etc/dnsmasq.conf  
address=/dev/127.0.0.1  
listen-address=127.0.0.1
```

Перезапустим `dnsmasq`:

```bash
sudo /etc/init.d/dnsmasq restart
```

Из "побочных эффектов", после установки `dnsmasq`, замечено уменьшение времени при резолвинге (`dns-resolve`) запросов к внешнему DNS-серверу - `dnsmasq` умеет кешировать dns-запросы, по умолчанию размер кеша равен 150.

Статус работы `dnsmasq` можно проверить:

_по логам_:

```bash
tail /var/log/messages
```

_командой_:

```bash
sudo killall -s USR1 dnsmasq
```

В качестве веб-сервера у меня установлен `apache2`, т.к. для локальных мучений его предостаточно. Теперь чтобы установить тот же самый `wordpress` и открыть его по адресу `blog.dev` мне достаточно сделать следующее:

```bash
cd /etc/apache2/sites-available  
cp ./000-default.conf ./blog.dev.conf
cat ./blog.dev.conf  
<VirtualHost *:80>  
    ServerName blog.dev  
    ServerAdmin admin@blog.dev  
    DocumentRoot /var/www/html/blog.dev  
</VirtualHost>
```

Сохраняем изменения `:wq` и включаем данный сайт в апаче:

```bash
# a2ensite blog.dev  
# service apache2 reload
```

После всех этих манипуляций можно поместить в папку `/var/www/html/blog.dev` тот же wordpress и открыть в браузере [http://blog.dev](http://blog.dev) и у вас автоматически запустится установщик вордпресса.

О том как установить полноценный `LAMP` на локальной машине в сети прелостаточно мануалов, посему не буду заострять на этом вопросе внимание. `RTFM` если есть вопросы.

Profit!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
