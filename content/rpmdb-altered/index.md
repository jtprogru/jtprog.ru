---
title: "[CentOS] RPMDB altered outside of yum"
date: 2019-07-29T11:47:56+03:00
draft: false
slug: '/rpmdb-altered/'
description: 'Устранение ошибки RPMDB altered outside of yum в CentOS'
categories: "howto"
tags: ['rpmdb', 'centos', 'yum']
comments: true
noauthor: false
share: true
type: "post"
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
