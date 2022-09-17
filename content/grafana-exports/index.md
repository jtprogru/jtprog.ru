---
categories: Develop
cover:
  alt: develop
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/dreamwolf97d61e)'
  image: develop.png
  relative: false
date: "2020-03-11T22:50:00+03:00"
tags:
- grafana
- export
- python
title: '[Develop] Экспорт dashboards/datasource из Grafana'
type: post
---
Привет, `%username%`! Небольшая заметка о том, как не пролюбить (с любовью настроенные) дашборды в [Grafana](https://grafana.com) если вдруг понадобилось перенести хранение настроек с SQLite на MySQL.

Можно поодному экспортировать по одному все дашборды вот таким образом:

1. Нажимаем в WebUI кнопочку `Share`;
2. Переходим на вкладку `Export`;
3. Дальше либо `Save to file`, либо `View JSON`;

Это очень удобно и прекрасно ровно до тех пор пока у вас количество дашбордов не велико. Но если у вас количестов дашбордов 10-20-50, то вам очень быстро наскучит тыкать мышкой. Следовательно возникает вопрос: *~~Доколе блэт?!~~* **Как сие действие автоматизировать?**

Ответ довольно простой - *курлы* :) А если серьезно то и curl'ить и python'ить приедтся для работы с API Grafana.

Начнем по порядку. Начнем с того, что вытащим все дашборды котоыре у нас есть. Для этого есть один замечательный [скрипт](https://gist.github.com/jtprogru/b5dd939621866057770569dc86481af6), который я благополучно нагуглил на просторах интернета. С этим скриптом всё более чем просто. Получаем API-Key для доступа в Grafana, указываем действие (`export`/`import`), полученный API-Key, директорию в которую хотим экспортнуть данные (или из которой импортнуть хотим). Все более чем просто.

Дальше мы хотим выгрузить все `Datasources` - ну не просто ж так мы занялись этим делом. Тут то нам и понадобится `curl`:

```bash
curl -H "Content-Type: application/json" \
-s "https://grafana.example.ru/api/datasources" \
-u admin:grafana | jq -c -M '.[]' |  split -l 1 - path/to/datasources/
```

На выходе имеем директорию `path/to/datasources/` со всем источниками данных, которые у нас есть на текущий момент в Grafana. Каждый Datasource будет в отдельном файле.

Собственно импортировать эти данные так же через `curl`:

```bash
for i in path/to/datasource/*; do \
    curl -X "POST" "https://grafana.example.ru/api/datasources" \
    -H "Content-Type: application/json" \
    --user admin:grafana \
    --data-binary @$i
done
```

И наши Datasources инмортировались как тут и были.

Собственно говоря вся эта канитель затевается для того чтобы перенести все настройки Grafana из `SQLite3` в `MySQL`. На вопрос "**Зачем?**" ответ простой - **Потому что!**.

Можно пойти проще и воспользоваться прямым переносом данных из SQLite в MySQL и для этого есть утилитка в виде написанная на Python. Почитать можно про неё вот на официальном [Github](https://github.com/techouse/sqlite3-to-mysql), а установить можно вот так:

```bash
python3 -m pip install sqlite3-to-mysql
```

Последний способ я сам пока еще не тестировал, но как попробую - сразу расскажу. А на этом всё!

---
Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).
