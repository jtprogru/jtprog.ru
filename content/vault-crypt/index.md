---
categories: Work
cover:
  alt: work
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: work.png
  relative: false
date: "2015-06-18T21:12:00+03:00"
tags:
- vault
- cryptor
- virus
- восстановление данных
- ransomware
- windows
title: '[Work] Очередной шифровальщик'
type: post
description: "Практические советы по защите от шифровальщиков. Использование ShadowExplorer и точек восстановления Windows для минимизации потерь."
keywords:
  - "борьба с шифровальщиками"
  - "восстановление файлов ShadowExplorer"
  - "точки восстановления Windows"
  - "настройка защиты системы"
  - "VAULT ransomware"
  - "резервное копирование данных"
---

Сегодня чаша моего терпения была переполнена после сообщения от секретарей о том, что "мы ничего не делали, а оно теперь не открывается". Это дичайше бесит. И этот пост будет от части криком души, сплошным ИМХО, а от части прямолинейной попыткой свести к минимуму потери на тот случай когда "поймал". Я не буду тут разбираться в том, как шифровальщики работают, а просто предложу один из вариантов решения проблемы.

Как сказал один классный дядька:

> *«Для человеческой глупости нет патча…» © Кевин Митник*

И, поверьте, он был прав, когда это сказал. Но попытки хоть чему-то научиться на собственном опыте ни к чему хорошему не приводят в большинстве случаев. Это факт с которым трудно спорить. Моя персональная защита от шифровальщиков состоит из двух пунктов:

1. Я использую Ubuntu;
2. Я старюсь быть внимательным;
3. Я имею несколько почтовых аккаунтов;
4. Немножко поиграем с фильтрами для сообщений в почтовом клиенте;

Далее по порядку и немного подробнее о каждом отдельном пункте.

## Я использую Ubuntu

Да я на личном компьютере использую именно Ubuntu, а если точнее, то на текущий момент Ubuntu 15.04. К сожалению это только дома, а по корпоративным стандартам мне приходится использовать еще и Windows на работе. Использование "Не Виндовз" дает свои преимущества. Так же очень часто можно услышать фразы "под linux вирусов нет", "linux самые защищенные системы" и т.д. Не верьте! Это ложь и провокация. Я не говорю, что все Linux системы дырявые, нет! Просто в силу низкой популярности среди простых пользователей, которым всего-то надо "вконтактик", "ютьюб", "одноклассники", "мой мир" и чтоб "крутые игрушки тянул", под Linux системы пишут меньше всякого какашечного кода, но он есть. И поверьте какашечного кода под Windows гораздо больше, т.к. ее распространенность среди простых пользователей гораздо больше. Так же есть такие места (ГЭС например, или АЭС), где используют древние версии Windows - например Windows 98/2000/XP - в силу специфичности софта который там используется. Переписывать его никто не хочет и не станет. И даже больше скажу, там сразу после установки Винды отключают обновления системы. Причина?! Ответ прост - После некоторых обновлений системы семейства Windows могут умереть. И с этими ситуациями я сталкиваюсь все чаще. А там не обновляют и не ставят антивирусов потому, что "а хрен его знает что потом произойдет? может быть реактор/турбина остановятся или наооборот в разнос подут?! И тогда всем трындец!"

## Я стараюсь быть внимательным

Ну про внимательность можно говорить очень много. И из тех, кто много про нее говорит получаются высококачественные параноики, которые потом всех бесят. Но все же стоит и о ней упомянуть. Я всегда смотрю за тем, что я запускаю и уж тем более за тем какое вложение из письма я открываю. Но на работе (особенно это касается должности секретарей) с внимательностью по отношению к почте очень плохо обстоят дела. Через наших секретарш проходит просто гигантское количество писем. Им приходится перечитывать сотни писем в день и пересылать их с общего ящика компании на ящики отделов/руководства и т.д. И собственно как не сложно догадаться на этот ящик валятся просто тонны спама, который девочкам так же необходимо просмотреть и "оценить" спам это или нет. После некоторых реорганизационных мероприятий им поставили третий компьютер (два секретаря на одном ресепшене и у каждого свой круг ответственности), на который и стекалась вся эта каша из спама и небольшого количества ценных писем. И на этом выделенном компьютере они поймали шифровальщик. Благо после введенной мною политики по отказу от хранения ценной документации на рабочем компьютере все данные хранились на сетевых хранилищах. Документы из бэкапов мы восстановили. А почта в формате The Bat! не пострадала еще ни разу.

Так вот. Шифровальщик был `VAULT`. Подробнее про разные шифровальщики вы можете почитать на блоге [Владимира Мартемьянова,](http://vmartyanov.ru/) а конкретно про `vault` можно почитать например [тут](http://forum.drweb.com/index.php?showtopic=320137).

## Я имею несколько почтовых аккаунтов

У меня несколько почтовых аккаунтов на разных сервисах. Помимо рабочей почты, у меня есть личная почта, которая рабоает на моем хостинге и она ТОЛЬКО МОЯ (!). Получение писем с этого личного ящика настроено на почти всех гаджетах, которые у меня есть (ноутбук, компьютер, смартфон). Так же есть такие почтовые аккаунты, на тех же mail(.)ru, google(.)com и yandex(.)ru, которые используются как сборщики мусора. Ящики эти просматриваются кайне редко и исключительно для того, чтобы посмотреть "не пришло ли туда что-то важное". Просматриваются они мною исключительно через браузер, т.к. не вижу смысла собирать почту с этих "мусорных баков" по POP3 и забивать этим свой комп, а по IMAP не всегда удобно работать.

## Немножко поиграем с фильтрами для сообщений в почтовом клиенте

У меня на работе в Mozilla Thunderbird настроено несколько фильтров, которые сортируют почту на несколько категорий. Все письма которые идут в общей переписке (это корпоративные списки рассылки, включающие всех сотрудников) перемещаются автоматически в отдельную папку с "мусором" (не папка "Спам" и не папка "Корзина"). Все письма, которые идут на определенные внутренние списки рассылки относящиеся ко мне или моему отделу, складываются по своим папкам (одна папка для одного списка рассылки). все остальные так и валяются в папке "Входящие". В папку "Спам" идут сообщения, с пметкой "SPAM" выставленной почтовым сервером. Ну а в "Корзину" я удаляю вручную письма в которых я точно не буду нуждаться.

## А теперь предложение

После небольшего гуглежа я пришел к выводу, что полностью избежать ситуации "поймал шифровальщик" невозможно (хотя это и ежу понятно). Для домашних пользователей (у жены именно так и настроил на ноутбуке, потом проверил - все работает) предлагаю вариант решения с минимальными потерями.

Идем [сюда](http://www.shadowexplorer.com/downloads.html) и качаем программу ShadowExplorer. Можно скачать либо установщик, либо версию для запуска с флешки. Далее нам необходимо немного настроить свою систему для того чтобы снизить риск потери данных к минимуму. Для этого открываем свойства системы (Пуск -> Панель управления -> Система), далее нажимаем "Дополнительные параметры системы".

![SysInfo](https://jtprog.ru/wp-content/uploads/2015/06/SysInfo.png)

Перед нами откроется окно "Свойства системы" где мы открываем вкладку "Защита системы":

![SysInfo3](https://jtprog.ru/wp-content/uploads/2015/06/SysInfo3.png)

Вот тут то мы и настраиваем самое важное: включаем функцию восстановления системы и задаем объем резервируемый для восстановления наших данных. Выбираем диск и нажимаем копку "Настроить".

![SysInfo3](https://jtprog.ru/wp-content/uploads/2015/06/SysInfo3.png)

Отмечаем пункт "Восстановить параметры системы и предыдущие версии файлов", как показано на скриншоте. Это для надежности так сказать :-). Но можно и выбрать второй пункт "Восстановить только предыдущие версии файлов".

Эти действие необходимо проделать для каждого из доступных дисков, т.к. данная функция распространяется только на выбранный диск.

После этого просто приучитесь делать точки восстановления системы или настройте этот вопрос по такой [инструкции](https://jtprog.ru/windows-restore-point/) на нужную вам периодичность.

В дальнейшем все просто. В случае если вы поймали шифровальщик, то вы делаете откат системы с помощью средств восстановления и ваши файлы возвращаются к вам или, как вариант, вручную (при достаточной сноровке и достаточном умении пользоваться головой) удаляете пойманный вирус и с помощью программы `ShadowExplorer` восстанавливаете всё подряд или же те файлы, которые нужны.

На этом все! Profit!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
