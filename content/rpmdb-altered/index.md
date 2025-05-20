---  
title: '[HowTo] RPMDB altered outside of yum'  
description: "Решение ошибки 'RPMDB altered outside of yum' в CentOS: очистка кэша, восстановление целостности базы RPM и рекомендации по работе с пакетами"  
keywords:  
  - yum ошибка rpmdb  
  - восстановление rpm базы  
  - yum history new  
  - yum clean all  
  - управление пакетами centos  
date: "2019-07-29T11:47:56+03:00"  
lastmod: "2019-07-29T11:47:56+03:00"  
tags:  
  - rpmdb  
  - centos  
  - yum  
categories: ["howto"]  
cover:  
  image: howto.png  
  alt: howto  
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'  
  relative: false  
type: post  
slug: 'rpmdb-altered'
---  

Привет, `%username%`! При работе с менеджером пакетов `yum` иногда возникают ошибки, чаще всего из-за человеческого фактора. Как исправить одну из таких читай ниже!

При установке нового пакета или при обновлении система сообщила:

```bash
Warning: RPMDB altered outside of yum.
```

Ошибка означает, что какое-то приложение работало с базой `rpm` в обход стандартного `RPM-API`.

Что бы избежать таких ошибок — лучше пользоваться стандартным `yum`, вместо `rpm -e`, `rpm -i`, `rpm -ivh` или `rpm -Uvh`. И не прерывать процесс установки/удаления/обновления комбинациями `Ctrl+C`. Если надо приостановить задачу — воспользуйтесь «заморозкой» — `Ctrl+Z`.

Что бы исправить такую ошибку — выполните:

```bash
yum history new
```

Или:

```bash
yum clean all
```

Profit!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
