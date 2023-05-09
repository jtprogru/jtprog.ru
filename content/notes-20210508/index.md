---
categories: Notes
cover:
  alt: notes
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: notes.png
  relative: false
date: "2021-05-08T18:37:56+03:00"
tags:
- fuckup
- заметкинаполях
- werf
- helm
- kubernetes
- k8s
title: '[Notes] Заметки на полях 2021.05.08'
type: post
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

Причина по которой не работали внесенные мною изменения довольно простая: надо читать документацию. Поясню: в новой спецификации для `apiVersion: networking.k8s.io/v1` в разделе `backend` необходимо указывать немного по другому информацию о порте – примерно вот так:

```yaml
{{- range .paths }}
- path: {{ .path }}
    backend:
      service:
        name: {{ $fullName }}
        port:
          number: {{ $svcPort }}
          name: {{ $svcName }}
{{- end }}
```

Т.е. раньше в поле `port` согласно новой спецификации передается объект, а не число как раньше и у этого объекта имеются поля (выдержка из документации):

- `name <string>` – Name is the name of the port on the Service. This is a mutually exclusive setting with "Number";
- `number <integer>` – Number is the numerical port number (e.g. 80) on the Service. This is a mutually exclusive setting with "Name";

Итого получаем тот факт, что у меня ушло дохрена времени на то, что можно было бы решить простейшим чтением документации и спецификации ingress'a.

За сим откланяюсь! Не совершай моих ошибок!

---
Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).
