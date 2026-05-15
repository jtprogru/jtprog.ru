---
title: 'Логи Nginx в JSON'
description: "Пошаговое руководство по настройке логирования Nginx в JSON-формате для удобного парсинга и интеграции с системами анализа логов"
keywords:
  - nginx logs
  - json logging
  - elk stack
  - nginx configuration
  - access logs
  - loki
  - vector
  - promtail
  - grafana alloy
date: "2021-08-26T18:14:09+03:00"
lastmod: "2026-05-15T20:00:00+03:00"
tags:
  - nginx
  - json
  - logs
categories: ["Work"]
cover:
  image: work.png
  alt: work
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  relative: false
type: post
slug: 'nginx-json-logs'
---

Привет, `%username%`! Логи это очень хорошо! Логи – это машина времени, которая работает исключительно в прошлое. А логи в JSON сильно проще парсить и лить в тот же ELK.

> 🔄 **Обновлено 2026-05-15**: nginx-конфиг ниже работает как был — поля и `escape=json` валидны. Внизу добавил короткий блок про то, как этот лог забирать в современный лог-стек (Loki через Vector или Grafana Alloy) — ELK уже не единственный вариант.

Чтобы писать логи в формате JSON достаточно правильно сконфигурировать Nginx.

```nginx
log_format main_json escape=json '{'
  '"msec": "$msec", ' # request unixtime in seconds with a milliseconds resolution
  '"connection": "$connection", ' # connection serial number
  '"connection_requests": "$connection_requests", ' # number of requests made in connection
  '"pid": "$pid", ' # process pid
  '"request_id": "$request_id", ' # the unique request id
  '"request_length": "$request_length", ' # request length (including headers and body)
  '"remote_addr": "$remote_addr", ' # client IP
  '"remote_user": "$remote_user", ' # client HTTP username
  '"remote_port": "$remote_port", ' # client port
  '"time_local": "$time_local", '
  '"time_iso8601": "$time_iso8601", ' # local time in the ISO 8601 standard format
  '"request": "$request", ' # full path no arguments if the request
  '"request_uri": "$request_uri", ' # full path and arguments if the request
  '"args": "$args", ' # args
  '"status": "$status", ' # response status code
  '"body_bytes_sent": "$body_bytes_sent", ' # the number of body bytes exclude headers sent to a client
  '"bytes_sent": "$bytes_sent", ' # the number of bytes sent to a client
  '"http_referer": "$http_referer", ' # HTTP referer
  '"http_user_agent": "$http_user_agent", ' # user agent
  '"http_x_forwarded_for": "$http_x_forwarded_for", ' # http_x_forwarded_for
  '"http_host": "$http_host", ' # the request Host: header
  '"server_name": "$server_name", ' # the name of the vhost serving the request
  '"request_time": "$request_time", ' # request processing time in seconds with msec resolution
  '"upstream": "$upstream_addr", ' # upstream backend server for proxied requests
  '"upstream_connect_time": "$upstream_connect_time", ' # upstream handshake time incl. TLS
  '"upstream_header_time": "$upstream_header_time", ' # time spent receiving upstream headers
  '"upstream_response_time": "$upstream_response_time", ' # time spend receiving upstream body
  '"upstream_response_length": "$upstream_response_length", ' # upstream response length
  '"upstream_cache_status": "$upstream_cache_status", ' # cache HIT/MISS where applicable
  '"ssl_protocol": "$ssl_protocol", ' # TLS protocol
  '"ssl_cipher": "$ssl_cipher", ' # TLS cipher
  '"scheme": "$scheme", ' # http or https
  '"request_method": "$request_method", ' # request method
  '"server_protocol": "$server_protocol", ' # request protocol, like HTTP/1.1 or HTTP/2.0
  '"pipe": "$pipe", ' # “p” if request was pipelined, “.” otherwise
  '"gzip_ratio": "$gzip_ratio", '
  '"http_cf_ray": "$http_cf_ray"'
'}';
```

Важно: Директива `escape=json` была добавлена в Nginx 1.11.8. Пруф в [документации](http://nginx.org/en/docs/http/ngx_http_log_module.html#log_format).

Это самая "жирная" конфигурация логирования в JSON, которая мне попадалась. Её стоит положить в `/etc/nginx/conf.d/logging.conf`, а в основном файле `/etc/nginx/nginx.conf` стоит проверить наличие строк подключения:

```nginx
include /etc/nginx/conf.d/*.conf;
```

Далее в нужном месте мы просто включаем логирование в формате `main_json`.

```nginx
...
access_log /var/log/nginx/jtprog.ru.json.log main_json;
...
```

## Куда лить эти логи

В 2021-м первой ассоциацией с «JSON-логи» был ELK. В 2026-м чаще встречается стек **Loki + Vector/Alloy + Grafana** — он легче, дешевле и не требует ворочать Elasticsearch.

**Минимальный pipeline через Vector** (`/etc/vector/vector.toml`):

```toml
[sources.nginx_access]
type           = "file"
include        = ["/var/log/nginx/*.json.log"]
read_from      = "end"

[transforms.parse_json]
type           = "remap"
inputs         = ["nginx_access"]
source         = ". = parse_json!(.message)"

[sinks.loki]
type           = "loki"
inputs         = ["parse_json"]
endpoint       = "http://loki:3100"
encoding.codec = "json"
labels.host    = "{{ host }}"
labels.app     = "nginx"
labels.vhost   = "{{ server_name }}"
```

`labels` берёт смысл прямо из полей JSON-лога — `server_name`, `host`, можно добавить `status` и `request_method`. Не злоупотребляй высокой кардинальностью (например, `request_uri` или `remote_addr` лейблами лучше не делать — взорвут индекс Loki).

**Альтернатива — Grafana Alloy** (унифицированный коллектор Grafana Labs, заменяет Promtail/OTel collector/node_exporter):

```alloy
loki.source.file "nginx" {
  targets = [{
    __path__ = "/var/log/nginx/*.json.log",
    job      = "nginx",
  }]
  forward_to = [loki.process.nginx.receiver]
}

loki.process "nginx" {
  stage.json {
    expressions = {
      status      = "status",
      method      = "request_method",
      server_name = "server_name",
    }
  }
  stage.labels {
    values = { status = "", method = "", server_name = "" }
  }
  forward_to = [loki.write.default.receiver]
}

loki.write "default" {
  endpoint { url = "http://loki:3100/loki/api/v1/push" }
}
```

Дальше — `{job="nginx", status="5xx"}` в Grafana, и ты видишь все 5xx за окно. Запросы вида `| json | duration > 1s` без проблем работают на структурированных JSON-логах.

Если стек ELK уже есть — `filebeat` с модулем `nginx` или `logstash` с `json` codec тоже отлично заходят: формат универсальный.

На этом всё!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". 
