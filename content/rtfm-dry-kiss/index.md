---
title: "[Opinion] Документация, Сухой поцелуй и джуны"
date: 2021-07-16T16:00:00+03:00
categories: "Opinion"
tags: ["rtfm", "kiss", "dry", "documentation", "junior"]
type: "post"
author: "jtprogru"
description: ""
showToc: false
TocOpen: false
draft: false
hidemeta: false
disableShare: false
cover:
    image: "cover.jpg"
    alt: "Cover"
    caption: "Photo by [Sigmund](https://unsplash.com/@sigmund?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/s/photos/documentation?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)"
    relative: false
comments: false
---

Привет, `%username%`! Современный мир обязывает быстро получать новую информацию и очень много знать. Давай по-рассуждаем о том, как быть и что делать, ну и про джунов поговорим. Ну и в целом перетрём за жизнь о доках, джунах и прочем.

## Немного терминологии

Для тех, кто родился раньше, чем к власти пришел действующий президент, аббревиатура RTFM не пустой звук (олды тут?).

**RTFM** довольно старое сокращение, которым часто пользовались те, кому задавали "нубские" вопросы. Значило оно "Read The Following Manual" (рус. «обратитесь к прилагаемому руководству»), но чаще использовалось в сленговом переводе как "Read The Fucking Manual" (рус. "читай долбаную документацию").

Собственно говоря, раньше все было по другому – не лучше и не хуже, просто по другому. И вот с распространением информации раньше было очень туго. Не было телеграм-каналов и телеграм-чатов, куда новичок мог зайти и задать вопрос. Были лишь man'ы, поэтому в 99% случаев все ссылались на нее.

**DRY** чуть более свежее сокращение, которое расшифровывается как "Don’t repeat yourself" (рус. «не повторяйся»). Считается одним из принципов разработки ПО, ключевым моментом которого является переиспользование кода.

Короче, копипастинг – это зло! Тут я согласен на все 200%. А вот формирование из определенных кусков собственного кода т.н. библиотек/модулей, которые можно будет в дальнейшем заюзать в новом проекте – это прям маст хэв современности!

**KISS** сокращение, приписываемое американскому авиаконструктору Джонсону Кларенсону. Расшифровывается как «Keep it simple, stupid» или «Делай проще, тупица» (привет [2Pizza](https://t.me/topizza) ;) ). Основной посыл фразы – "не надо усложнять". Из этой же оперы мне очень нравится (да и приучили меня со школы) правило: "Лучшее – враг хорошего!"

В общем не пытайся усложнять то, что и так хорошо. И наверняка прочитав это, некоторые вспомнят фразу "Работает – не трогай!" И вот с этим "не трогай" у меня не редко случаются проблемы или недопонимания, но об этом позже.

## Что делать и как быть

Определившись с некоторыми важными и нужными терминами, давай попробуем понять как оно всё связано с тем, чтобы быстрее потреблять информацию и держать ее в актуальном состоянии. Мы уже знаем, что в преимущественном большинстве такая необходимость диктуется рынком и навязанным этим же рынком "[Синдромом самозванца](https://ru.wikipedia.org/wiki/Синдром_самозванца)", который ну очень часто встречается среди коллег по цеху.

И ведь если немного пораскинуть мозгами, то они – все три ключевых термина – очень даже связаны с процессом потребления и актуализации знаний. Давай поясню более развернуто на примере, который мне ближе всего.

Вот тебя сослали (ну или ты сам пришел) в новый проект, где используется стек, с которым ты раньше не работал. Что ты будешь делать в первую очередь? Правильно! Просить предоставить документацию по проекту. Это вполне логично, по крайней мере в моей вселенной. Да, можно конечно и попросить коллег рассказать тебе о проекте, но:

- Мне не хотелось бы отвлекать коллег от работы (я убежден что в первую очередь с документации надо начинать в таких случаях);
- Коллег, которые могут рассказать, может и не быть на проекте когда проект новый, а ты единственный;

Если ты один на новом проект (считай что в поле воин), то вопрос формирования документации – это напрямую к тебе. Как минимум тебе самому потом проще будет, а коллеги которые буду приходить к тебе в помощь в дальнейшем станут безмерно благодарны. Но вернемся к примеру.

Ты начинаешь читать про те технологии, котрые используются на этом новом проекте. Гуглишь, ищешь всякие статьи на [Habr](https://habr.com), но рано или поздно (и лучше именно рано) ты приходишь к женщине, которая всегда тебе даст ответы. Документация по тулзам и фреймворкам, которые используются у тебя на проекте. Читая доку, так или иначе приходится делать заметки чтобы не забыть какие-то важные моменты. Ну вот считай эти заметки собственной документацией, которую возможно придется кому-то показывать коллеге, разработчику, начальнику.

В общем тебе надо очень быстро впитать в себя довольно большой объём информации (да – я вернулся к тому с чего начинал). И если снова взглянуть на пример выше, то ты для актуализации своих знаний читаешь доку – RTFM! А благодаря ведению каких-то заметок ты начинаешь формировать документацию. Когда-то давно этот блог задумывался именно как заметочник, чтоб не искать нужные куски документации при решении каких-то проблем.

## Повторение – мать учения

Наверняка ты слышал не раз такую фразу, особенно в школьные годы. Повтори много раз одно и то же чтобы заучить это. Я даже больше скажу: я многим вайтишникам рекомендую начинать не со всяких ansible'й или terraform'ов, а именно руками первое время выполнять какие-то действия. И в этом я вижу определенную цель. Давай на примере поясню, чтоб наверняка было понятно (а если не станет понятно – заходи в чат).

Есть два (нет, не стула) джуна и они оба будут делать ровно то, что ты скажешь им, но есть условие. Первый должен будет делать исключительно руками, а второй исключительно автоматизацией (ansible, terraform, etc). Обоим ставится задача: есть три сервера с Linux (у каждого свои), на них надо поставить PHP-приложение, Nginx, NodeJS, MySQL. 

Если принять факт, что оба джуна имеют одинаковые навыки и знания, а так же не обращать внимание на то, что они за разное время выполнят эту задачу, то можно будет прийти к неожиданному выводу. Первый (тот который руками работал) вероятнее всего сможет рассказать тебе где и какие конфиги, где лежат логи и даже какой-то примитивнейший траблшутинг выполнить сможет. В то же время второй (который с ansible'м) вероятнее всего не сможет все то же самое т.к. он не трогал руками тех вещей, которые позволят ему составить эту картину в голове. Второй джун будет больше копипастером и максимально типичным выпускником обычного онлайн-пту "ЯщикСноровки" обещающего офферы на 900kns сразу после выпуска (таких "выпускников" довольно много, но справедливости ради – есть и нормальные и толковые ребята, которые научились многому самостоятельно).

Думаю можно сделать вывод о некоторых моих советах и подходах в работе с джунами: первое время (в самом начале карьеры особенно), стоит больше уделять именно ручной работе. Ручная работа позволит джуну погрузиться глубже в используемый стек. Как минимум лишним это точно не будет. И сразу замечу, что я не говорю на это время запретить джуну использовать ansible, terraform, etc. Нет! Я считаю, что самым правильным будет подход, когда джун (я и сам так часто делаю, да) сначала что-то выполняет руками, а потом переносит это на всякие ansible и ему подобные системы.

## KISS или Работает – не трогай!

Почему важно делать просто? Ну тут как мне кажется вполне себе уместен анекдот про то, как программисту [доверили поддержку чужого проекта](https://twtr.jtprog.ru/tceyRuICJpN). И знаешь почему этот анекдот тут уместен? Потому что KISS, а еще не надо усложнять и ломать то, что и так работает.

У меня уже выработанное правило на эту тему: сначала я делаю максимально просто руками, а после делаю для этого автоматизацию (я уже сказал об этом выше). Можно делать сразу максимально автоматизированно и правильно с точки зрения best practice, но есть один нюанс: это требует больше времени нежели "костылестроение". А я же на работе работу работаю – а работа требует "здесь и сейчас" результат и деньги принесенные этим результатом. Довольно часто мы забываем про это, потому что мы – айтишники всех мастей – так устроены.

Для меня, как и для многих коллег безумно интересно пробовать что-то новое. Новый фреймворк, новую тулзу, новые сорта крафтового пива. Не редко это приводит к усложнению систем. Я много раз сталкивался с таким – приходишь в новое место, прошлый админ привнес ansible (круто!), начинаешь раскуривать и понимаешь, что это жопа! Вот прям не реальная жопа, потому что в попытке упростить свою жизнь, прошлый админ обмазал все этим ansible'м и приправил сверху bash'ем. А на десерт ни одного README или странички в конфлюенсе – "ну тут и так же все понятно!"

Понятно только тебе и только до того момента, пока ты с этим работаешь постоянно. Стоит тебе самому перестать этим пользоваться на ежедневной основе, или передать кому-либо на саппорт, сразу становится непонятно.

Поэтому я стараюсь делать просто, а главное, где бы я не работал, я всегда помню одну важную истину: я не буду работать на этом проекте и стеке всю свою жизнь и меня тут когда-то кто-то сменит. И вот чтоб не говорили потом "этому мудаку, который тут все делал надо оторвать всё что торчит и поменять местами, потому что нихрена непонятно", я стараюсь делать так, чтоб хоть простой README.md или статейка хоть в личном пространстве Confluence обязательно оставалась.

Ну и на тему "Работает – не трогай!" у меня частенько всплывали в практике ситуации, когда эта фраза была прям "НЕПОКОЛЕБИМОЙ ИСТИНОЙ" у особо скилловых и олдовых админов. У таких ребят и работаю серваки по десятку лет без ребутов, даунтаймов, обновлений и патчей безопасности. Стабильность это конечно хорошо, но когда твоим smtp relay начинает пользоваться какой-нибудь ботнет, то у тебя начинаются проблемы и попоболи.

Я за здравый баланс! Ну вот сам посуди: ты примерно раз в пару месяцев пусть и руками, пусть и с даунтаймами делаешь обновление сервера. Все дыры в системе закрываются с обновлениями. Постепенно обновляются ядро, постфиксы и прочая сопутствующая хрень. И ведь при этом ты совершенно не усложняешь систему! Оно все просто и максимально работоспособно!

## Миша, а ты о чём вообще?

Собственно да! О чём это я? А я собственно говоря о том, что документация это такая мифическая вещь, про которую многие забывают и совсем не думают. Именно документация по [Celery](https://docs.celeryproject.org/en/stable/) и [django-celery-beat](https://django-celery-beat.readthedocs.io/en/latest/) позволили мне начать писать приложеньку. Простую парсилку для RSS и дальнейшей отправки в TG новостных дайджестов. Ни один чат не помог в этом, а именно документация.

Я хочу сказать, что первое чему стоит учиться – читать документацию и правильно делать запросы в гугл. Ну и если ты джун, решивший попробовать себя в деле админства (Inrfastructure Engineer, SRE, DevOps), но не знаешь с чего начать, то у меня для тебя хорошая новость: я понял, что я готов знаться менторством. Если ты считаешь, что тебе нужна помощь наставника в самообучении, то просто приходи в личку в телегу и пиши "Мне нужен ментор". Общий план следующий (нюансы индивидуальны):

- Знакомство;
- Определение целей;
- Первое собеседование;
- САМООБУЧЕНИЕ;
- Итоговое собеседование;

Я не просто так выделил самообучение, потому что это ключевой момент. Если ты не готов учиться самостоятельно, то тебе стоит подумать на тему забыть про работу в IT. Если же ты всё-таки уверен в то, что готов заниматься самообразованием, то обращайся. Со своей стороны я буду помогать тебе найти правильный путь в решении проблемных вопросов.

Короче если ты чувствуешь в себе силы к самообучени, обращайся! А на этом у меня всё!


---
Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://t.me/jtprogru_chat), а так же подписывайся на [канал](https://t.me/jtprogru_channel).
