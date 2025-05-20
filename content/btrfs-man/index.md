---
categories: Basics
cover:
    image: basics.png
    alt: basics
    caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
    relative: false
date: "2019-05-20T10:55:05+03:00"
tags:
- btrfs
- linux
- filesystem
- commands
- subvolumes
- snapshots
- ext3 conversion
- resize
- basics
title: '[Basics] Btrfs - что это и как это'
type: post
description: "Введение в файловую систему Btrfs для Linux: основные понятия, история, примеры команд для создания, управления томами, подтомами, снимками, конвертации из ext3 и изменения размера."
keywords: ["btrfs файловая система", "linux filesystem", "btrfs команды", "btrfs subvolume", "btrfs snapshot", "конвертация ext3 в btrfs", "изменение размера btrfs", "администрирование linux", "btrfs основы"]
---
**Btrfs** (иногда произносится butter fs) — новая свободная файловая система, разрабатываемая при поддержке компании Oracle. Распространяется по лицензии GPL. Несмотря на то, что её разработка ещё далека от завершения, 9 января 2009 года файловая система была интегрирована в ядро Linux, и доступна в Debian Squueze.

Хотя Btrfs была включена в ядро 2.6.29, разработчики утверждают, что "начиная от ядра 2.6.31, мы только планируем сделать впредь совместимый формат изменений диска". Разработчики по-прежнему хотят улучшить пользовательские/управленческие средства, чтобы сделать их более удобными в использовании.

Ext2/3/4 могут быть превращены в Btrfs (но не наоборот).

## Примеры команд по работе с btrfs

Создание файловой системы:

```bash
mkfs.btrfs
```

Управление томами, подтомами, снимками; проверка целостности файловой системы:

```bash
btrfsctl
```

Сканирование в поисках файловых систем btrfs:

```bash
btrfsctl -a
btrfsctl -A /dev/sda2
```

Создание снимков и подтомов:

```bash
mount -t btrfs -o subvol=. /dev/sda2 /mnt
btrfsctl -s new_subvol_name /mnt
btrfsctl -s snapshot_of_default /mnt/default
btrfsctl -s snapshot_of_new_subvol /mnt/new_subvol_name
btrfsctl -s snapshot_of_a_snapshot /mnt/snapshot_of_new_subvol
ls /mnt
```

Проверка extent-деревьев файловой системы:

```bash
btrfsck
```

Вывести метаданные в текстовой форме:

```bash
debug-tree
debug-tree /dev/sda2 >& big_output_file
```

Показать файловые системы btrfs на жестком диске:

```bash
btrfs-show /dev/sda*
```

Дефрагментация (по умолчанию не требуется):

```bash
btrfs filesystem defragment /mnt
```

или

```bash
btrfs filesystem defragment /mnt/file.iso
```

## Превращение файловой системы ext3 в btrfs

Файловую систему `ext3` можно превратить в `btrfs`, и работать с ней дальше уже как с новой файловой системой. Причём состояние исходной файловой системы `ext3`, будет доступно и потом.

```bash
# Always run fsck first
fsck.ext3 -f /dev/xxx

# Convert from Ext3->Btrfs
btrfs-convert /dev/xxx

# Mount the resulting Btrfs filesystem
mount -t btrfs /dev/xxx /btrfs

# Mount the ext3 snapshot
mount -t btrfs -o subvol=ext2_saved /dev/xxx /ext2_saved

# Loopback mount the image file
mount -t ext3 -o loop,ro /ext2_saved/image /ext3
```

Теперь в каталоге `/ext3` видно состояние исходной файловой системы.

Размонтирование происходит в обратном порядке:

```bash
umount /ext3
umount /ext2_saved
umount /btrfs
```

Можно вернуться на файловую систему `ext3` и потерять сделанные изменения:

```bash
btrfs-convert -r /dev/xxx
```

Или можно остаться на `btrfs` и удалить сохранённый образ файловой системы `ext3`:

```bash
rm /ext2_saved/image
```

**Примечание**: у новой файловой системы после конвертирования иногда бывает очень большой размер метаданных.

Посмотреть размер метаданных:

```bash
btrfs filesystem df /mnt/data1tb/
```

Нормализировать их размер:

```bash
btrfs fi balance /mnt/btrfs
```

## Изменение размера файловой системы и разделов

Для `btrfs` доступно онлайн (на лету) изменение размера файловой системы. Для начала нужно примонтировать нужный раздел:

```bash
mount -t btrfs /dev/xxx /mnt
```

Добавление 2Гб:

```bash
btrfs filesystem resize +2G /mnt
```

или

```bash
btrfsctl -r +2g /mnt
```

Уменьшение на 4Гб:

```bash
btrfs filesystem resize -4g /mnt
```

или

```bash
btrfsctl -r -4g /mnt
```

Задать размер в 20Гб файловой системе:

```bash
btrfsctl -r 20g /mnt
```

или

```bash
btrfs filesystem resize 20g /mnt
```

Использование всего свободного места:

```bash
btrfs filesystem resize max /mnt
```

или

```bash
btrfsctl -r max /mnt
```

Вышеперечисленные команды справедливы только для файловой системы. Чтобы изменить размер раздела, надо воспользоваеться еще другими утилитами, например `fdisk`. Рассмотрим пример для уменьшения раздела на 4Гб. Монтируем и уменьшаем раздел:

```bash
mount -t btrfs /dev/xxx /mnt
btrfsctl -r -4g /mnt
```

Теперь отмонтируем раздел и используем `fdisk`:

```bash
umount /mnt
fdisk /dev/xxx
```

где:

- `dev/xxx` - жесткий диск с нужным нам разделом
- `p` - выводит список разделов, узнаем номер нужного нам (N)
- `d` - удалить раздел, не пугайтесь
- Номер раздела (1-4): `N` - вводим число - номер нужного нам раздела
- `n` - создать новый раздел на месте старого:
- `p` - основной раздел
- Номер раздела (1-4): `N` - вводим конечно тоже самое число
- Первый цилиндр, ставим тот, который программа предлагает по умолчанию
- Последний цилиндр ставим как разницу старого размера раздела и 4Гб: например, если размер был 100Гб, ставим: `+96G`
- `p` - посмотреть в списке разделов, все ли сделано правильно
- `w` - записать изменения

После надо перемонтировать раздел или перезагрузиться. Проверяем на ошибки новый раздел(нужно отмонтировать):

```bash
btrfsck /dev/xxx
```

Profit!

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". Попасть в закрытый Telegram-чат единомышленников "BearLoga" можно по ссылке на [Tribute](https://web.tribute.tg/s/oRV).
