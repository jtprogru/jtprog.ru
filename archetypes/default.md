---
title: '{{ replace .Name "-" " " | title }}'
description: ""
keywords: []
date: {{ .Date }}
lastmod: {{ .Date }}
tags:
  - first
categories: ["Work"]
cover:
  image: work.png
  alt: work
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  relative: false
type: post
slug: '{{ .Date | time.AsTime | time.Format "2006-01-02" }}-{{ replace .Name " " "-" }}'
aliases:
  - '{{ replace .Name " " "-" }}'
---

Привет, `%username%`!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". 
