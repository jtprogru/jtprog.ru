---
categories: howto
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: howto.png
  relative: false
date: "2016-08-01T05:55:44+03:00"
tags:
- macos
- safari
title: '[HowTo] Разрешаем просмотр pdf-файлов в Safari'
type: post
---

С недавних пор я стал маководом, прикупив себе не новый `MacBook Pro 15` 2011 года. Конфигурация вполне себе приличная для такого старичка:

- CPU Intel Core i7;
- RAM 2x4 GB DDR3 1600 MHz;
- SSD PLEXTOR PX-512M5Pro 512 GB.

Остальное в целом стандартное. И вот постепенно осваиваясь в новой системе я захотел решить одну проблему связанную просмотром PDF в браузере `Safari`.

Я перешел на `Safari` с родной и близкой моему сердцу `Mozilla Firefox` по причине того, что `Safari` более оптимизирована для экономии заряда батареи. В целом все хорошо, но мне очень не понравилось, что `Safari` вместо открытия `pdf`-файла скачивает его, и я всё же нашел как эту проблему решить.

Делается это выполнением в `Терминале` следующей команды:

```bash
defaults write com.apple.Safari WebKitOmitPDFSupport -boolean true 
defaults delete com.apple.Safari WebKitOmitPDFSupport
```

После чего необходимо перезапустить `Safari`.

Как говорится "Все гениальное - просто!"

На этом всё!

---
Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).
