---
categories: howto
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: howto.png
  relative: false
date: "2015-01-10T19:56:11+03:00"
tags:
- the bat
- outlook
- windows
title: '[HowTo] Перенос почты с The Bat в Outlook'
type: post
description: "Пошаговая инструкция по миграции почты из The Bat! в Microsoft Outlook. Экспорт EML-файлов и импорт в Outlook."
keywords:
  - "перенос почты The Bat в Outlook"
  - "экспорт EML из The Bat"
  - "импорт писем в Outlook"
  - "миграция почтовых клиентов"
  - "конвертация почты Windows"
  - "работа с .eml файлами"
---

Возникла проблема: Надоел сотруднику `The Bat!` и он захотел `MS Outlook` при условии сохранения всей базы писем. Для сотрудников на должностях манагеров-продажников почта, к сожалению, фактически ключевой инструмент. При условии покупки пакета `MS Office` на каждого сотрудника глупо было закупать еще несколько десятков лицензий на `The Bat!`

А эта глупость была в старые времена, еще до моего прихода в компанию. Тогда было так: приходит новый сотрудник и его спрашивают "Какой почтовой программой Вы предпочитаете пользоваться?". С одной стороны - это прекрасно и хорошо, но с другой стороны - ~~идите нахер господа~~ учитесь пользоваться разными решениями и развивайтесь ~~блять~~!

Сейчас я так не делаю и просто ставлю по дефолту всем `MS Outlook` в составе всего офисного пакета от мелкософта. Были глупые растраты на ненужное ПО. Сейчас мы с ними боремся всеми путями.

Возвращаясь к нашей проблеме. Для переноса почты из `The Bat!` в `MS Outlook` необходимо проделать следующие манипуляции.

Этап экспорта из `The Bat!`:

1. На жестком диске создайте временные директории для каждой папки вашего e-mail аккаунта (`Inbox`, `Sent`, `VasyaMail`, ...);
2. В `The Bat!`, выберите папку;
3. Выберите все сообщения в папке (`Ctrl+A`);
4. `Tools -> Export Messages -> Message files (.EML)`, сохраните в соответствующей директории из созданных в пункте `1`. Каждое сообщение будет сохранено отдельным файлом;
5. Повторите `2-4` для всех папок письма из которых хотите перенести;

У вас должно получится несколько (или одна) директорий заполненными `*.EML` файлами, типа `00000001.EML`

Этап импорта в `Outlook`:

1. В `Outlook`'е создайте аккаунт, в который вы хотите перенести почту из `The Bat!`;
2. Там же создайте все те же ящики, которые есть в переносимом аккаунте с `The Bat!`;
3. Откройте `Windows Explorer`'ом одну из директорий созданных на Этапе экспорта в пункте `1` и выберите все `.eml` файлы (`Ctrl+A`);
4. Перетяните (`drag-and-drop`) эти файлы в Outlook прямо на соответствующий ящик. Всё!;
5. Повторите `3-5` для остальных ящиков;

Вот собственно и все. Процедура нудная и не интересная. Сразу оговорюсь, что это удобно делать для отправленной почты дабы сохранить все написанные письма которые нужны. Так же это удобно было в нашей ситуации, когда была произведена замена почтового сервера и далеко не все входящие письма для пользователей были доступны для повторного выкачивания почтовым клиентом.

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
