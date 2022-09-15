---
categories: OS
comments: true
date: "2016-10-31T09:00:14+03:00"
draft: false
noauthor: false
share: true
slug: /queue-blacklist-postfix/
tags:
- postfix
- blacklist
title: '[Ubuntu] Очередь и blacklist Postfix'
type: post
---

Приветствую, `%username%`! Рано или поздно все сталкиваются с проблемами в работе почтового сервера. И одна из распространенных причин это переполнение очереди сообщений. Рассмотрим как же эту очередь посмотреть и почистить.

Ну собственно всё гениальное просто. Заходим на сервер:
```bash
ssh -p 22 root@mail.company.org
```

Да я хожу на сервера под рутом. Да по ключу. Да пароль не меньше 18 символов.

Далее для того, чтобы просто посмотреть какие сообщения в очереди есть и узнать их количество есть несколько вариантов.

Первый:
```bash
mailq
```

Нам покажется вся очередь сообщений, с указанием общего объёма и количества писем в очереди. Пример (отрывок):
```bash
-Queue ID- --Size-- ----Arrival Time---- -Sender/Recipient------- 
E031AAB432F5* 8721 Fri Oct 28 03:25:54 root@mail.company.org root@mail.company.org 
8DB65AB43E34* 2130 Fri Oct 28 09:01:52 root@mail.company.org root@mail.company.org 
2E0FDAB40FF4* 2130 Fri Oct 28 04:01:20 root@mail.company.org root@mail.company.org 
BD2ACAB440A9     4696 Fri Oct 28 01:11:17  MAILER-DAEMON (connect to static.vnpt.vn[203.162.0.78]:25: Connection refused) Rivera.68@static.vnpt.vn 
B7D55AB440D2     4708 Fri Oct 28 04:23:30  MAILER-DAEMON (delivery temporarily suspended: connect to static.vnpt.vn[203.162.0.78]:25: Connection refused) Sanchez.4098@static.vnpt.vn 
B5292AB440E9     4714 Fri Oct 28 04:23:31  MAILER-DAEMON (delivery temporarily suspended: connect to static.vnpt.vn[203.162.0.78]:25: Connection refused) Sanchez.4098@static.vnpt.vn -- 3542 Kbytes in 195 Requests.
```
Второй:
```bash
postqueue -p
```
Вывод точно такой же как и у предыдущей команды. Но *postqueue* мне больше нравится для более детального разбора полётов, т.к. имеет возможность вывода данных в JSON формате:
```bash
postqueue -j | less
```
`less` предоставит нам более удобную навигацию с детальной информацией об отправителях, получателях, размере, ответе сервера получателя. Далее мы определяемся с тем, какое письмо можно удалить, а какое можно оставить. Удалить конкретное письмо можно вот такой командой:
```bash
postsuper -d 8DB65AB43E34
```

Где `8DB65AB43E34` это ID конкретного письма. Ну а если вы всё же решили полностью почистить всю очередь удалив в ней все письма, тогда вместо конкретного ID указывается параметр `ALL`:
```bash
postsuper -d ALL
```

После этого наша очередь пуста. Собственно с вопросом очистки очереди всё. Далее меня интересует вопрос занесения в черный список конкретных email-адресов, серверов, IP-адресов. В Postfix всё делается следующим образом:
```bash
vim /etc/postfix/sender_access.pcre
```

И вносим в этот файл интересующие нас данные в соответствии с примером ниже:
```bash
cat /etc/postfix/sender_access.pcre
203.162.0.78 REJECT 
static.vnpt.vn REJECT 
pupkin@company.org REJECT
```

После этого необходимо выполнить следующее:
```bash
postmap hash:sender_access.pcre
```

А так же отредактировать файл `main.cf` в разделе `Recipient restrictions`:
```bash
vim /etc/postfix/main.cf
```
Вносим следующую строчку сразу после уже перечисленных там:
```bash
check_sender_access hash:/etc/postfix/sender_access.pcre
```

Далее для полноты эффекта неплохо бы подкрутить еще и SpamAssassin. По умолчанию там включены только белые списки. Нам же необходимо добавить туда еще и список засранцев. Делается это следующим образом. Открываем файл `/etc/mail/spamassassin/local.cf` и вносим туда всё что необходимо в соответствии с примером ниже, после чего перезагружаем сервис SpamAssassin:
```bash
cat /etc/mail/spamassassin/local.cf
# Blacklist
blacklist_from *@static.vnpt.vn
```

Мы просто добавили конкретный домен. Теперь от него мы более не получим никаких писем. Далее просто рестартуем сервис SpamAssassin:
```bash
service spamassassin restart
```

На этом собственно всё!
