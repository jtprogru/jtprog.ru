---
categories: howto
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/dreamwolf97d61e)'
  image: howto.png
  relative: false
date: "2019-08-15T11:33:00+03:00"
tags:
- python
- centos
title: '[HowTo] Установка Python 3 в CentOS 7'
type: post
---

Привет, `%username%`! При работе на CentOS всё чаще необходим становится Python третьей ветки, ибо вторая ветка скоро умрёт. Как ставить Python 3.x из репозиториев? Легко!

## Условия

- CentOS 7 установленный и запущенный
- Права `sudo`

## Установка сопуствующих утилит

Для установки сопутствующих утилит необходимо выполнить следущие команды:

```bash
sudo yum update
sudo yum install yum-utils 
sudo yum groupinstall development 
```

## Установка Python 3.x

В стандартных репозиториях отсутствует последняя стабильная сборка Python и нам необходимо установить дополнительный репозиторий `IUS (Inline with Upstream Stable)`.

```bash
sudo yum install https://centos7.iuscommunity.org/ius-release.rpm
```

После чего сможем установить Python 3.6:

```bash
sudo yum install python36u
python3.6 --version  # Проверяем версию установленного Python 3.6
```

Далее устанавливаем менеджер пакетов `pip`:

```bash
sudo yum install python36u-pip
sudo yum install python36u-devel
```

Проверяем что у нас всё стало хорошо

```bash
# Вызываем стандартный интерпретатор Python
python –V
# Видим что он второй ветки:
Python 2.7.5

# Вызываем установленный Python 3 
python3.6 –V
# Видим что он третьей ветки:
Python 3.6.1
```

## Создание виртуального окружения

Дабы сохранять систему в чистоте используем виртуальное окружение (в папке с проектом):

```bash
python3.6 -m venv venv
```

Результатом будет создание директории `venv` в текущей директории с проектом. После этого можно его активировать и установить зависимости проекта, используя `pip`:

```bash
. venv/bin/activate  # Ативируем виртуальное окружение
pip install [package_name] # Устанавливаем пакет package_name
pip install -r requirements.txt # Устанавливаем зависимости из файла requirements.txt
```

На этом всё! Profit!

---
Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).
