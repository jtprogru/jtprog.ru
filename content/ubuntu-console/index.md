---
title: "[Encoding table] Кракозябры в консоли"
date: 2015-06-19T12:37:00+03:00
draft: false
slug: '/ubuntu-console/'
categories: "how-to"
tags: ['encoding', 'cli', 'linux']
comments: true
noauthor: false
share: true
type: "post"
---

У тех, кто рабоает в консоли часто встречается проблема отображения кракозябр вместо символов кириллицы. С такой проблемой и я столкнулся недавно. Решилась она довольно просто. Нужно всего лишь в ручную подправить файлик и всё. Для пользователей английской версии это не актуально, т.к. вся информация выводится без использования символов кириллицы.

Кракозябры в консоли можно побороть вот таким вот способом:
```bash
sudo apt-get install console-setup console-setup-linux
sudo spt-get purge console-cyrilic
```
После это правим ручка вот этот файл `/etc/default/console-setup`:
```bash
sudo nano /etc/default/console-setup
```
И вписываем туда вот такие значения:
```bash
CHARMAP="UTF-8"  
CODESET="CyrSlav"  
FONTFACE="VGA"  
FONTSIZE="16" #Не 16x8!
```
После этого делаем вот так:
```bash
setupcon --save
```
И распаковываем указанный шрифт:
```bash
gunzip -k /etc/console-setup/CyrSlav-VGA16.psf.gz
```
Но главное помнить, что файл может быть другим в зависимости от настроек. Название файла должно точно совпадать с настройками из `/etc/default/console-setup`, потому что `setupcon` может подбирать аналог, если 100% совпадение не найдено, а скрипт в `initrd` - нет.

И завершаем все вот такой командой
```bash
update-initramfs -u
```
Посмотреть, какие есть шрифты можно в этой папке `/usr/share/consolefonts/`.

Так же можно использовать и вот такую команду
```bash
sudo dpkg-reconfigure console-setup
```
Но учтите, что он неправильно устанавливает параметр `FONTSIZE`.

После всех этих манипуляций у вас будет нормально отображаться информация на русском языке.

На этом все! Profit!
