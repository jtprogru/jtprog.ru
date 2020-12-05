---
title: '[Opinion] Что ты такое – DevOps?'
date: 2020-11-09T22:25:00+03:00
categories: 'Opinion'
tags: ["devops", "opinion", "sysops"]
type: 'post'
author: "JTProg"
description: "Очередная статья про DevOps"
showToc: false
TocOpen: false
draft: false
hidemeta: false
disableShare: false
#cover:
#  image: "<image path/url>"
#  alt: "<alt text>"
#  caption: "<text>"
#  relative: false
comments: false
---

Привет, `%username%`! Последние несколько лет у всех на слуху такой термин как `DevOps`. И скажу больше – я даже нанимал иногда людей на позицию `DevOps`. Но вот на просторах интернета очень много статей на тему, что это такое и эта будет еще одной – отражающей мое мнение о том, что или кто этот ваш `DevOps`.

## Определения

Начнем с того, что `DevOps` – это составное слово от `Developers` (разработчики) и `Operations` (админы/инфраструктурщики). Главное, что нужно запомнить: `DevOps` – это методология (набор рекомендаций и практик – если так проще понимать). Так же определимся с понятиями, которые так или иначе используются при упоминании `DevOps`:

* `Collaboration` (Совместная работа);
* `Continuous Integration` (`CI`, Непрерывная интеграция);
* `Continuous Testing` (`CT`, Непрерывное тестирование);
* `Continuous Delivery` (`CD`, Непрерывная поставка);
* `Continuous Monitoring` (`CM`, Непрерывный мониторинг);
* `Automation` (Автоматизация);

Далее обо всем этом подробнее. А для начала условимся в следующем:

### Совместная работа

Тут все довольно просто: для бОльшего "погружения" в идеологию и методологию `DevOps` обе составляющие – разработчики и инфраструктурщики – должны погрузиться в работу друг друга. Инфраструктурщики/сисадмины должны погрузиться и понять: что именно делают разработчики, какие текущие задачи они решают, какой стек технологий используется, как в целом они работают. Разработчики же в свою очередь тоже должны погрузиться и понять: что именно делают админы, как они запускают приложение, в каких условия в реальности работает приложение.

Как только оба "лагеря" поймут, чем занимаются и люди "с другой стороны", тогда начинается совместная работа. Именно тут начинает выстраиваться и формироваться "мониторинг приложения", а так же построение дороги к `CI`.

Если упростить, то хороший разработчик должен понимать в каких условиях работает его приложение, а админ должен понимать, что именно он запускает.

### Непрерывная интеграция

`CI`  решает несколько задач, одной из которых являются автоматический запуск тестов на свежей версии кода. И да это так! Просто некоторые забывают, что кроме запуска тестов есть еще задачи, которые можно и нужно автоматизировать и добавить в `CI`. Такими задачами являются, например: сбор метрик во время тестирования, merge из develop/feature в master ветку, build каких-либо артефактов (jar'ники, docker image, rpm-пакет, etc), публикация данных артефактов в условный [Nexus](https://help.sonatype.com/repomanager3)/[Docker Hub](https://hub.docker.com).

Ключевое слово – Интеграция – четко описывает то, что требуется делать для достижения целей. Интегрировать команды (QA, Operations, Developers, Analytics) между собой, а так же дать возможность коммуницировать между собой и возможность видеть, что происходит "у коллег по цеху". Для этого и придумываются/находятся инструменты автоматизации и коммуникации внутри команд.

Непрерывная интеграция как раз именно о том, что на протяжении всего жизненного цикла приложения/фичи происходит "непрерывное" интегрирование команд (QA, Operations, Developers, Analytics) между собой. Именно интегрирование команд в первую очередь должно происходить, а "автоматический запуск тестирования" – далеко не первостепенное.

### Непрерывное тестирование

Тут кмк все довольно просто: надо тестировать всё, ну или хотя бы стремиться к этому. Даже не смотря на то, что я выше упомянул о том, что "автоматический запуск тестирования" – это далеко не первостепенное, сделать это стоит одним из первых пунктов. Как минимум это довольно просто – добавить в `pipeline` строчку  `npm run test` одним из этапов. Если тесты провалились, то `merge` в `master`-ветку запрещен (условно).

Простой пример: есть некоторая dev-площадка, которая работает только для разработчиков. На данной площадке, для упрощения жизни все требуемые сервисы и компоненты развернуты в Docker, а описаны в одном `docker-compose.yml`. Есть контейнер `front` с условным Nginx и есть контейнер `ssr` с условным NuxtJS. Сборка нового docker image происходит очень просто, но есть один нюанс – иногда сборка проходит успешно, а после поднятия новой версии контейнера с `ssr` площадка падает. Следовательно просто жизненно необходимо "затестировать" данный момент.

Сделать это кмк довольно просто: сразу после сборки нового docker image поднимать его "где-то рядом" и проверять работоспособность. Разработчики должны предусмотреть "ручку" внутри своего приложения и предоставить ее админам. Админы же в свою очередь настраивают `pipeline` таким образом, что после сборки нового docker image происходит его запуск, а так же "дёргание ручки". Если ответ присутствует (условный `OK`), то можно смело тушить данный контейнер и обновлять уже в `docker-compose`.

Теперь мы точно знаем, что если кто-то из разработчиков накосячит в коде, то другие смогу продолжать работу с площадкой.

### Непрерывная поставка

`CD` отвечает за ту часть пути приложения, которую можно смело назвать "последняя миля" – выкатывание кода на Production. На текущий момент все еще есть такие команды/разработчики, которые релизятся по scp/ssh/ftp и делают это примерно раз в 1-2 недели самостоятельно и руками. Возможно у некоторых есть bash-скрипты для упрощения своей жизни. В некоторых ситуация это "может быть оправдано", а в некоторых такой вариант не допустим!

В большинстве случаев "ручной релиз" планируется на максимально тихое время для проекта – условные 2-4 часа ночи по Мск т.к. в это время меньше всего нагрузка на сайта и "не заметят" уже привычных 5-10 минут с ошибкой `502`/`504`. И вроде бы уже все привыкли, дежурный админ страхует разраба, разраб релизит – все хорошо! НО! В один прекрасный момент разработчик или админ приходит к своему начальнику и говорит: "А давайте мне премию и/или прибавку за то, что я тут ночами не сплю когда релизы идут". И запрос вполне обоснованный кмк, только вот далеко не каждый решится об этом сказать начальству, да и не каждый начальник поймет, что этот обоснованно.

Взглянем на картину с другой стороны: Непрерывная поставка говорит нам о том, что код всегда можно выкатить на Production (руками/автоматически – не важно). Главное, что важно – сколько времени проходит с момента появления идеи/фичи/запроса клиента/выявления бага до момента когда код с этими правками приезжает на Prod. В ситуация описанных выше – ручками ночью по ftp – срок в 1-2 недели это не о том, что "от и до". Срок от появления фичи, до ее появления на проде может доходить до нескольких месяцев.

`CD` говорит о том, что релизы "можно делать в любое время"! Вот прям в любое: в 9:00, в 12:12, да хоть в 17:55! Непрерывная поставка кода – это о том, что можно и нужно сократить время между появлением идеи и ее опробыванием в бою. А появление условной фичи на проде нас автоматически подводит к следующему пункту.

### Непрерывный мониторинг

`CM` отвечает за постоянный сбор метрик о состоянии вашего приложения с момента пуша в фича-ветку. Я не упомянул "ДО", т.к. это бы говорило о том, что в определенный момент мы перестаем мониторить наше приложение. Смею заметить, что такой момент есть – релиз новой версии. И это вполне логично – мы не можем мониторить то, что уже "выключено". Мониторингу подлежит только то, что есть сейчас и "включено". И я не только о Production, а в целом обо всем жизненном цикле приложения.

Непрерывный мониторинг очень часто (я заметил такую тенденцию) подают в докладах как "нарисуйте в Grafana красивые графики и все поймут что DevOps действительно нужен" – я уже писал об этом у себя в [канале](https://t.me/sysopschannel/3768). На самом деле это немножко не так от слова "совсем". Мониторинг – он больше про то, что все члены команды (QA, Operations, Developers, Analytics) могут видеть одну и ту же информацию из одного источника – системы мониторинга (Zabbix/Prometheus/etc). Оперируя "красивыми графиками" и коррелируя данные между собой, а так же взгляды со своей стороны – каждый член команды начинает видеть аномалии в поведении всей системы, а не только "той фичи которую он пилит".

Мониторинг должен выполняться на всех этапах – во время запуска "unit тестов" (если конечно такое реализуемо). Если у вас есть возможность выполнять в автоматическом режиме нагрузочное тестирование – это просто великолепно! Выполняйте его и мониторьте всё!

### Автоматизация

Автоматизация – это автоматизация! Конец, занавес, спасибо, Кэп!

Если конечно порассуждать, то Автоматизация как таковая проходит через все предыдущие составляющие. Добавление того же `.gitlab-ci.yml`, подключение runner'ов к проекту в GitLab'е, написание bash-скриптов или ролей/плейбуков в ansible для выполнения каких-либо задач. Всё это автоматизация!

Автоматизация – перекладывание ручного труда админов/разрабов на кремниевые мозги компьютера.

## Как внедрять

Довольно часто приходят с вопросом: "Как внедрять этот ваш DevOps?". Однозначного ответа нет и быть, как мне кажется не может, хотя бы потому, что все компании разные, коллективы все разные, продукты все разные.

Лично мое мнение: DevOps является определенной стадией взросления компании и подхода к работе с её продуктом. Просто потому, что это мое мнение. Я действительно считаю, что к внедрению нельзя подойти в режиме "Нам срочно надо".  DevOps не про внедрение каких бы то ни было технологий и инструментов. Необходимо задаваться вопросами, до того как начинать что-то внедрять. Если ответ на вопрос "Зачем вам DevOps?" будет в духе "Стильно! Модно! Молодежно!", то лучше сразу задуматься – "А всё ли правильно в вашей жизни?". А если ответ в духе "Чтобы решить такую-то попоболь", то поверьте – вы уже на правильном пути.

## Итого

Мы прошлись по всем составляющим DevOps, но так и не дали ответ на вопрос: "Что же это такое?". Скажу сразу – ответ на данный вопрос, это только мое личное мнение и оно может отличаться от вашего.

`DevOps` – это набор рекомендаций и практик, направленных на решение задач бизнеса через изменение подхода к разработке и "обслуживанию" разрабатываемого продукта.

### Ссылки

Тут я подобрал список материалов, на которые я опирался при составлении статьи.

1. https://habr.com/ru/company/flant/blog/322686/
2. https://habr.com/ru/company/itsumma/blog/525070/
3. https://www.itexpert.ru/rus/biblio/detail.php?ID=16167
4. <https://leadstartup.ru/db/devops>
5. <https://aws.amazon.com/ru/devops/what-is-devops/>
6. <https://azure.microsoft.com/ru-ru/overview/what-is-devops/>
7. <https://habr.com/ru/company/oleg-bunin/blog/448492/>

На этом всё! Если с чем-то не согласны или вам есть что сказать или как-то дополнить, то жду в [чате](https://t.me/sysopschat)!