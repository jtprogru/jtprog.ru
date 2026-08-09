---
aliases:
  - '/grafana-exports/'
categories: ["Develop"]
cover:
  alt: develop
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: develop.png
  relative: false
date: "2020-03-11T22:50:00+03:00"
lastmod: "2026-08-09T12:00:00+03:00"
tags:
- grafana
- export
- python
- curl
- api
- dashboard
- datasource
- automation
- migration
- sqlite
- mysql
- json
- monitoring
- visualization
title: 'Экспорт dashboards/datasource из Grafana'
type: post
description: "Экспорт дашбордов и datasource из Grafana через API: service accounts вместо устаревших API-ключей, выгрузка по UID скриптом — и почему лучше держать всё в provisioning."
keywords: ["grafana export dashboard", "grafana export datasource", "grafana api", "автоматизация grafana", "миграция grafana", "grafana sqlite to mysql", "python grafana api", "curl grafana api", "резервное копирование grafana", "мониторинг", "визуализация данных"]
---
Привет, `%username%`! Небольшая заметка о том, как не пролюбить (с любовью настроенные) дашборды в [Grafana](https://grafana.com) если вдруг понадобилось перенести хранение настроек с SQLite на MySQL.

> 🔄 **Обновлено 2026-08-09.** Пост написан под Grafana 6, с тех пор поменялась аутентификация в API: обычные API-ключи объявлены устаревшими в Grafana 9.1 и выпилены в 11-й версии, вместо них — service accounts. Команды ниже рабочие, но токен надо получать по-другому: см. [«Аутентификация в API сегодня»](#аутентификация-в-api-сегодня). Появился и способ вообще не заниматься экспортом руками — [provisioning как код](#а-лучше-не-экспортировать-вовсе).

## Руками через WebUI

Можно поодному экспортировать по одному все дашборды вот таким образом:

1. Нажимаем в WebUI кнопочку `Share`;
2. Переходим на вкладку `Export`;
3. Дальше либо `Save to file`, либо `View JSON`;

Это очень удобно и прекрасно ровно до тех пор пока у вас количество дашбордов не велико. Но если у вас количестов дашбордов 10-20-50, то вам очень быстро наскучит тыкать мышкой. Следовательно возникает вопрос: *~~Доколе блэт?!~~* **Как сие действие автоматизировать?**

Ответ довольно простой - *курлы* :) А если серьезно то и curl'ить и python'ить приедтся для работы с API Grafana.

## Аутентификация в API сегодня

Здесь главное расхождение с оригинальным постом. В 2020-м доступ к API давали обычные API-ключи из `Configuration → API Keys`. В Grafana 9.1 их объявили устаревшими, в Grafana 11 раздел из интерфейса убрали совсем. Замена — **service accounts**: `Administration → Users and access → Service accounts`, создаёшь аккаунт, выдаёшь ему роль (для экспорта хватит `Viewer`, для импорта нужен `Editor` или `Admin`) и генерируешь токен.

Дальше токен подставляется в заголовок `Authorization`:

```bash
export GRAFANA_URL="https://grafana.example.ru"
export GRAFANA_TOKEN="glsa_xxxxxxxxxxxxxxxxxxxx"

curl -sS -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
  "${GRAFANA_URL}/api/search?type=dash-db" | jq -r '.[].uid'
```

Заодно обрати внимание на две вещи в примерах ниже. Basic auth вида `-u admin:grafana` в них ещё встречается — он до сих пор работает, но пускать пароль администратора в командную строку не надо, он останется в истории шелла и в логах процессов. И `?type=dash-db` в поиске: без него в выдачу попадут ещё и папки.

Ещё поменялось API самого дашборда. Ручка `/api/dashboards/db/:slug` из старых скриптов давно удалена, сейчас обращаться надо по UID:

```bash
# выгрузить один дашборд по UID
curl -sS -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
  "${GRAFANA_URL}/api/dashboards/uid/abc123" | jq '.dashboard' > dashboard.json

# выгрузить все разом
for uid in $(curl -sS -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
    "${GRAFANA_URL}/api/search?type=dash-db" | jq -r '.[].uid'); do
  curl -sS -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
    "${GRAFANA_URL}/api/dashboards/uid/${uid}" | jq '.dashboard' > "dashboards/${uid}.json"
done
```

## Скриптом через API

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

Последний способ я сам пока еще не тестировал, но как попробую - сразу расскажу.

## А лучше — не экспортировать вовсе

Спустя годы главный вывод из этой истории такой: если тебе регулярно приходится выгружать дашборды скриптами, значит они живут не там, где надо.

Grafana умеет **provisioning** — забирать дашборды и источники данных из файлов на диске при старте. Кладёшь YAML в `/etc/grafana/provisioning/datasources/` и `/etc/grafana/provisioning/dashboards/`, рядом складываешь JSON дашбордов, и вся конфигурация превращается в обычный код в git:

```yaml
# /etc/grafana/provisioning/dashboards/main.yaml
apiVersion: 1
providers:
  - name: 'from-git'
    orgId: 1
    folder: 'Production'
    type: file
    disableDeletion: true
    updateIntervalSeconds: 60
    options:
      path: /var/lib/grafana/dashboards
```

```yaml
# /etc/grafana/provisioning/datasources/prometheus.yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
```

После этого вопрос «как не потерять дашборды при переезде базы» просто исчезает: база становится кешем, а источником правды — репозиторий. Переезд с SQLite на MySQL превращается в поднятие пустого инстанса с тем же provisioning-каталогом.

Тем, кто уже живёт в Kubernetes, то же самое даёт [grafana-operator](https://github.com/grafana/grafana-operator) через CRD, а для терраформистов есть [провайдер Grafana](https://registry.terraform.io/providers/grafana/grafana/latest/docs).

Ручной экспорт при этом остаётся полезным ровно один раз — чтобы вытащить то, что уже накликано в интерфейсе, и положить в git.

А на этом всё!
