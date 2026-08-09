---
title: '{{ replace .Name "-" " " | title }}'
description: "TODO: краткое описание поста (150-160 символов)"
keywords: []
date: {{ .Date }}
lastmod: {{ .Date }}
draft: true
tags: []
categories: []
cover:
  image: "TODO-cover.png"
  alt: "TODO: alt-текст обложки"
  caption: "TODO: caption (автор, источник)"
  relative: false
type: post
slug: '{{ replace .Name " " "-" }}'
params:
  math: false
---

Привет, `%username%`!

<!-- Футер со ссылками на чат, канал и донаты руками не пишем: его подставляет
     тема под каждым постом (params.postEndnote в hugo.yaml). -->

