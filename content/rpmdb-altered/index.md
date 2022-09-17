---
categories: howto
cover:
  alt: wiki
  caption: wiki
  image: wiki.png
  relative: false
date: "2019-07-29T11:47:56+03:00"
tags:
- rpmdb
- centos
- yum
title: '[HowTo] RPMDB altered outside of yum'
type: post
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
