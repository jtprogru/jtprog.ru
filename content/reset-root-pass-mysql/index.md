---
categories: howto
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: howto.png
  relative: false
date: "2015-10-09T10:15:30+03:00"
tags:
- mysql
- password
title: '[HowTo] Если Вы забыли пароль MySQL (сброс пароля)'
type: post
---

В предыдущей статье я [описал](https://jtprog.ru/amarok-on-mysql/) как заставить удобный плеер Amarok хранить базу музыкальной библиотеки в MySQL. Сейчас все прекрасно работает и летает. А позже случился *~~пи%%ец~~* казус - я забыл пароль `root`'а от MySQL.

Я хоть и не программист, но иногда пытаюсь сотворить что-нибудь эдакое. И вот в процессе написания примитивного блога на PHP (холивары в сторону) с возможностью хранения постов и прочей информации в базе MySQL я понял, что просто не помню пароля от `root`'а. И естесственно я не могу войти в phpMyAdmin чтобы создать нужную мне базу данных и пользователя.

Относительно быстрый гуглеж привел меня к довольно простому рецепту лечения склероза. Для смены пароля root'а от MySQL требуется произвести следующие манипуляции в консоли.

Останавливаем MySQL:

```bash
/etc/init.d/mysqld stop
```

Запускаем MySQL с особыми параметрами:

```bash
/usr/bin/mysqld_safe --skip-grant-tables --user=root &
```

Запускаем клиента MySQL:

```bash
mysql -u root
```

Выполняем запрос SQL:

```sql
UPDATE mysql.user SET Password=PASSWORD(`siskisiski`) WHERE User=`root`;
```

где `siskisiski` - новый пароль

Применяем изменения:

```sql
FLUSH PRIVILEGES;
```

Выходим из клиента MySQL:

```sql
exit
```

Перезапускаем MySQL сервер:

```bash
/etc/init.d/mysqld restart
```

На этом всё - пароль рута MySQL изменён на `siskisiski`. Запоминаем его и стараемся не забывать. Profit!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
