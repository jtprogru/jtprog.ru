---
title: "[Notes] Заметки на полях  2021.05.08"
date: 2021-05-08T18:37:56+03:00
categories: "Fuckup"
tags: ["заметкинаполях", "werf", "helm", "kubernetes", "k8s"]
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
     alt: "Keyboard"
     caption: 'Photo by [Katharina Gloth](https://unsplash.com/@kath_a) on [Unsplash](https://unsplash.com/)'
     relative: false
comments: false
---

Привет, `%username%`! Очередная рубрика факапов и человеческого фактора. 

Попался мне в руки кластер k8s и надо там много чего переделать. Работаю с Helm'ом и решил попробовать [werf](https://werf.io).

При генерации шаблона чарта с помощью 

```bash
werf helm create mychartname
```
Создается примерно вот такая структура

```bash
├── Chart.yaml
├── charts
├── operator.yaml
├── templates
│   ├── NOTES.txt
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── hpa.yaml
│   ├── ingress.yaml
│   ├── service.yaml
│   ├── serviceaccount.yaml
│   └── tests
│       └── test-connection.yaml
└── values.yaml
```

Где в файлике `templates/ingress.yaml` появляется вот такая вот структура (вырезка):

```yaml
{{- if semverCompare ">=1.14-0" .Capabilities.KubeVersion.GitVersion -}}
apiVersion: networking.k8s.io/v1beta1
{{- else -}}
apiVersion: extensions/v1beta1
{{- end }}
```

При попытке проверить встроенным в helm литером, возникает вот такой варнинг:

```bash
[WARNING] templates/ingress.yaml: networking.k8s.io/v1beta1 Ingress is deprecated in v1.19+, unavailable in v1.22+; use networking.k8s.io/v1 Ingress
```

Ну я возьми и поправь это на `apiVersion: networking.k8s.io/v1`.

При попытке установить чарт с помощью Helm'а или с помощью werf'а будет вылетать вот такая ошибка:
```bash
Error: UPGRADE FAILED: error validating "": error validating data: [ValidationError(Ingress.spec.rules[0].http.paths[0].backend): unknown field "serviceName" in io.k8s.api.networking.v1.IngressBackend, ValidationError(Ingress.spec.rules[0].http.paths[0].backend): unknown field "servicePort" in io.k8s.api.networking.v1.IngressBackend]
```
Быстрый гуглеж приводит тебя к тому, что ты решаешь поправить вот это:

```yaml
{{- range .paths }}
- path: {{ .path }}
    backend:
      serviceName: {{ $fullName }}
      servicePort: {{ $svcPort }}
{{- end }}
```

На вот это:

```yaml
{{- range .paths }}
- path: {{ .path }}
    backend:
      service:
        name: {{ $fullName }}
        port: {{ $svcPort }}
{{- end }}
```

И как результат у тебя нихера не работает! А работать начинает только тогда, когда ты вернёшь всё в зад – пофиксишь обратно `apiVersion` и пофиксишь обратно описание backend'а.

За сим откланяюсь! Не совершай моих ошибок!  

---
Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://t.me/sysopschat), а так же подписывайся на [канал](https://t.me/sysopschannel).
