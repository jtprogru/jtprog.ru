---
categories: ["HowTo"]
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: howto.png
  relative: false
date: "2016-10-04T12:36:54+03:00"
tags:
- mc
- macos
- troubleshooting
- configuration
- file manager
- terminal
- utility
title: '[HowTo] Исправляем глюк Midnight Commander'
type: post
description: "Исправление ошибки в Midnight Commander (mc) на macOS и Linux, когда левая панель всегда открывает одну и ту же директорию, путем редактирования файла panels.ini."
keywords: ["midnight commander fix", "mc bug", "mc panels ini", "fixed directory mc", "linux mc", "macos mc", "command line file manager", "troubleshooting mc", "mc configuration"]
---

В работе часто приходится пользоваться консолью и Midnight Commander'ом aka `mc`. Так вот, с недавнего времени у меня обнаружился глюк. При открытии он в правой панели открывает текущую директорию, а в левой одну и ту же. В целом ничего страшного, но пипец как неудобно. Решение оказалось довольно простым.

Всё, что требуется сделать это подправить файл настроек самого mc, который расположен по пути `~/.config/mc/panels.ini` (это в macOS и большинстве Linux систем).

Делаем в консоли:

```bash
vim ~/.config/mc/panels.ini
```

И ищем раздел `[Dirs]`, в котором есть параметр `other_dir`. Для решения проблемы достаточно удалить всё, что написано после знака `=`. Т.е. раздел у меня получился вот такой:

```bash
[Dirs]
current_is_left=false
other_dir=
```

Сохраняем изменения и радуемся нормальному открытию `mc`.

На этом всё!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". 
