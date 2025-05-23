---
title: '[Basics] Ротация логов с logrotate'
description: "Полное руководство по настройке автоматической ротации логов в Linux с использованием logrotate: примеры конфигурации, основные директивы и проверка работы."
keywords:
  - "logrotate"
  - "ротация логов"
  - "настройка logrotate"
  - "автоматизация логов"
  - "Linux логи"
  - "конфигурация logrotate"
  - "примеры logrotate"
  - "Nginx логи"
  - "сжатие логов"
  - "проверка logrotate"
date: "2021-08-28T14:30:00+03:00"
lastmod: "2021-08-28T14:30:00+03:00"
tags:
  - logrotate
  - basics
  - "примитивы"
  - "автоматизация"
  - "системное администрирование"
categories:
  - Basics
cover:
  image: basics.png
  alt: basics
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  relative: false
type: post
slug: "logrotate-basics"
---

Привет, `%username%`! Логи – наше всё! Это знает каждый нормальный админ. Но что делать если они растут в объёме? Правильно! Настраивать logrotate чтоб он рулил размерами и количеством.

В любой Linux-системе всегда работает множество фоновых процессов и демонов, которые пишут в свои лог-файлы статусную информацию: об ошибках которые обработали, о выполнении каких-то задач. По стандарту все файлы логов должны храниться в директории `/var/log/`.

Анализирую логи можно понять что именно не работает и почему произошла ошибка. Есть одна проблема: логи постоянно пишутся в один файл и размер этого файла постоянно растет, поэтому необходимо систематически чистить логи удаляя старые записи, чтобы однажда не кончилось место на сервере из-за огромного размера лог-файла.

Ты можешь чистить логи ручками – поставить себе напоминание, ходить руками на сервер и вручную удалять старые записи из лог-файлов, а можешь навертеть на bash'е скрипт и поставить его в cron. Однако есть вариант сильно проще - утилита `logrotate`.

## Как работает

Logrotate предназначен для автоматической обработки лог-файлов. Эта утилита может выполнять необходимые действия с лог-файлами в зависимости от конфигурации. Для примера:

- Можно паковать журналы в архив;
- Отправлять на другой сервер когда они достигнут какого-то размера, возраста;

Проверка условий настраивается ежедневно, еженедельно или ежемесячно. Это позволяет создать довольно гибкую схему ротации логов.

## Настройка

В большинстве дистрибутивов эта утилита идет "искаропки", так что дополнительных действий по ее установке не требуется. Но на всякий случай ставится она вот так:

```shell
# CentOS
sudo yum install logrotate
# Ubuntu
sudo apt install logrotate
```

Ключевые настройки `logrotate` находятся в файле `/etc/logrotate.conf`. Поддерживается подключение доволнительных настроек, которые могут быть размещены в директории `/etc/logroate.d/`. Тебе никто не запрещает херачить весь конфиг в один файл, но "не торопись и подумой!"

Для подключения дополнительных конфигов из директории `/etc/logrotate.d/` надо всего лишь раскоментировать строчку в основном конфиге `/etc/logrotate.conf`:

```shell
include /etc/logrotate.d
```

Обычно по дефолту эта строка уже есть и не закоментирована. Теперь надо разобраться с основными директивами, чтоб научиться писать "правильный" конфиг для ротации своих лог-файлов.

Чтоб указать `logrotate` как часто нужно выполнять проверку используются такие директивы:

- `hourly` – каждый час;
- `daily` – каждый день;
- `weekly` – каждую неделю;
- `monthly` – каждый месяц;
- `yearly` – каждый год;

С частотой проверки всё понятно и просто. Теперь основные директивы управления и обработки лог-файлов:

- `rotate` - сколько старых логов нужно хранить, в параметрах передается количество (пример: `rotate 4`);
- `create` - необходимо создать пустой лог файл после перемещения старого;
- `dateext` - добавляет дату ротации перед заголовком старого лога;
- `compress` - сжимает архивный лог-файл;
- `delaycompress` - не сжимать последний и предпоследний журнал;
- `extension` - сохранять оригинальный лог файл после ротации, если у него указанное расширение;
- `mail` - отправлять Email после завершения ротации;
- `maxage` - выполнять ротацию журналов, если они старше, чем указано;
- `missingok` - не выдавать ошибки, если лог файла не существует;
- `olddir` - перемещать старые логи в отдельную папку;
- `postrotate`/`endscript` - выполнить произвольные команды после ротации;
- `start` - номер, с которого будет начата нумерация старых логов;
- `size` - размер лога, когда он будет перемещен;

Кажется это все основные директивы, которыми тебе придется оперировать. Директивы из основного файла `/etc/logrotate.conf` конфигурация будут распространяться на все логи если не было отменено их действие. Файл описывающий логи, которые подлежат ротации с помощью `logrotate` верхнеуровнево выглядит вот так:

```nginx
адрес_файла_лога {
    директивы
}
```

Причем `адрес_файла_лога` может быть указан по маске как в примере дальше. Давай сделаем конфигурацию для `logrotate` которая будет следить за логами Nginx. Создай файл `/etc/logrotate.d/nginx` и приведи его к такому виду:

```nginx
/var/log/nginx/*.log {
        daily
        missingok
        rotate 14
        compress
        delaycompress
        notifempty
        create 640 nginx adm
        sharedscripts
        postrotate
                [ -f /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid`
        endscript
}
```

Эти настройки говорят `logrotate`, что:

- все файлы из `/var/log/nginx` у которых суффикс (расширение файла) `.log`
- должны быть обработаны ежедневно
- игнорировать ошибку если файл не найден
- хранить последние 14 архивных файлов
- сжимать все кроме последнего и предпоследнего файлов
- не выполнять ротацию если журнал пустой
- создать новый файл с правами `640` владельцем `nginx` и группой `adm`
- выполнить скрипты один раз не зависимо от количества лог-файлов
- сам скрипт, который выполнится после ротации лог-файлов из этого конфига

По аналогии можно настроить ротацию любого лог-файла в системе. А чтобы проверить что ты в конфиге не накосячил и все будет работать так как ты планируешь, надо выполнить вот это:

```shell
logrotate -d /etc/logrotate.d/nginx
```

Подтвержением того, что ежедневная обработка лог-файлов включена будет появление файла `/etc/cron.daily/logrotate` с примерно таким содержимым:

```bash
#!/bin/sh

/usr/sbin/logrotate -s /var/lib/logrotate/logrotate.status /etc/logrotate.conf
EXITVALUE=$?
if [ $EXITVALUE != 0 ]; then
    /usr/bin/logger -t logrotate "ALERT exited abnormally with [$EXITVALUE]"
fi
exit 0
```

## Итоги

По аналогии с примером выше ты вполне теперь можешь сконфигурить ротацию других лог-файлов, которые "слишком быстро пухнут".

Подробнее о параметрах `logrotate` можно почитать в мануалах [тут](https://www.opennet.ru/man.shtml?topic=logrotate&category=8&russian=0) или тут:

```shell
man logrotate
```

Если тебе надо автоматизировать, то вот тут моя роль [jtprogru.logrotate](https://github.com/jtprogru/ansible-role-logrotate) – не забудь бахнуть звездочку в знак благодарности. Поставить роль можно из Ansible Galaxy вот так:

```bash
ansible-galaxy install jtprogru.logrotate
```

На этом всё!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
