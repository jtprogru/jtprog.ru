---
categories: howto
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: howto.png
  relative: false
date: "2015-06-08T18:51:46+03:00"
tags:
- ubuntu
- route
- man
- сетевые настройки
- статическая маршрутизация
title: '[HowTo] Шпаргалка про роутинг в Ubuntu'
type: post
description: "Руководство по настройке статической и динамической маршрутизации в Ubuntu. Примеры команд route, работа с таблицами маршрутов и конфигурацией интерфейсов."
keywords:
  - "настройка маршрутизации Ubuntu"
  - "команда route Linux"
  - "netstat таблица маршрутов"
  - "статический маршрут eth0"
  - "шлюз по умолчанию Ubuntu"
  - "конфигурация /etc/network/interfaces"
---

Про правила добавления маршрутов в Windows я уже [написал](https://jtprog.ru/windows-route-add/). Пришла пора написать про правила добавления маршрутов в любимой мною Ubuntu. Так же есть немного общей информации по данной теме, относящейся к Ubuntu и маршрутизации. И сразу поясню, что все действия требуется делать от имени суперпользователя (`root`).

Правила маршрутизации определяют, куда отправлять IP-пакеты. Данные маршрутизации хранятся в одной из таблиц ядра. Вести таблицы маршрутизации можно статически или динамически. Статический маршрут - это маршрут, который задается явно с помощью команды route. Динамическая маршрутизация выполняется процессом-демоном (routed или gated), который ведет и модифицирует таблицу маршрутизации на основе сообщений от других компьютеров сети. Для выполнения динамической маршрутизации разработаны специальные протоколы: RIP, OSPF, IGRP, EGP, BGP и т. д.  

Динамическая маршрутизация необходима в том случае, если у вас сложная, постоянно меняющаяся структура сети и одна и та же машина может быть доступна по различным интерфейсам (например, через разные Ethernet или SLIP интерфейсы). Маршруты, заданные статически, обычно не меняются, даже если используется динамическая маршрутизация. Для персонального компьютера, подключаемого к локальной сети, в большинстве ситуаций бывает достаточно статической маршрутизации командой route. Прежде чем пытаться настраивать маршруты, просмотрите таблицу маршрутизации ядра с помощью команды `netstat -n -r`. Вы должны увидеть что-то вроде следующего

```bash
jtprog@server_test:~$ netstat -n -r  
Destination          Gateway              Genmask             Flags     MSS     Window       irtt       Iface  
192.168.254.0     0.0.0.0                 255.255.255.0     U           0          0                  0          eth1  
192.168.254.0     0.0.0.0                 255.255.255.0     U           0          0                  0          eth0  
169.254.0.0         0.0.0.0                 255.255.0.0         U           0          0                  0          eth1  
0.0.0.0                 192.168.254.1     0.0.0.0                 UG         0          0                  0          eth0  
0.0.0.0                 192.168.254.1     0.0.0.0                 UG         0          0                  0          eth1
```

Если таблица пуста, то вы увидите только заголовки столбцов. С помощью команды `route` можно добавить или удалить один (за один раз) статический маршрут. Вот ее формат:

```bash
route операция -тип адресат шлюз интерфейс
```

Здесь аргумент "операция" может принимать одно из двух значений: `add` (маршрут добавляется) или `delete` (маршрут удаляется).

Аргумент "адресат" может быть IP-адресом машины, IP-адресом сети или ключевым словом `default`.

Аргумент "шлюз" - это IP-адрес компьютера, на который следует пересылать пакет (этот компьютер должен иметь прямую связь с вашим компьютером).

Команда:

```bash
route -f
```

удаляет из таблицы данные обо всех шлюзах. Необязательный аргумент тип принимает значения net или host. В первом случае в поле адресата указывается адрес сети, а во втором - адрес конкретного компьютера (хоста). Как правило, бывает необходимо настроить маршрутизацию по упоминавшимся выше трем интерфейсам:

- локальный интерфейс (`lo`),
- интерфейс для платы Ethetnet (`eth0`),
- интерфейс для последовательного порта (`PPP` или `SLIP`).

Локальный интерфейс поддерживает сеть с IP-номером `127.0.0.1`. Поэтому для маршрутизации пакетов с адресом `127.0.X.X` используется команда:

```bash
route add -net 127.0.0.1 lo
```

Если у вас для связи с локальной сетью используется одна плата Ethernet, и все машины находятся в этой сети (сетевая маска `255.255.255.0`), то для настройки маршрутизации достаточно вызвать:

```bash
route add -net 192.168.36.0 netmask 255.255.255.0 eth0
```

Если же вы имеете насколько интерфейсов, то вам надо определиться с сетевой маской и вызвать команду route для каждого интерфейса. Поскольку очень часто IP-пакеты с вашего компьютера могут отправляться не в одну единственную сеть, а в разные сети (например, при просмотре разных сайтов в Интернете), то в принципе надо было бы задать очень много маршрутов. Очевидно, что сделать это было бы очень сложно, точнее просто невозможно. Поэтому решение проблемы маршрутизации пакетов перекладывают на плечи специальных компьютеров-маршрутизаторов, а на обычных компьютерах задают маршрут по умолчанию, который используется для отправки всех пакетов, не указанных явно в таблице маршрутизации. С помощью маршрута по умолчанию вы говорите ядру "а все остальное отправляй туда". Маршрут по умолчанию настраивается следующей командой:

```bash
route add default gw 192.168.1.1 eth0
```

Опция `gw` указывает программе `route`, что следующий аргумент - это IP-адрес или имя маршрутизатора, на который надо отправлять все пакеты, соответствующие этой строке таблицы маршрутизации.

## А теперь пример

Имеются следующие интерфейсы `/etc/network/interfaces`:

```bash
auto lo  
iface lo inet loopback

auto eth0  
iface eth0 inet static  
address 192.168.17.8  
hwaddress ether 00:E0:4C:A2:C4:48  
netmask 255.255.255.0  
broadcast 192.168.17.255

auto eth1  
iface eth1 inet static  
address 192.168.254.2  
netmask 255.255.255.0  
gateway 192.168.254.1  
broadcast 192.168.254.255
```

Интерфейс `eth0` это связь с локальной сетью состоящей из 20 подсетей `192.168.1.х-192.168.20.х`

Интерфейс `eth1` это связь с ADSL модемом с выходом в интернет. Так большинство запросов идут в Инет на этом интерфейсе прописываем шлюз (`gateway 192.168.254.1`) данный параметр указывает в системе шлюз по-умолчанию, обращаю внимание, что шлюз надо прописывать только на одном интерфейсе, иначе в системе появятся 2 маршрута по умолчанию и естественно будет затупление в работе. С интернетом разобрались.

Но требуется еще просматривать ресурсы локальной сети для этого надо выполнить вот эти команды:

```bash
route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.17.254 eth0
route add -net 192.168.12.0 netmask 255.255.255.0 gw 192.168.17.254 eth0
route add -net 192.168.21.0 netmask 255.255.255.0 gw 192.168.17.254 eth0
```

На этом примере маршрутизируются 3 подсети Все эти команды и многие другие можно прописать в файлк `/etc/network/interfaces` в итоге получится следующее:

```bash
auto lo  
iface lo inet loopback

auto eth0  
iface eth0 inet static  
  address 192.168.17.8  
  hwaddress ether 00:E0:4C:A2:C4:48  
  netmask 255.255.255.0  
  broadcast 192.168.17.255  
  up route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.17.254 eth0  
  up route add -net 192.168.12.0 netmask 255.255.255.0 gw 192.168.17.254 eth0  
  up route add -net 192.168.21.0 netmask 255.255.255.0 gw 192.168.17.254 eth0

auto eth1  
iface eth1 inet static  
  address 192.168.254.2  
  netmask 255.255.255.0  
  gateway 192.168.254.1  
  broadcast 192.168.254.255
```

По аналогии настраиваются любое кол-во маршрутов и сетевых интерфейсов. Обратите внимание:

```bash
hwaddress ether 00:E0:4C:A2:C4:48
```

так легко можно изменить `MAC`, не забываем после редактирования файла делать рестарт

```bash
sudo /etc/init.d/networking restart
```

Так же отмечу, что:

1. Для того, чтобы просмотреть таблицу маршрутов достаточно запуска команды `route` без параметров или `route -n`, если в сети нет `DNS`.
2. Маска может быть записана проще, в виде `/x`, где `x` - число единичных битов, например:

```bash
route add -net 192.168.36.0/24 eth0
```

вместо

```bash
route add -net 192.168.36.0 netmask 255.255.255.0 eth0
```

Настройки сети размещаются в файле `/etc/network/interfaces`:

При подключение к Inet через VPN (`ppp0`), необходимо заменять маршрут по умолчанию на `ppp0`. А проще указать в файле `/etc/ppp/options` следующее:

```bash
defaultroute  
replacedefaultroute
```

тогда маршрут заменяется сам и при отключении восстанавливается.

Есть прога, серверная часть которой стоит во внутренней сети, например Radmin Server, чтобы к нему подключиться клиентская прога (Radmin Viewer) запрашивает соединение по порту `5588` (например). Все работает внутри локальной сети. Есть шлюз (с внешним IP), через который обеспечивает доступ в и-нет всех компов внутренней сети. Теперь вопрос, как настроить шлюз, чтобы при обращении из вне клиентсокой частью к IP шлюза по порту `4799`, он пробрасывал этот запрос дальше, например на `192.168.0.2` по томуже порту? Для этого есть команда [`iptables`](https://jtprog.ru/iptables-manual/).

На этом все! Profit!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
