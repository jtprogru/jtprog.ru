---
categories: Work
cover:
  alt: work
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: work.png
  relative: false
date: "2014-06-18T17:10:00+03:00"
tags:
- esxi
- work
- виртуализация
- Active Directory
- VMware
- репликация
title: '[Work] Знакомство с виртуальными серверами'
type: post
description: "Практический опыт настройки VMware ESXi: создание тестового стенда с Active Directory, решение проблем сетевых карт и синхронизации времени."
keywords:
  - "настройка VMware ESXi"
  - "виртуализация серверов"
  - "репликация Active Directory"
  - "установка виртуальных машин"
  - "синхронизация времени Windows Server"
  - "проблемы сетевых карт ESXi"
---

Задача в общем и целом была такова:
> Создать и запустить тестовый стенд с виртуальными серверами. При положительном результате данный стенд будет реализован на практике и в нем будут помимо виртуальных еще и физические сервера.  

Поставило руководство мне задачу: Сделать! В общем я ее и сделал=) Ситуация, мягко говоря, трудная сложилась у меня с самого начала. Но обо всем по порядку.

Есть сервер (физическая машинка с приемлемой конфигурацией - Core i3/16 GB RAM/320+250 Gb HDD/1000 Mb LAN), так же есть еще обычный офисный компьютер, ZyWALL USG 20, не особо кривые руки и не пустая черепная коробка.

На сервер мы поставили VMware ESXi 5.5.0 и сразу же запустили его.  Далее при подключении к указанному IP-адресу выдается страничка с предложением скачать приложение-клиент с официального сайта VMware или воспользоваться веб-интерфейсом. Мы как ленивые решили попробовать воспользоваться веб-интерфейсом и как результат у нас ничего не получилось. Оказывается, чтобы воспользоваться веб-интерфейсом необходимо скачать и установить с сайта VMware пакет VMware vCentre. Ставится он исключительно на серверные ОСи. Мы скачали, подняли виртуалку и установили на нее vCentre. Теперь заработал веб-интерфейс и через него стало доступно все и сразу. Он дает возможность создавать пуллы, виртуалки, клонировать и резервировать, делать "горячее" изменение аппартной конфигурации виртуальной машины, в общем все что только пожелаете.

Настройка и конфигурирование VMware ESXi 5.5.0 особенно и не распишешь =) Просто качаем образ, пишем, ставим =) Но есть одно НО! VMware ESXi не со всеми сетевыми картами работает. У нас возникла проблема именно такого характера. Решение нашлось довольно быстро. В помощь нам пришел сайт VMware на котором был написан способ решения проблемы с сетевыми картами которые не очень-то и любит. Проблема решилась довольно просто: с их сайта качается специальная утилита для работы с их же образами, так же качается драйвер для ESXi в специальном формате и с помощью данной утилиты впихивается в нужный образ. Далее система полностью переустанавливается.

Создаем 4 виртуальные машины, для примера и простоты представим, что они называются `Main-First`, `Main-Double`, `Office-Msk-First`, `Office-Msk-Double`. Устанавливаем на них Windows Server 2008 R2 + Active Directory (на `Office-Msk-First` и `Office-Msk-Double` так же ставим службу политики сети и доступа). Установив все выше указанное наступила самая важная и интересная на первый взгляд новичка в этом деле часть работы: необходимо настроить репликацию серверов между собой. Схема которую необходимо было реализовать мне была понятна и абсолютно проста:

- `Main-First` - сервер DC леса (на нем вертится весь AD и вообще он самый главный);
- `Main-Double` - с позволения сказать "брат-близнец" выше указанного `Main-First`;
- `Office-Msk-First` - серверочек для конкретного московского офиса;
- `Office-Msk-Double` - аналогично как и с `Main-Double` он является "братом-близнецом" `Office-Msk-First`;

И так! После установки ОС и AD возник спорный вопрос с коллегами по поводу количества сетевых интерфейсов на выше указанных виртуальных машинах для общения друг с другом и с машинами пользователей =) Ответ на этот вроде бы простой вопрос кажется вполне логичным - нам понадобится два интерфейса на каждом сервере - один для рабочих мест, а второй для общения с другими серверами. И как вы догадались я с коллегами начал пытаться настроить именно такой вариант. Но после двух дней ~~мозгоклюйства~~ пришли к общему мнению, что на каждом сервере вполне достаточно одного сетевого интерфейса.

Так же перед нами стоял выбор: однодоменная сеть или многодоменная. Выбор пал на однодоменную и сейчас постараюсь объяснить почему.

Во-первых, на данный момент у нас в распоряжении есть действующая однодоменная сеть. И поскольку в дальнейшем планируется перенос рабочих серверов в виртуальную среду и частичная реорганизация сети предприятия в целом, то мы решили оставить и в виртуальной среде такую же сеть. "Братья близнецы" серверов созданы как резервные сервера на случай выхода из строя основных.

И во-вторых, при переносе AD, а конкретно учетных данных пользователей/компьютеров, групп пользователей/компьютеров и групповых политик безопасности из однодоменной в многодоменную сеть могут возникнуть б**О**льшие проблемы, чем при переносе в однодоменную. В тонкости настройки AD и самой  Windows Server 2008R2 вдаваться не буду потому, что таких мануалов в сети полным полно и я не горю желанием плодить еще один такой мануал. Единственный момент который укажу явно на всякий случай это то, что мы повесили в настройках AD все DC на один сайт. Причина этого проста - необходимо было организовать репликацию между мерверами представительств и офисов. А поскольку все КД у нас висят на одном сайте, то и реплицируются между собой просто прекрасно даже без особой заморочки с настройками доверительных отношений.

Наконец-то после всех установок и настроек все DC смогли нормально общаться между собой. Все настройки заключались в установке ОСей и AD. Репликация проходила прекрасно, за исключением тех моментов когда, в самом начале, происходили сбои с настройками времени в самих ОСях. Проблема была в том, что интернетом для наших сервером служил ZyWALL, который и имел собственно выход в сеть интернет. Поскольку необходимо включение опции автоматического обновления времени, то время на КД настроивал имено ZyWALL, а не удаленный сервер времени. Это самая распространенная ошибка репликации. Если время на серверах не синхронизировано, то репликации просто не пройдут из-за разногласий во времени.

И так! Подведем итоги: Виртуальные сервера это очень удобно и просто! На данным момент все это дело у меня жужит в режиме тестового стенда. В дальнейшем планируется переносить в рабочую сеть. И об этом я так же постараюсь написать.

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
