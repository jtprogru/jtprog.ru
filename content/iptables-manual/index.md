---
author: jtprogru
categories: howto
comments: true
date: "2015-03-30T16:48:37+03:00"
draft: false
noauthor: false
share: true
slug: /iptables-manual/
tags:
- iptables
- man
- linux
title: '[iptables] Шпаргалка по iptables'
type: post
---

Файрвол в системе linux контролируется программой `iptables` (для ipv4) и `ip6tables` (для ipv6). В данной шпаргалке я указал самые распространённые варианты использования iptables. Знак `#` означает, что команда выполняется от root'а. Получение прав root'а в системе Ubuntu делается командой `sudo -s`, в других системах командой `su`. Этот пост можно считать частичным дополнением моего поста про [VPN-сервер](http://jtprog.ru/simple-vpn/ "Простой VPN-сервер на базе Ubuntu+pptpd") и других, потому что пришлось изрядно поломать голову на тему доступа к серверу извне.

### Узнать статус

```bash
iptables -L -n -v
```

Примерный вывод команды для неактивного файрвола:

```bash
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
pkts bytes target     prot opt in     out     source               destination 
Chain FORWARD (policy ACCEPT 0 packets, 0 bytes) 
pkts bytes target     prot opt in     out     source               destination 
Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes) 
pkts bytes target     prot opt in     out     source               destination
```

И для активного файрвола:

```bash
Chain INPUT (policy DROP 0 packets, 0 bytes) 
pkts bytes target     prot opt in     out     source               destination 
0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0           state INVALID
394 43586 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0           state RELATED,ESTABLISHED 
93 17292 ACCEPT     all  --  br0    *       0.0.0.0/0            0.0.0.0/0 
1   142 ACCEPT     all  --  lo     *       0.0.0.0/0            0.0.0.0/0 
Chain FORWARD (policy DROP 0 packets, 0 bytes) 
pkts bytes target     prot opt in     out     source               destination 
0     0 ACCEPT     all  --  br0    br0     0.0.0.0/0            0.0.0.0/0 
0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0           state INVALID 
0     0 TCPMSS     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0           tcp flags:0x06/0x02 TCPMSS clamp to PMTU 
0     0 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0           state RELATED,ESTABLISHED 
0     0 wanin      all  --  vlan2  *       0.0.0.0/0            0.0.0.0/0 0     0 wanout     all  --  *      vlan2   0.0.0.0/0            0.0.0.0/0 
0     0 ACCEPT     all  --  br0    *       0.0.0.0/0            0.0.0.0/0 
Chain OUTPUT (policy ACCEPT 425 packets, 113K bytes)
pkts bytes target     prot opt in     out     source               destination 
Chain wanin (1 references) 
pkts bytes target     prot opt in     out     source               destination 
Chain wanout (1 references) 
pkts bytes target     prot opt in     out     source               destination
```

Параметры:

- `-L` : Показать список правил.  
- `-v` : Отображать дополнительную информацию. Эта опция показывает имя интерфейса, опции, TOS маски. Также отображает суффиксы "K", "M" or "G".  
- `-n` : Отображать IP адрес и порт числами (не используя DNS сервера для определения имен. Это ускорит отображение).

### Отобразить список правил с номерами строк

```bash
iptables -n -L -v --line-numbers
```

Примерный вывод:

```bash
Chain INPUT (policy DROP) 
num target prot opt source destination 
1 DROP all -- 0.0.0.0/0 0.0.0.0/0 state INVALID 
2 ACCEPT all -- 0.0.0.0/0 0.0.0.0/0 state RELATED,ESTABLISHED 
3 ACCEPT all -- 0.0.0.0/0 0.0.0.0/0 
4 ACCEPT all -- 0.0.0.0/0 0.0.0.0/0 
Chain FORWARD (policy DROP) 
num target prot opt source destination 
1 ACCEPT all -- 0.0.0.0/0 0.0.0.0/0 
2 DROP all -- 0.0.0.0/0 0.0.0.0/0 state INVALID 
3 TCPMSS tcp -- 0.0.0.0/0 0.0.0.0/0 tcp flags:0x06/0x02 TCPMSS clamp to PMTU 
4 ACCEPT all -- 0.0.0.0/0 0.0.0.0/0 state RELATED,ESTABLISHED 
5 wanin all -- 0.0.0.0/0 0.0.0.0/0 
6 wanout all -- 0.0.0.0/0 0.0.0.0/0 
7 ACCEPT all -- 0.0.0.0/0 0.0.0.0/0 
Chain OUTPUT (policy ACCEPT) 
num target prot opt source destination 
Chain wanin (1 references) 
num target prot opt source destination 
Chain wanout (1 references) 
num target prot opt source destination
```

Вы можете использовать номера строк для того, чтобы добавлять новые правила.

### Отобразить INPUT или OUTPUT цепочки правил

```bash
iptables -L INPUT -n -v 
iptables -L OUTPUT -n -v --line-numbers
```

### Остановить, запустить, перезапустить файрвол

Силами самой системы:

```bash
service ufw stop 
service ufw start
```

Можно также использовать команды iptables для того, чтобы остановить файрвол и удалить все правила:

```bash
iptables -F 
iptables -X 
iptables -t nat -F 
iptables -t nat -X 
iptables -t mangle -F 
iptables -t mangle -X 
iptables -P INPUT ACCEPT 
iptables -P OUTPUT ACCEPT 
iptables -P FORWARD ACCEPT
```

Где:

- `-F` : Удалить (flush) все правила.  
- `-X` : Удалить цепочку.  
- `-t table_name` : Выбрать таблицу (nat или mangle) и удалить все правила.  
- `-P` : Выбрать действия по умолчанию (такие, как DROP, REJECT, или ACCEPT).

### Удалить правила файрвола

Чтобы отобразить номер строки с существующими правилами:

```bash
iptables -L INPUT -n --line-numbers 
iptables -L OUTPUT -n --line-numbers 
iptables -L OUTPUT -n --line-numbers | less 
iptables -L OUTPUT -n --line-numbers | grep 202.54.1.1
```

Получим список IP адресов. Просто посмотрим на номер слева и удалим соответствующую строку. К примеру для номера 3:

```bash
iptables -D INPUT 3
```

Или найдем IP адрес источника (`202.54.1.1`) и удалим из правила:

```bash
iptables -D INPUT -s 202.54.1.1 -j DROP
```

Где:

- `-D` : Удалить одно или несколько правил из цепочки.

### Добавить правило в файрвол

Чтобы добавить одно или несколько правил в цепочку, для начала отобразим список с использованием номеров строк:

```bash
iptables -L INPUT -n --line-numbers
```

Примерный вывод:

```bash
Chain INPUT (policy DROP) 
num target prot opt source destination 
1 DROP all -- 202.54.1.1 0.0.0.0/0 
2 ACCEPT all -- 0.0.0.0/0 0.0.0.0/0 state NEW,ESTABLISHED
```

Чтобы вставить правило между 1 и 2 строкой:

```bash
iptables -I INPUT 2 -s 202.54.1.2 -j DROP
```

Проверим, обновилось ли правило:

```bash
iptables -L INPUT -n --line-numbers
```

Вывод станет таким:

```bash
Chain INPUT (policy DROP) 
num target prot opt source destination 
1 DROP all -- 202.54.1.1 0.0.0.0/0 
2 DROP all -- 202.54.1.2 0.0.0.0/0 
3 ACCEPT all -- 0.0.0.0/0 0.0.0.0/0 state NEW,ESTABLISHED
```

### Сохраняем правила файрвола

Через `iptables-save`:

```bash
iptables-save > /etc/iptables.rules
```

### Восстанавливаем правила

Через `iptables-restore`:

```bash
iptables-restore < /etc/iptables.rules
```

### Устанавливаем политики по умолчанию

Чтобы сбрасывать весь трафик:

```bash
iptables -P INPUT DROP 
iptables -P OUTPUT DROP 
iptables -P FORWARD DROP 
iptables -L -v -n
```

После вышеперечисленных команд ни один пакет не покинет данный хост.

```bash
ping google.com
```

### Блокировать только входящие соединения

Чтобы сбрасывать все не инициированные вами входящие пакеты, но разрешить исходящий трафик:

```bash
iptables -P INPUT DROP 
iptables -P FORWARD DROP 
iptables -P OUTPUT ACCEPT 
iptables -A INPUT -m state --state NEW,ESTABLISHED -j ACCEPT 
iptables -L -v -n
```

Пакеты исходящие и те, которые были запомнены в рамках установленных сессий - разрешены.

```bash
ping google.com
```

### Сбрасывать адреса изолированных сетей в публичной сети

```bash
iptables -A INPUT -i eth1 -s 192.168.0.0/24 -j DROP 
iptables -A INPUT -i eth1 -s 10.0.0.0/8 -j DROP
```

Список IP адресов для изолированных сетей:

```bash
10.0.0.0/8 -j (A)
172.16.0.0/12 (B)
192.168.0.0/16 (C)
224.0.0.0/4 (MULTICAST D) 
240.0.0.0/5 (E) 
127.0.0.0/8 (LOOPBACK)
```

### Блокировка определенного IP адреса

Чтобы заблокировать адрес взломщика `1.2.3.4`:

```bash
iptables -A INPUT -s 1.2.3.4 -j DROP 
iptables -A INPUT -s 192.168.0.0/24 -j DROP
```

### Заблокировать входящие запросы порта

Чтобы заблокировать все входящие запросы порта `80`:

```bash
iptables -A INPUT -p tcp --dport 80 -j DROP 
iptables -A INPUT -i eth1 -p tcp --dport 80 -j DROP
```

Чтобы заблокировать запрос порта `80` с адреса `1.2.3.4`:

```bash
iptables -A INPUT -p tcp -s 1.2.3.4 --dport 80 -j DROP 
iptables -A INPUT -i eth1 -p tcp -s 192.168.1.0/24 --dport 80 -j DROP
```

### Заблокировать запросы на исходящий IP адрес

Чтобы заблокировать определенный домен, узнаем его адрес:

```bash
host -t a facebook.com
```

Вывод:

```bash
facebook.com has address 69.171.228.40
```

Найдем `CIDR` для `69.171.228.40`:

```bash
whois 69.171.228.40 | grep CIDR
```

Вывод:

```bash
CIDR: 69.171.224.0/19
```

Заблокируем доступ на `69.171.224.0/19`:

```bash
iptables -A OUTPUT -p tcp -d 69.171.224.0/19 -j DROP
```

Также можно использовать домен для блокировки:

```bash
iptables -A OUTPUT -p tcp -d www.fаcebook.com -j DROP 
iptables -A OUTPUT -p tcp -d fаcebook.com -j DROP
```

### Записать событие и сбросить

Чтобы записать в журнал движение пакетов перед сбросом, добавим правило:

```bash
iptables -A INPUT -i eth1 -s 10.0.0.0/8 -j LOG --log-prefix "IP_SPOOF A: " 
iptables -A INPUT -i eth1 -s 10.0.0.0/8 -j DROP
```

Проверим журнал (по умолчанию `/var/log/messages`):

```bash
tail -f /var/log/messages 
grep -i --color "IP SPOOF" /var/log/messages
```

### Записать событие и сбросить (с ограничением на количество записей)

Чтобы не переполнить раздел раздутым журналом, ограничим количество записей с помощью `-m`. К примеру, чтобы записывать каждые 5 минут максимум 7 строк:

```bash
iptables -A INPUT -i eth1 -s 10.0.0.0/8 -m limit --limit 5/m --limit-burst 7 -j LOG --log-prefix "IP_SPOOF A: " 
iptables -A INPUT -i eth1 -s 10.0.0.0/8 -j DROP
```

### Сбрасывать или разрешить трафик с определенных MAC адресов

```bash
iptables -A INPUT -m mac --mac-source 00:0F:EA:91:04:08 -j DROP 
## разрешить только для TCP port 8080 с mac адреса 00:0F:EA:91:04:07 
iptables -A INPUT -p tcp --destination-port 22 -m mac --mac-source 00:0F:EA:91:04:07 -j ACCEPT
```

### Разрешить или запретить ICMP Ping запросы

Чтобы запретить:

```bash
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP 
iptables -A INPUT -i eth1 -p icmp --icmp-type echo-request -j DROP
```

Разрешить для определенных сетей/хостов:

```bash
iptables -A INPUT -s 192.168.1.0/24 -p icmp --icmp-type echo-request -j ACCEPT
```

Разрешить только часть `ICMP` запросов:

```bash
## предполагается, что политики по умолчанию ### 
## для входящих установлены в DROP  ### 
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT 
iptables -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT 
iptables -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT 
## разрешим отвечать на запрос ## 
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
```

### Открыть диапазон портов

```bash
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 7000:7010 -j ACCEPT
```

### Открыть диапазон адресов

```bash
## разрешить подключение к порту 80 (Apache) ## 
## если адрес в диапазоне от 192.168.1.100 до 192.168.1.200 ## 
iptables -A INPUT -p tcp --destination-port 80 -m iprange --src-range 192.168.1.100-192.168.1.200 -j ACCEPT 
## пример для nat ## 
iptables -t nat -A POSTROUTING -j SNAT --to-source 192.168.1.20-192.168.1.25
```

### Закрыть или открыть стандартные порты

Заменить `ACCEPT` на `DROP`, чтобы заблокировать порт.

```bash
## ssh tcp port 22 ##
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT 
iptables -A INPUT -s 192.168.1.0/24 -m state --state NEW -p tcp --dport 22 -j ACCEPT 
## cups (printing service) udp/tcp port 631 для локальной сети ##
iptables -A INPUT -s 192.168.1.0/24 -p udp -m udp --dport 631 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -p tcp -m tcp --dport 631 -j ACCEPT 
## time sync via NTP для локальной сети (udp port 123) ## 
iptables -A INPUT -s 192.168.1.0/24 -m state --state NEW -p udp --dport 123 -j ACCEPT 
## tcp port 25 (smtp) ##
iptables -A INPUT -m state --state NEW -p tcp --dport 25 -j ACCEPT 
## dns server ports ##
iptables -A INPUT -m state --state NEW -p udp --dport 53 -j ACCEPT
iptables -A INPUT -m state --state NEW -p tcp --dport 53 -j ACCEPT
## http/https www server port ## 
iptables -A INPUT -m state --state NEW -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -m state --state NEW -p tcp --dport 443 -j ACCEPT 
## tcp port 110 (pop3) ## 
iptables -A INPUT -m state --state NEW -p tcp --dport 110 -j ACCEPT 
## tcp port 143 (imap) ## 
iptables -A INPUT -m state --state NEW -p tcp --dport 143 -j ACCEPT 
## Samba file server для локальной сети ## 
iptables -A INPUT -s 192.168.1.0/24 -m state --state NEW -p tcp --dport 137 -j ACCEPT 
iptables -A INPUT -s 192.168.1.0/24 -m state --state NEW -p tcp --dport 138 -j ACCEPT 
iptables -A INPUT -s 192.168.1.0/24 -m state --state NEW -p tcp --dport 139 -j ACCEPT 
iptables -A INPUT -s 192.168.1.0/24 -m state --state NEW -p tcp --dport 445 -j ACCEPT 
## proxy server для локальной сети ## 
iptables -A INPUT -s 192.168.1.0/24 -m state --state NEW -p tcp --dport 3128 -j ACCEPT 
## mysql server для локальной сети ## 
iptables -I INPUT -p tcp --dport 3306 -j ACCEPT
```

### Ограничить количество параллельных соединений к серверу для одного адреса

Для ограничений используется connlimit модуль. Чтобы разрешить только 3 ssh соединения на одного клиента:

```bash
iptables -A INPUT -p tcp --syn --dport 22 -m connlimit --connlimit-above 3 -j REJECT
```

Установить количество запросов HTTP до 20:

```bash
iptables -p tcp --syn --dport 80 -m connlimit --connlimit-above 20 --connlimit-mask 24 -j DROP
```

Где:

- `--connlimit-above 3` : Указывает, что правило действует только если количество соединений превышает 3.  
- `--connlimit-mask 24` : Указывает маску сети.

### Помощь по `iptables`

Для поиска помощи по `iptables`, воспользуемся `man`:

```bash
man iptables
```

Чтобы посмотреть помощь по определенным командам и целям:

```bash
iptables -j DROP -h
```

### Проверка правила `iptables`

Проверяем открытость/закрытость портов:

```bash
netstat -tulpn
```

Проверяем открытость/закрытость определенного порта:

```bash
netstat -tulpn | grep :80
```

Проверим, что iptables разрешает соединение с `80` портом:

```bash
iptables -L OUTPUT -v -n | grep 80
```

В противном случае откроем его для всех:

```bash
iptables -A OUTPUT -m state --state NEW -p tcp --dport 80 -j ACCEPT
```

Проверяем с помощью `telnet`

```bash
telnet ya.ru 80
```

Можно использовать `nmap` для проверки:

```bash
nmap -sS -p 80 ya.ru
```

На этом можно и притормозить, потому что описанных здесь методов достаточно, чтобы  разобраться как с помощью `iptables` управлять сетевой безопасностью сервера и маршрутизацией на нем.

---
Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).
