---
title: "[Python] Качаем и ресайзим картинки"
date: 2019-08-15T19:50:55+03:00
draft: false
slug: '/get-pic/'
description: 'Небольшой пример работы с API Unsplash из Python 3 с использованием библиотеки pyunsplash'
categories: "Develop"
tags: ['python', 'requests']
comments: true
noauthor: false
share: true
type: "post"
---

Привет, `%username%`! Для оформления нового поста мне необходимо где-то взять новую картинку. Решение нашлось довольно быстро: [unsplash.com](https://unsplash.com).

После прочтения документации по [API Unsplash](https://unsplash.com/documentation) я решил скачивать картинку оттуда, после чего изменять ее размер, ибо некоторые из них весят больше мегабайта (а то и двух). В результате моих пыхтений получилось вот это вот:

```python
#!/usr/bin/env python3
# coding=utf-8
# Created by JTProgru
# Date: 2019-08-14
# https://jtprog.ru/


from pyunsplash import PyUnsplash
import requests
from PIL import Image
import os

UNSPLASH_ACCESS_KEY = 'XXXXXXXX'

pu = PyUnsplash(api_key=UNSPLASH_ACCESS_KEY)

logging.getLogger(__name__).setLevel(logging.DEBUG)
# Dir name for downloading image
tmp_dir = '/tmp/'
# Dir for save resized image
img_path = '/Users/jtprog/workplace/kb/static/images/'


def scale_image(input_image_path,
                output_image_path,
                width=None,
                height=None):
    """
    Simple function for scale image
    :param input_image_path: - full name to downloaded image
    :param output_image_path: - full name to save scaled image
    :return: None
    """
    original_image = Image.open(input_image_path)
    w, h = original_image.size
    print('The original image size is {wide} wide x {height} '
          'high'.format(wide=w, height=h))

    if width and height:
        max_size = (width, height)
    elif width:
        max_size = (width, h)
    elif height:
        max_size = (w, height)
    else:
        # No width or height specified
        raise RuntimeError('Width or height required!')

    original_image.thumbnail(max_size, Image.ANTIALIAS)
    original_image.save(output_image_path)

    scaled_image = Image.open(output_image_path)
    width, height = scaled_image.size
    print('The scaled image size is {wide} wide x {height} '
          'high'.format(wide=width, height=height))


def main():
    # Get one random image
    collections_page = pu.photos(type_='random', count=1, featured=True, query="programming")
    for photo in collections_page.entries:
        # Print Photo ID and Donwload link
        print(photo.id, photo.link_download)
        # Full fine name for download image
        tmp_file_name = tmp_dir + photo.id + '.jpg'
        # Full file name for save resized image
        done_file_name = img_path + photo.id + '.jpg'
        with open(tmp_file_name, 'wb') as handle:
            response = requests.get(photo.link_download, stream=True)
            if not response.ok:
                print(response)
            for block in response.iter_content(1024):
                if not block:
                    break
                handle.write(block)
        # If tmp_file_name is file:
        if os.path.isfile(tmp_file_name):
            # Resize image
            scale_image(input_image_path=tmp_file_name,
                        output_image_path=done_file_name,
                        width=800)
        # Remove tmp_file_name
        os.remove(tmp_file_name)
        print('File: ' + tmp_file_name + ' deleted')


if __name__ == '__main__':
    main()
```

Думаю тут довольно таки понятно всё, ибо не так много строчек кода и я ~~люблю~~ пишу комменты хотя бы для себя.

Позже выложу в свой [Github](https://github.com/jtprog/) вместе с остальными мелочами.


