---
title: '[OS] Шпаргалка про роутинг в Windows'
description: "Пошаговая инструкция по добавлению и управлению статическими маршрутами в Windows: синтаксис, параметры, примеры команд, советы по настройке и устранению ошибок."
keywords: ["роутинг windows", "статические маршруты windows", "route add windows", "windows routing table", "настройка маршрутизации windows", "route print", "windows network troubleshooting", "windows route delete", "windows route change"]
date: "2015-06-08T12:49:00+03:00"
lastmod: "2015-06-08T12:49:00+03:00"
tags:
  - windows
  - route
  - man
categories:
  - OS
cover:
  image: OS.png
  alt: OS
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  relative: false
type: post
slug: windows-route-add
---

Привет, `%username%`! Поскольку часто приходится настраивать ВПНы на чужих машинах и предоставлять доступ к каки-либо ресурсам нашей сети, а чаще всего это просто конкретные машины, то надо записать себе шпаргалку по добавлению статических маршрутов в ОСях семейства Windows (XP/7/8/8.1). Все элементарно и просто.

## Синтаксис

```cmd
route [-f] [-p] [*команда* [*конечная_точка*] [mask <маска_сети>] [<шлюз>] [metric <метрика>]] [if <интерфейс>]]
```

## Параметры

- `-f` - Очищает таблицу маршрутизации от всех записей, которые не являются узловыми маршрутами (маршруты с маской подсети `255.255.255.255`), сетевым маршрутом замыкания на себя (маршруты с конечной точкой `127.0.0.0` и маской подсети `255.0.0.0`) или маршрутом многоадресной рассылки (маршруты с конечной точкой `224.0.0.0` и маской подсети `240.0.0.0`). При использовании данного параметра совместно с одной из команд (таких, как `add`, `change` или `delete`) таблица очищается перед выполнением команды.
- `-p` - При использовании данного параметра с командой `add` указанный маршрут добавляется в реестр и используется для инициализации таблицы IP-маршрутизации каждый раз при запуске протокола TCP/IP. По умолчанию добавленные маршруты не сохраняются при запуске протокола TCP/IP. При использовании параметра с командой print выводит на экран список постоянных маршрутов. Все другие команды игнорируют этот параметр. Постоянные маршруты хранятся в реестре по адресу `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\PersistentRoutes`
- `команда` - Указывает команду, которая будет запущена на удаленной системе.

Список допустимых параметров:

|Команда | Назначение |
|:---|:---|
|`add` | Добавление маршрута|
|`change` | Изменение существующего маршрута|
|`delete` |Удаление маршрута или маршрутов|
|`print` | Печать маршрута или маршрутов|

- `конечная_точка` -  Определяет конечную точку маршрута. Конечной точкой может быть сетевой IP-адрес (где разряды узла в сетевом адресе имеют значение 0), IP-адрес маршрута к узлу, или значение `0.0.0.0` для маршрута по умолчанию.
- `mask <маска_сети>` Указывает маску сети (также известной как маска подсети) в соответствии с точкой назначения. Маска сети может быть маской подсети соответствующей сетевому IP-адресу, например `255.255.255.255` для маршрута к узлу или `0.0.0.0`. для маршрута по умолчанию. Если данный параметр пропущен, используется маска подсети `255.255.255.255`. Конечная точка не может быть более точной, чем соответствующая маска подсети. Другими словами, значение разряда 1 в адресе конечной точки невозможно, если значение соответствующего разряда в маске подсети равно 0.
- `шлюз` - Указывает IP-адрес пересылки или следующего перехода, по которому доступен набор адресов, определенный конечной точкой и маской подсети. Для локально подключенных маршрутов подсети, адрес шлюза — это IP-адрес, назначенный интерфейсу, который подключен к подсети. Для удаленных маршрутов, которые доступны через один или несколько маршрутизаторов, адрес шлюза — непосредственно доступный IP-адрес ближайшего маршрутизатора.
- `metric <метрика>` - Задает целочисленную метрику стоимости маршрута (в пределах от 1 до 9999) для маршрута, которая используется при выборе в таблице маршрутизации одного из нескольких маршрутов, наиболее близко соответствующего адресу назначения пересылаемого пакета. Выбирается маршрут с наименьшей метрикой. Метрика отражает количество переходов, скорость прохождения пути, надежность пути, пропускную способность пути и средства администрирования.
- `if <интерфейс>` - Указывает индекс интерфейса, через который доступна точка назначения. Для вывода списка интерфейсов и их соответствующих индексов используйте команду `route print`. Значения индексов интерфейсов могут быть как десятичные, так и шестнадцатеричные. Перед шестнадцатеричными номерами вводится `0х`. В случае, когда параметр `if` пропущен, интерфейс определяется из адреса шлюза.
- `/?` -  Отображает справку в командной строке.

## Примечания

- Большие значения в столбце `metric` таблицы маршрутизации — результат возможности протокола TCP/IP автоматически определять метрики маршрутов таблицы маршрутизации на основании конфигурации IP-адреса, маски подсети и стандартного шлюза для каждого интерфейса ЛВС. Автоматическое определение метрики интерфейса, включенное по умолчанию, устанавливает скорость каждого интерфейса и метрики маршрутов для каждого интерфейса так, что самый быстрый интерфейс создает маршруты с наименьшей метрикой. Чтобы удалить большие метрики, отключите автоматическое определение метрики интерфейса в дополнительных свойствах протокола TCP/IP для каждого подключения по локальной сети.
- Имена могут использоваться для параметра `<конечная_точка>`, если существует соответствующая запись в файле базы данных `Networks`, находящемся в папке `*системный_корневой_каталог*\System32\Drivers\Etc`. В параметре `<шлюз>` можно указывать имена до тех пор, пока они разрешаются в IP-адреса с помощью стандартных способов разрешения узлов, таких как запрос службы DNS, использование локального файла `Hosts`, находящегося в папке `*системный_корневой_каталог*\system32\drivers\etc`, или разрешение имен NetBIOS.
- Если команда — `print` или `delete`, параметр `<шлюз>` опускается и используются подстановочные знаки для указания точки назначения и шлюза. Значение `<конечной_точки>` может быть подстановочным значением, которое указывается звездочкой (`*`). При наличии звездочки (`*`) или вопросительного знака (`?`) в описании конечной точки, они рассматриваются как подстановки, тогда печатаются или удаляются только маршруты, соответствующие точке назначения. Звездочка соответствует любой последовательности символов, а вопросительный знак — любому одному символу. `10.*.1`, `192.168.*`, `127.*` и `*224*` являются допустимыми примерами использования звездочки в качестве подстановочного символа.
- При использовании недопустимой комбинации значений конечной точки и маски подсети (маски сети) выводится следующее сообщение об ошибке: `Маршрут: неверная маска подсети адреса шлюза`. Ошибка появляется, когда одно или несколько значений разрядов в адресе конечной точки равно 1, а значения соответствующих разрядов маски подсети — 1. Для проверки этого состояния выразите конечную точку и маску подсети в двоичном формате. Маска подсети в двоичном формате состоит из последовательности единичных битов, представляющей часть сетевого адреса конечной точки, и последовательности нулевых битов, обозначающей часть адреса узла конечной точки. Проверьте наличие единичных битов в части адреса точки назначения, которая является адресом узла (как определено маской подсети).
- Параметр `-p` поддерживается в команде `route` только в операционных системах Windows NT 4.0, Windows 2000, Windows Millennium Edition и Windows XP. Этот параметр не поддерживается командой `route` в системах Windows 95 и Windows 98.
- Эта команда доступна, только если в свойствах сетевого адаптера в объекте Сетевые подключения в качестве компонента установлен протокол Интернета (TCP/IP).

## Примеры

Чтобы вывести на экран все содержимое таблицы IP-маршрутизации, введите команду:

```bash
route print
```

Чтобы вывести на экран маршруты из таблицы IP-маршрутизации, которые начинаются с `*10.*`, введите команду:

```bash
route print 10.*
```

Чтобы добавить маршрут по умолчанию с адресом стандартного шлюза `192.168.12.1`, введите команду:

```bash
route add 0.0.0.0 mask 0.0.0.0 192.168.12.1
```

Чтобы добавить маршрут к конечной точке `10.41.0.0` с маской подсети `255.255.0.0` и следующим адресом перехода `10.27.0.1`, введите команду:

```bash
route add 10.41.0.0 mask 255.255.0.0 10.27.0.1
```

Чтобы добавить постоянный маршрут к конечной точке `10.41.0.0` с маской подсети `255.255.0.0` и следующим адресом перехода `10.27.0.1`, введите команду:

```bash
route -p add 10.41.0.0 mask 255.255.0.0 10.27.0.1
```

Чтобы добавить маршрут к конечной точке `10.41.0.0` с маской подсети `255.255.0.0` и следующим адресом перехода `10.27.0.1` и метрикой `7`, введите команду:

```bash
route add 10.41.0.0 mask 255.255.0.0 10.27.0.1 metric 7
```

Чтобы добавить маршрут к конечной точке `10.41.0.0` с маской подсети `255.255.0.0` и следующим адресом перехода `10.27.0.1` и использованием индекса интерфейса `0х3`, введите команду:

```bash
route add 10.41.0.0 mask 255.255.0.0 10.27.0.1 if 0x3
```

Чтобы удалить маршрут к конечной точке `10.41.0.0` с маской подсети `255.255.0.0`, введите команду:

```bash
route delete 10.41.0.0 mask 255.255.0.0
```

Чтобы удалить все маршруты из таблицы IP-маршрутизации, которые начинаются с `*10.*`, введите команду:

```bash
route delete 10.*
```

Чтобы изменить следующий адрес перехода для маршрута с конечной точкой `10.41.0.0` и маской подсети `255.255.0.0` с `10.27.0.1` на `10.27.0.25`, введите команду:

```bash
route change 10.41.0.0 mask 255.255.0.0 10.27.0.25
```

На этом все! Profit!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
