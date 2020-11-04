---
title: "[Linux] Лечим Postfix"
date: 2019-05-23T15:48:55+03:00
draft: false
slug: '/postfix-ipv4/'
categories: "Linux"
tags: ['postfix', 'linux']
comments: true
noauthor: false
share: true
type: "post"
---



После отключения IPv6 на сервере перестал запускаться Postfix, но оставлял в логах следующие ошибки:
```bash
fatal: parameter inet_interfaces: no local interface found for ::1
```
Или что-то подобное:
```bash
May 23 15:46:27 myserver.local postfix/postsuper[25738]: warning: inet_protocols: disabling IPv6 name/address support: Address family not supported by protocol
May 23 15:46:28 myserver.local postfix[25657]: /usr/sbin/postconf: warning: inet_protocols: disabling IPv6 name/address support: Address family not supported by protocol
May 23 15:46:28 myserver.local postfix/postlog[25779]: warning: inet_protocols: disabling IPv6 name/address support: Address family not supported by protocol
May 23 15:46:28 myserver.local postfix/postfix-script[25779]: starting the Postfix mail system
May 23 15:46:28 myserver.local postfix/master[25783]: warning: inet_protocols: disabling IPv6 name/address support: Address family not supported by protocol
May 23 15:46:28 myserver.local postfix/master[25783]: warning: inet_protocols: disabling IPv6 name/address support: Address family not supported by protocol
```

Для решения редактируем `/etc/postfix/main.cf` заменяя

```bash
inet_protocols=all
```

на

```bash
inet_protocols=ipv4
```

Далее, перезапускаем сервис

```bash
systemctl restart postfix
```
Profit!
