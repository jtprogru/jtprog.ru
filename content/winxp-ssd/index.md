---
categories: OS
cover:
  alt: OS
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: OS.png
  relative: false
date: "2016-07-15T19:14:00+03:00"
tags:
- windows
- upgrade
- SSD
- миграция данных
- Acronis
title: '[OS] Windows XP на новом SSD'
type: post
description: "Опыт переноса Windows XP на SSD: клонирование диска, решение проблем с драйверами и оптимизация производительности старого ПК."
keywords:
  - "миграция Windows XP на SSD"
  - "клонирование HDD на SSD"
  - "Acronis для Windows XP"
  - "оптимизация старого компьютера"
  - "восстановление данных с поврежденного диска"
  - "драйверы для SSD"
---

Давно я ничего не писал. Все работа да работа. Но все исправил тот факт, что мне надо было в отпуск. И вот собственно в отпуске и началось веселье. У мамы был старенький компьютер за которым она работала. Обычная персоналка на AMD примерно 5-7 летней давности. На которой стоит Windows XP SP3  полностью лицензионный. И этот самый динозавр стал дико тормозить.

Решений тут как известно несколько: купить новый комп (дорого для мамы), поставить Linux (мама привыкла к Windows), обновить железо (что и было выбрано). Самое простое, что можно было сделать это обновить железо. Из железа было обновлено: старый посыпавшийся HDD 320GB заменен на новый SSD 240GB, заменена оперативная память (стояло 1+1 GB, а поставили 2+2 GB).

Переносить собственно информацию было самым относительно простым заданием, т.к. у мамы информации рабочей около одного гигабайта, а все остальное было забито игрушками и музыкой моего младшего брата. И на такие случаи у меня всегда с собой в моем походном рюкзаке несколько внешних жестких дисков. Один ZALMAN VE-400 1TB и три обычных внешних на 1ТБ и 500ГБ.

Первое, что необходимо было сделать, это перенести мамины данные. Но т.к. родной хард на котором стояла система посыпался по смарту, пришлось как-то выходить из ситуации. Мне было дико лень ставить с нуля семерку или даже икспишку. Но самым досадным было обнаружить отсутсвие 386 разрядности лайв-образ. Меня спас из ситуации тот факт, что у мамы всегда была копия документов на флешке (сам её к этому приучил), а так же нашелся в значках старый мультизагрузочный диск с хрюшей и несколькими утилитами для работы с хардами.

Обычное клонирование разделов Акронисом не получилось - он выдавал какие-то ошибки ("Критическая ошибка" без каких-либо расшифровок). После чего была успешная попытка сделать обычный образ диска в формате Акрониса и сохранить его в файл, что закончилось успешно. Далее этим же Акронисом этот файл я накатил на новый SSD-диск и, О ЧУДО(**!**) оно заработало.

После того, как образ был накачен и все место на новом диске было использовано, я поменял старый и новый нарды местами. Старая хрюшка запустилась без запинок с ощутимым ускорением (по словам мамы, ранее комп загружался минут за 5-7, а теперь за полторы(**!**)). На всякий случай обновил все драйвера и все готово!

На этом собственно всё!

ЗЫЖ Вот таким довольно дешевым способом произошла реанимация старого (и дорогого сердцу) железа.

А как решали подобные ситуации?

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
