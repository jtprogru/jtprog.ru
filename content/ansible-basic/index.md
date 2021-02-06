---
title: "[DevOps] Ansible – основы управления конфигурацией"
date: 2020-12-29T00:30:54+03:00
categories: 'Work'
tags: ["DevOps", "Ansible", "Configuration management", IaC]
type: 'post'
author: "JTProg"
description: "Что такое Ansible, для каких задач он нужен? Что такое IaC?"
draft: false
---

Привет, `%username%`! На страницах этого блога уже [было](/notes-20200925/) небольшое упоминание [Ansible](https://www.ansible.com) – инструмента для управления конфигурацией. Пройдемся по основам, определениям дабы зафиксировать.

## Управления конфигурацией
Пробежавшись по различным ресурсам в интернете можно прийти к следующему определению:

> **Управление конфигурацией** (Configuration Management / CM) – это автоматизированный процесс внесения изменений в систему, который обеспечивает целостность конфигураций.

CM часто вспоминают в контексте автоматизации каких-либо рутинных задач/процессов. Например: как только у вас появляется несколько одинаковых серверов, вам жизненно необходимо начать работать с CM системами дабы исключить человеческий фактор из процесса конфигурирования одинаковых систем. Человек белковый может допустить очепятку, а машина железная – нет.

Посмотрим на преимущества инструментов CM для автоматизации настройки инфраструктуры и на то, как работает Ansible.

## Преимущества использования инструментов CM

Для управления конфигурацией существует некоторое количество инструментов с различными уровнями сложности и архитектурными стилями:

| Tool | Released by | Method | Approach | Written in |
|:--:|:--:|:--:|:--:|:--:|
| Chef | Chef (2009) | Pull | Declarative and imperative| Ruby |
| Otter| Inedo|Push|Declarative and imperative|- |
| Puppet|Puppet (2005)|Pull|Declarative|C++ & Clojure since 4.0, Ruby|
| SaltStack|SaltStack|Push and Pull|Declarative and imperative|Python |
| CFEngine|CFEngine|Pull|Declarative|C |
| Terraform|HashiCorp (2014)|Push|Declarative|Go |
| DSC|Microsoft|Push/Pull|Declarative/Imperative|PowerShell|
| Ansible / Ansible Tower|RedHat (2012)|Push|Declarative and imperative|Python |

Не смотря на различные подходы, архитектуру и прочие незначительные отличия, каждый из инструментов работает по своему и выполняет одну и ту же задачу: гарантирует, что состояние системы соответствует описанному сценарию.

Ключевые преимущества CM связаны с определением инфраструктуры как кода – подход [Infrastructure as Code (IaC)](https://en.wikipedia.org/wiki/Infrastructure_as_code), что позволяет:
- Использовать GitLab/Github, чтобы отслеживать изменения в инфраструктуре;
- Переиспользовать сценарии в нескольких серверных средах (в средах dev, test, stage и prod);
- Делиться сценариями с как внутри команды, так и между командами;
- Ускорить процесс размножения серверов;

Ну и самое главное: инструменты CM позволяют управлять сотнями серверов централизованно, что повышает эффективность инфраструктуры.

## Ansible – краткий обзор

Ansible – современный инструмент CM, который облегчает настройку удаленных серверов благодаря своей простоте и низкому порогу вхождения.

Сценарии Ansible пишутся на [YAML](https://yaml.org), что позволяет  создавать сложные сценарии проще, чем другими инструментами этой же категории.

Ansible не требует установки специального ПО на управляемые хосты – доступ осуществляется по стандартному протоколу SSH. Установить Ansible нужно только на хост, с которого будет происходить управление другими хостами.

Ansible предоставляет следующие базовые функции:
- Идемпотентность. Ansible отслеживает состояние ресурсов в целевых управляемых системах для исключения повторения задач, которые уже были выполнены. Пример: если требуемый пакет уже установлен в системе, Ansible не будет пытаться установить его. Основная цель Ansible состоит в том, чтобы система достигала/сохраняла желаемое состояние, даже если процесс запускается несколько раз. При запуске плейбука выдается отчет о состоянии каждой задачи и статус внесла ли задача изменение в системе;
- Переменные, условные выражения и циклы. При составлении сценария автоматизации можно использовать переменные, условные выражения и циклы. Это позволяет сделать автоматизацию более универсальной и эффективной;
- Факты о системе. Ansible собирает подробную информацию об управляемых нодах  и предоставляет ее в виде глобальных переменных. Собранные факты можно использовать в плейбуках;
- Шаблонизация. В качестве системы шаблонов Ansible использует Jinja2 Python. Шаблоны упрощают параметризацию конфигурационных файлов. Например: вы можете создать шаблон для настройки демона SSH и применить его на нескольких серверах, повесив на разные порты в зависимости от заданных переменных;
- Поддержка модулей и плагинов. В поставку Ansible включено множество встроенных модулей, а это значительно упрощает написание общих задач (установка пакетов через `apt`/`yum`), работу с распростаненным ПО (MySQL, PostgreSQL, MongoDB, etc) и управление зависимостями (composer, npm, etc). Если в стандартной поставке Ansible не нашлось нужного модуля, вы всегда можете написать свой на Python;

## Основные понятия Ansible

Пробежимся по основным терминам Ansible:
- Главная/Управляющая нода (Control Node) – это сервер, на который устанавливается Ansible и с которого выполняется подключение ко всем конфигурируемым хостам. В качестве главной ноды можно настроить любую систему, которая способна запускать Ansible – выделенный сервер, ПК или ноутбук с  Linux/Unix на борту. На текущий момент Ansible не работает на Windows, но это обходится запуском виртуальной машины и запуском Ansible оттуда;
- Управляемые ноды (Managed Nodes) – это серверы, которыми вы будете управлять с помощью Ansible. Для Ansible требуется, чтобы целевые хосты были доступны по SSH и чтобы на них был установлен Python 2 (версия 2.6+) или Python 3 (версия 3.5+). Управлять Ansible может Linux/Unix и Windows;
- Файл инвентаря или инвентарь (Inventory) – это файл со списком хостов, которыми планируется управлять. По умолчанию Ansible создает файл инвентаря тут  `/etc/ansible/hosts`, но рекомендуется создавать файл инвентаря для каждого проекта. Инвентарь может быть как статический (файл `.ini`/`.yml`), так и динамически генерируемый;
- Задача в Ansible (Tasks) – это единица действий в Ansible, которая выполняется на управляемом хосте. Упрощая: каждое действие определяется как задача. Задачи можно выполнять единожды с помощью специальных параметров, а так же включать задачи в плейбук как часть сценария автоматизации;
- Плейбук (Playbook) – это YAML-файл, содержащий упорядоченный список задач, а так же других параметров: на каких хостах выполнять автоматизацию, нужно ли использовать повышать привилегии для выполнения задач, определения переменных или включения дополнительных файлов. Выполнение задач происходит последовательно, а полное выполнение плейбука называется плей (play);
- Обработчики/Хендлеры (Handlers) – используются для выполнения действий с сервисами (для перезапуска и остановки). Хендлеры запускаются задачами и их выполнение происходит в конце плея, после того как все задачи были выполнены. Если перезапуск какого-то сервиса будет инициироваться несколькими задачами, то сервис перезапустится только один раз после выполнения всех задач. Хендлеры по умолчанию имеют эффективным и более практичным, а при необходимости можно принудительно немедленно запустить обработчик;
- Роль (Roles) – это набор плейбуков/задач, связанных файлов, организованных в предопределенную структуру. Роли позволяет переиспользовать плейбуки в пакеты/библиотеки например для установки [базового ПО](https://github.com/jtprog/ansible-role-install-base-soft), установка [Docker](https://github.com/jtprog/ansible-role-install-docker).

## Заключение

Ansible – это довольно простой инструмент для автоматизации рутинных задач. Благодаря комьюнити он имеет огромное количество модулей. Простые требования к инфраструктуре и легкость восприятия синтаксиса позволяют легко начать знакомиться с управлением конфигурациями.

На этом всё! Очепятки/замечания/комментарии направляй [сюда](https://t.me/sysopschat). Ну и подписывайся на [канал](https://t.me/sysopschannel)!