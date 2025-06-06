---
title: '[HowTo] Лечим исчезнувший NetworkManager applet'
description: "Решение проблемы с отсутствующим апплетом NetworkManager в Ubuntu: восстановление сетевого интерфейса и альтернативные инструменты управления"
keywords:
  - networkmanager ubuntu
  - восстановление nm-applet
  - wicd установка
  - ошибки сетевого интерфейса
  - libnl фикс
date: "2016-02-02T21:51:19+03:00"
lastmod: "2016-02-02T21:51:19+03:00"
tags:
  - ubuntu
  - network
  - networkmanager
categories: ["howto"]
cover:
  image: howto.png
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  relative: false
type: post
slug: 'recover-nm-applet'
---

Случилась беда у меня на днях. Пришел с работы и не могу подключиться к домашней сетке. Пытаюсь посмотреть на сетевые подключения, а знакомого значка не нахожу на панели. Оказывается отвалился `nm-applet` вместе со всем `NetworkManager`'ом.

Главное настроить доступ в интернет себе с потерянного компьютера, а дальше можно вылечить все. И так, первое, что необходимо сделать, это настроит доступ в сеть. Делается это вот таким вот способом:

```bash
sudo ifconfig eth0 up
sudo dhclient eth0
```

Мы таким образом коннектимся по шнурку к сетке, получаем ip'шник по DHCP (~~если такой сервер присутствует в вашей сети~~) и соответственно можем работать в интернете. На этом можно остановиться и радоваться жизни. Но мне данное решение не совсем удобно, т.к. я в течении дня могу подключаться к 5-7 разным сетям как по шнурку, так и по вафле. Меня такое не совсем устраивает, т.к. я ленивый и не горю желанием каждый раз понимать интерфейсы через консоль.

Для того, чтобы совсем не пользоваться NetworkManager'ом и при этом получить возможность работать с сетями есть софтина под названием Wicd:

```bash
sudo apt-get install wicd
```

Она простая как палка и многим ее так же может хватить при условии, что вам пофигу чем именно работать. А мне очень хочется удобства, да и привычка дает о себе знать. Собственно для таких же как и я есть вот такое решение:

```bash
sudo apt-get install libnl-3-200=3.2.21-1 libnl-route-3-200=3.2.21-1 libnl-genl-3-200=3.2.21-1
sudo service network-manager restart
```

И вуаля! Все работает!

ЗЫЖ Линки по которым все выше указанное сделано: [askubuntu](http://askubuntu.com/questions/727127/last-upgrade-crashes-network-manager-no-internet-connection-no-applet/727204#727204), и сами bug'и заведенные в launchpad: [раз](https://bugs.launchpad.net/ubuntu/+source/libnl3/+bug/1539513), [два](https://bugs.launchpad.net/ubuntu/+source/libnl3/+bug/1511735), [три](https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/1539634).

На этом все!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
