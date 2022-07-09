---
categories: Develop
comments: true
date: "2017-09-13T15:00:00+03:00"
draft: false
noauthor: false
share: true
slug: /twitter-excuse/
tags:
- python
- twitter api
title: '[Python] Пишем отмазки в Twitter'
type: post
---

Привет `%username%`! Давно я тут ничего не писал и тут мне захотелось поделиться. Решил я ради развлечения написать небольшую приблуду для своего любимого `zsh`. Теперь он по команде `excuse` отправляет случайное предложение из базы данных Redis, которая крутится у меня в Docker'е. Для страждущих собственно [код](https://github.com/jtprog/twitter-excuse). Остальным под кат.

В остальном все примитивно и просто - как мне теперь кажется.

Вот собственно листинг единственного файла который делает всё:
```python
#!/usr/local/bin/python3
# -*- coding: utf-8 -*-
# Copyright 2017 Savin (JTProg) Mihael
# Simple Twitter posting excuse
# https://jtprog.ru/

import twitter  
import dotenv as d  
from pathlib import Path  
import logging  
import os  
import redis  
import random

r = redis.StrictRedis(host='localhost', port=63799, db=0)

# Get current working directory  
wd = os.path.dirname(os.path.abspath(__file__))  
# Log file name  
LOG_FILE_PATH = cwd + '/logs/info.log'

logging.getLogger(__name__)  
# Logging configuration  
logging.basicConfig(format=u'%(filename)s [LINE:%(lineno)d]# \
                    %(levelname)s [%(asctime)s] %(message)s',
                    level=logging.DEBUG,
                    filename=LOG_FILE_PATH)

# Load Twitter credential  
env = str(Path(__file__).parent / '.env')

try:  
    TOKEN = d.get_key(env, 'TOKEN')  
    TOKEN_KEY = d.get_key(env, 'TOKEN_KEY')  
    CON_SEC = d.get_key(env, 'CON_SEC')  
    CON_SEC_KEY = d.get_key(env, 'CON_SEC_KEY')  
except Exception as e:  
    # Log errors.  
    logging.fatal(u'Can\'t get configuration from enviromentnnFATAL: {}'.format(e))

def main():  
    my_auth = twitter.OAuth(TOKEN, TOKEN_KEY, CON_SEC, CON_SEC_KEY)  
    try:  
        twit = twitter.Twitter(auth=my_auth)  
    except Exception as e:  
        # Log errors  
        logging.fatal(u'FATAL: {}'.format(e))  
    # List of a reasons  
    reasons = r.get(random.randrange(0, 42388))

    try:  
        # Send tweet  
        # tweet = random.choice(reasons)  
        twit.statuses.update(status=reasons[0:139])  
        logging.info(u'INFO: {}'.format('Message send'))  
    except Exception as e:  
        # Log errors  
        logging.fatal(u'FATAL: {}'.format(e))

    return

if __name__ == '__main__':  
    main()
```

Redis у меня запущен в Docker-контейнере и проброшен соответствующий порт `63799`. Наполнение базы данных в Redis делалось с помощью отдельного скрипта, который я решил не выкладывать в репозиторий. Вот его листинг:
```python
# coding=utf-8  
from nltk.tokenize import sent_tokenize  
import redis

r = redis.StrictRedis(host='localhost', port=63799, db=0)

txt = open(r'tolstoy.txt', encoding='utf-8').read()  
sents = sent_tokenize(txt)  
key = 0

for pred in sents:  
    key += 1  
    r.set(key, pred)

print(r.dbsize())
```
Тут все примитивно и понятно подключаемся к БД, открываем файл с текстом в кодировке `UTF-8`, прогоняем через полезную и интересную библиотеку `nltk` и простым циклом загоняем все предложения в БД.

**Важно**: не проглядеть такой параметр как `db=0`, т.к. именно он отвечает за ту базу к которой вы подключаетесь и наполняете своими "отмазками".

На этом собственно всё!
