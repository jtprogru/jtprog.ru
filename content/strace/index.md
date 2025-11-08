---
title: '[OS] Наблюдение за процессами при помощи strace'
description: "Практическое руководство по использованию strace для диагностики и отладки процессов в Linux: основные опции, примеры, анализ системных вызовов."
keywords: ["strace linux", "отладка процессов linux", "диагностика linux", "системные вызовы strace", "пример использования strace", "strace опции", "мониторинг процессов linux", "bsd лицензия strace", "инструменты linux"]
date: "2019-07-29T12:01:18+03:00"
lastmod: "2019-07-29T12:01:18+03:00"
tags:
  - strace
  - linux
  - debugging
  - troubleshooting
  - system calls
  - linux tools
  - command line
categories:
  - OS
cover:
  image: OS.png
  alt: OS
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  relative: false
type: post
slug: strace
---

Привет, `%username%`! Поговорим о такой болезни как [вуайеризм](https://ru.m.wikipedia.org/wiki/Вуайеризм). Подглядывать мы будем за процессами в Linux, а использовать для столь интимного дела мы будем утилиту `strace`.

## **Что это и чем его едят**

`strace` — это утилита, присутствующая во многих дистрибутивах Linux по умолчанию, которая может использоваться в диагностических, учебных или отладочных целях. При помощи `strace` вы иной раз можете избавить себя от лишней головной боли, когда необходимо отыскать причину возникающего сбоя, при этом не имея доступа к исходным кодам. Помимо этого, `strace` может использоваться при отправке багрепортов разработчикам. Используя этот инструмент вы сможете воочию увидеть, что делает программа.

`strace` — это бесплатная утилита, распространяемая под BSD-лицензией. Изначально она была написана `Paul Kranenburg` для `SunOS` и называлась `trace`. Затем усилиями Branko Lankester она была портирована на Linux, включая поддержку специфики Linux-ядра. Затем, в 1993 году, версии `strace` для `SunOS` и Linux были объединены в одну, был добавлен  некоторый функционал `truss` из `SVR4`. В итоге получившийся винегрет назвали `strace`, который теперь работает на многих UNIX-платформах. Сегодня разработкой утилиты занимаются `Wichert Akkerman` и `Roland McGrath`.

В самом простом варианте strace запускает переданную команду с её аргументами и выводит в стандартный поток ошибок все системные вызовы команды. Давайте разберём опции утилиты, с помощью которых можно управлять её поведением:

- `-i` - выводить указатель на инструкцию во время выполнения системного вызова;
- `-k` - выводить стек вызовов для отслеживаемого процесса после каждого системного вызова;
- `-o` - выводить всю информацию о системных вызовах не в стандартный поток ошибок, а в файл;
- `-q` - не выводить сообщения о подключении о отключении от процесса;
- `-qq` - не выводить сообщения о завершении работы процесса;
- `-r` - выводить временную метку для каждого системного вызова;
- `-s` - указать максимальный размер выводимой строки, по умолчанию 32;
- `-t` - выводить время суток для каждого вызова;
- `-tt` - добавить микросекунды;
- `-ttt` - добавить микросекунды и количество секунд после начала эпохи Unix;
- `-T` - выводить длительность выполнения системного вызова;
- `-x` - выводить все не ASCI-строки в шестнадцатеричном виде;
- `-xx` - выводить все строки в шестнадцатеричном виде;
- `-y` - выводить пути для файловых дескрипторов;
- `-yy` - выводить информацию о протоколе для файловых дескрипторов;
- `-c` - подсчитывать количество ошибок, вызовов и время выполнения для каждого системного вызова;
- `-O` - добавить определённое количество микросекунд к счетчику времени для каждого вызова;
- `-S` - сортировать информацию выводимую при опции `-c`. Доступны поля `time`, `calls`, `name` и `nothing`. По умолчанию используется `time`;
- `-w` - суммировать время между началом и завершением системного вызова;
- `-e` - позволяет отфильтровать только нужные системные вызовы или события;
- `-P` - отслеживать только системные вызовы, которые касаются указанного пути;
- `-v` - позволяет выводить дополнительную информацию, такую как версии окружения, статистику и так далее;
- `-b` - если указанный системный вызов обнаружен, трассировка прекращается;
- `-f` - отслеживать также дочерние процессы, если они будут созданы;
- `-ff` - если задана опция `-o`, то для каждого дочернего процесса будет создан отдельный файл с именем `имя_файла.pid`.
- `-I` - позволяет блокировать реакцию на нажатия `Ctrl+C` и `Ctrl+Z`;
- `-E` - добавляет переменную окружения для запускаемой программы;
- `-p` - указывает `pid` процесса, к которому следует подключиться;
- `-u` - запустить программу, от имени указанного пользователя.

Вы знаете основные опции `strace`, но чтобы полноценно ею пользоваться, нужно ещё разобраться с системными вызовами, которые используются чаще всего. Мы не будем рассматривать все, а только основные. Многие из них вы уже и так знаете, потому что они называются так же, как и команды в терминале:

- `fork` - создание нового дочернего процесса;
- `read` - попытка читать из файлового дескриптора;
- `write` - попытка записи в файловый дескриптор;
- `open` - открыть файл для чтения или записи;
- `close` - закрыть файл после чтения или записи;
- `chdir` - изменить текущую директорию;
- `execve` - выполнить исполняемый файл;
- `stat` - получить информацию о файле;
- `mknod` - создать специальный файл, например, файл устройства или сокет;

А теперь разберём примеры `strace` Linux.

## **Запуск**

Системный вызов — это своего рода «обращение» программы к ядру ОС с просьбой выполнить то или иное действие. Необходимость в таких вызовах обусловлена тем, что процессы не могут напрямую взаимодействовать с системой (представьте, что было бы, если бы каждая программа, например, выделяла себе сколько угодно памяти или могла читать и писать какие угодно файлы!).

Работа `strace` заключается в отслеживании того, какие системные вызовы делает указанный процесс, а также какие сигналы он получает. Вообще, возможна ситуация, когда процесс не делает ни одного системного вызова. В этом случае, естественно, `strace` вам ничего не "отследит".

В общем случае запуск `strace` выглядит так:

```bash
strace program_name
```

Утилита запустит программу `program_name` и будет выводить в поток стандартного вывода сообщения о выполняемых системных вызовах. Зачастую засорение стандартного вывода сообщениями трассировки нежелательно, поскольку в нём будет трудно отыскать то, что выводит сам процесс, поэтому лучше перенаправить вывод `strace` в отдельный файл, который потом анализировать:

```bash
strace -o trace_output.txt program_name
```

Некоторые текстовые редакторы, например `Vim`, имеют цветовую подсветку вывода `strace`, что значительно помогает при анализе больших файлов с текстами трассировки.

Ещё, как вариант, можно запускать `strace` для трассировки уже запущенного процесса. Для этого необходимо знать `PID` нужного процесса и передать его в качестве параметра опции `-p` утилиты:

```bash
strace -o trace_output.txt -p 1234
```

## Анализ вывода

Предлагаю попробовать запустить что-нибудь и поглазеть, как `strace` ведёт себя в реальной жизни. Возьмём одну из наиболее часто используемых программ и посмотрим, что же она делает "за кулисами".

```bash
strace -o ~/strace.log /bin/ls
```

Вывод файла достаточно велик, поэтому здесь не выкладываю. Думаю, кому интересно, сами попробуют на своей системе. Рассмотрим лишь несколько строк в качестве примера.

```bash
execve("/bin/ls", ["/bin/ls"], 0x7ffc28d52f70 /* 26 vars */) = 0
brk(NULL)                               = 0x561942184000
arch_prctl(0x3001 /* ARCH_??? */, 0x7ffeedfde460) = -1 EINVAL (Invalid argument)
access("/etc/ld.so.preload", R_OK)      = -1 ENOENT (No such file or directory)
openat(AT_FDCWD, "/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3
fstat(3, {st_mode=S_IFREG|0644, st_size=25678, ...}) = 0
mmap(NULL, 25678, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7f2f60f22000
close(3)                                = 0
openat(AT_FDCWD, "/lib/x86_64-linux-gnu/libselinux.so.1", O_RDONLY|O_CLOEXEC) = 3
read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0@p\0\0\0\0\0\0"..., 832) = 832
fstat(3, {st_mode=S_IFREG|0644, st_size=163200, ...}) = 0
mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f2f60f20000
mmap(0x7f2f60f1c000, 174600, PROT_READ, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0x7f2f60ef5000
mprotect(0x7f2f60efb000, 135168, PROT_NONE) = 0
mmap(0x7f2f60efb000, 102400, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x6000) = 0x7f2f60efb000
mmap(0x7f2f60f14000, 28672, PROT_READ, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x1f000) = 0x7f2f60f14000
mmap(0x7f2f60f1c000, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x26000) = 0x7f2f60f1c000
mmap(0x7f2f60f1e000, 6664, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0x7f2f60f1e000
close(3)                                = 0
openat(AT_FDCWD, "/lib/x86_64-linux-gnu/libc.so.6", O_RDONLY|O_CLOEXEC) = 3
read(3, "\177ELF\2\1\1\3\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0\360q\2\0\0\0\0\0"..., 832) = 832
pread64(3, "\6\0\0\0\4\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0"..., 784, 64) = 784
pread64(3, "\4\0\0\0\20\0\0\0\5\0\0\0GNU\0\2\0\0\300\4\0\0\0\3\0\0\0\0\0\0\0", 32, 848) = 32
pread64(3, "\4\0\0\0\24\0\0\0\3\0\0\0GNU\0\363\377?\332\200\270\27\304d\245n\355Y\377\t\334"..., 68, 880) = 68
fstat(3, {st_mode=S_IFREG|0755, st_size=2029224, ...}) = 0
pread64(3, "\6\0\0\0\4\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0"..., 784, 64) = 784
pread64(3, "\4\0\0\0\20\0\0\0\5\0\0\0GNU\0\2\0\0\300\4\0\0\0\3\0\0\0\0\0\0\0", 32, 848) = 32
pread64(3, "\4\0\0\0\24\0\0\0\3\0\0\0GNU\0\363\377?\332\200\270\27\304d\245n\355Y\377\t\334"..., 68, 880) = 68
mmap(NULL, 2036952, PROT_READ, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0x7f2f60d03000
mprotect(0x7f2f60d28000, 1847296, PROT_NONE) = 0
mmap(0x7f2f60d28000, 1540096, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x25000) = 0x7f2f60d28000
mmap(0x7f2f60ea0000, 303104, PROT_READ, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x19d000) = 0x7f2f60ea0000
mmap(0x7f2f60eeb000, 24576, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x1e7000) = 0x7f2f60eeb000
mmap(0x7f2f60ef1000, 13528, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0x7f2f60ef1000
close(3)                                = 0
openat(AT_FDCWD, "/lib/x86_64-linux-gnu/libpcre2-8.so.0", O_RDONLY|O_CLOEXEC) = 3
read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0\340\"\0\0\0\0\0\0"..., 832) = 832
fstat(3, {st_mode=S_IFREG|0644, st_size=584392, ...}) = 0
mmap(NULL, 586536, PROT_READ, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0x7f2f60c73000
mmap(0x7f2f60c75000, 409600, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x2000) = 0x7f2f60c75000
mmap(0x7f2f60cd9000, 163840, PROT_READ, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x66000) = 0x7f2f60cd9000
mmap(0x7f2f60d01000, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x8d000) = 0x7f2f60d01000
close(3)                                = 0
openat(AT_FDCWD, "/lib/x86_64-linux-gnu/libdl.so.2", O_RDONLY|O_CLOEXEC) = 3
read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0 \22\0\0\0\0\0\0"..., 832) = 832
fstat(3, {st_mode=S_IFREG|0644, st_size=18816, ...}) = 0
mmap(NULL, 20752, PROT_READ, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0x7f2f60c6d000
mmap(0x7f2f60c6e000, 8192, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x1000) = 0x7f2f60c6e000
mmap(0x7f2f60c70000, 4096, PROT_READ, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x3000) = 0x7f2f60c70000
mmap(0x7f2f60c71000, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x3000) = 0x7f2f60c71000
close(3)                                = 0
openat(AT_FDCWD, "/lib/x86_64-linux-gnu/libpthread.so.0", O_RDONLY|O_CLOEXEC) = 3
read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0\220\201\0\0\0\0\0\0"..., 832) = 832
pread64(3, "\4\0\0\0\24\0\0\0\3\0\0\0GNU\0O\305\3743\364B\2216\244\224\306@\261\23\327o"..., 68, 824) = 68
fstat(3, {st_mode=S_IFREG|0755, st_size=157224, ...}) = 0
pread64(3, "\4\0\0\0\24\0\0\0\3\0\0\0GNU\0O\305\3743\364B\2216\244\224\306@\261\23\327o"..., 68, 824) = 68
mmap(NULL, 140408, PROT_READ, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0x7f2f60c4a000
mmap(0x7f2f60c51000, 69632, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x7000) = 0x7f2f60c51000
mmap(0x7f2f60c62000, 20480, PROT_READ, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x18000) = 0x7f2f60c62000
mmap(0x7f2f60c67000, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x1c000) = 0x7f2f60c67000
mmap(0x7f2f60c69000, 13432, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0x7f2f60c69000
close(3)                                = 0
mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f2f60c48000
arch_prctl(ARCH_SET_FS, 0x7f2f60c49400) = 0
mprotect(0x7f2f60eeb000, 12288, PROT_READ) = 0
mprotect(0x7f2f60c67000, 4096, PROT_READ) = 0
mprotect(0x7f2f60c71000, 4096, PROT_READ) = 0
mprotect(0x7f2f60d01000, 4096, PROT_READ) = 0
mprotect(0x7f2f60f1c000, 4096, PROT_READ) = 0
mprotect(0x561941595000, 4096, PROT_READ) = 0
mprotect(0x7f2f60f56000, 4096, PROT_READ) = 0
munmap(0x7f2f60f22000, 25678)           = 0
set_tid_address(0x7f2f60c496d0)         = 575033
set_robust_list(0x7f2f60c496e0, 24)     = 0
rt_sigaction(SIGRTMIN, {sa_handler=0x7f2f60c51bf0, sa_mask=[], sa_flags=SA_RESTORER|SA_SIGINFO, sa_restorer=0x7f2f60c5f3c0}, NULL, 8) = 0
rt_sigaction(SIGRT_1, {sa_handler=0x7f2f60c51c90, sa_mask=[], sa_flags=SA_RESTORER|SA_RESTART|SA_SIGINFO, sa_restorer=0x7f2f60c5f3c0}, NULL, 8) = 0
rt_sigprocmask(SIG_UNBLOCK, [RTMIN RT_1], NULL, 8) = 0
prlimit64(0, RLIMIT_STACK, NULL, {rlim_cur=8192*1024, rlim_max=RLIM64_INFINITY}) = 0
statfs("/sys/fs/selinux", 0x7ffeedfde3b0) = -1 ENOENT (No such file or directory)
statfs("/selinux", 0x7ffeedfde3b0)      = -1 ENOENT (No such file or directory)
brk(NULL)                               = 0x561942184000
brk(0x5619421a5000)                     = 0x5619421a5000
openat(AT_FDCWD, "/proc/filesystems", O_RDONLY|O_CLOEXEC) = 3
fstat(3, {st_mode=S_IFREG|0444, st_size=0, ...}) = 0
read(3, "nodev\tsysfs\nnodev\ttmpfs\nnodev\tbd"..., 1024) = 435
read(3, "", 1024)                       = 0
close(3)                                = 0
access("/etc/selinux/config", F_OK)     = -1 ENOENT (No such file or directory)
openat(AT_FDCWD, "/usr/lib/locale/locale-archive", O_RDONLY|O_CLOEXEC) = 3
fstat(3, {st_mode=S_IFREG|0644, st_size=3390256, ...}) = 0
mmap(NULL, 3390256, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7f2f6090c000
close(3)                                = 0
ioctl(1, TCGETS, {B38400 opost isig icanon echo ...}) = 0
ioctl(1, TIOCGWINSZ, {ws_row=63, ws_col=238, ws_xpixel=3808, ws_ypixel=2268}) = 0
openat(AT_FDCWD, ".", O_RDONLY|O_NONBLOCK|O_CLOEXEC|O_DIRECTORY) = 3
fstat(3, {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
getdents64(3, /* 42 entries */, 32768)  = 1424
getdents64(3, /* 0 entries */, 32768)   = 0
close(3)                                = 0
fstat(1, {st_mode=S_IFCHR|0620, st_rdev=makedev(0x88, 0x4), ...}) = 0
write(1, "adv  alert_install.sh  bashscrip"..., 229) = 229
close(1)                                = 0
close(2)                                = 0
exit_group(0)                           = ?
+++ exited with 0 +++
```

Структура каждой строки вывода `strace` следующая. Первым идёт имя системного вызова. Затем в круглых скобках выводится список параметров, переданных вызову. И последним, после знака равенства, отображается код завершения системного вызова. Подробную документацию по каждому системному вызову в случае необходимости можно найти на соответствующих man-страницах второго раздела.

## Резюме

`strace` может оказаться (и оказывается!) весьма полезной утилитой как для программистов, так и для системных администраторов, помогая отыскать причины "падений" или некорректной работы программ с закрытыми или недоступными исходными кодами.

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". 
