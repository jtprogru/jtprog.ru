---
# Служебный раздел: страницы /go/<slug>/ генерирует content/go/_content.gotmpl
# из data/golinks.yaml. Сам /go/ рендерится редиректом на главную: на nginx
# каталог без index.html отдаёт 403, а человек, обрезавший ссылку, должен
# попасть на сайт, а не в ошибку. Цели в Метрике здесь нет.
title: "Короткие ссылки"
layout: redirect
target: "/"
label: "главную"
robotsNoIndex: true
# Без этого у раздела появляется пустой /go/index.xml
outputs: [html]
build:
  list: never
---
