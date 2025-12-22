---
title: '[HowTo] Сброс пароля на коммутаторе HP 1910 серии'
description: "Подробное руководство по сбросу забытого или неизвестного пароля на коммутаторах HP 1910 и 3Com Baseline Switch 2952."
keywords:
- сброс пароля
- HP 1910
- коммутатор
- сетевое оборудование
- 3Com
- Baseline Switch 2952
- восстановление пароля
- PuTTY
- console кабель
- BootRom
date: "2018-01-07T21:40:57+03:00"
lastmod: "2018-01-07T21:40:57+03:00"
tags:
- hp1910
- network
categories: ["HowTo"]
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/iganpol)'
  image: howto.png
  relative: false
type: post
slug: 'hp1910-reset-password'
---

В данной заметке опишу способ сброса пароля на коммутаторе HP 1910 серии. А так как компания Hewlett-Packard поглотила в свое время 3Com и продолжила выпускать их продукцию уже под своим брендом, то написанное ниже будет справедливо также и для коммутаторов 3Com Baseline Switch 2952 и подобной серии.

Для выполнения процедуры сброса забытого или неизвестного пароля вам необходим физический доступ к устройству. Подключите коммутатор с помощью соединительного кабеля (идет в комплекте) из порта Console (**38400.8.1.N**) на самом свиче к com-порту компьютера. При этом мной используется программа  [PuTTY](http://www.putty.org "PuTTY"):

![2018-01-07_21-40_01](/wp-content/uploads/2018/01/2018-01-07_21-40_01.jpg)

Для установки соединения с помощью этой программы, в главном окне установите переключатель в **Serial**:

![2018-01-07_21-40_02](/wp-content/uploads/2018/01/2018-01-07_21-40_02.jpg)

Затем измените настройки подключения в:

- Speed (baud) – 38400;
- Data bits – 8;
- Stop bits – 1;
- Flow control – None.

![2018-01-07_21-40_03](/wp-content/uploads/2018/01/2018-01-07_21-40_03.jpg)

Нажмите кнопку `Open` и только после этого подайте электропитание на коммутатор. Теперь в начальный момент загрузки, когда на экране вы увидите надпись `Press Ctrl-B to enter Extended Boot menu`, вы должны успеть нажать требуемую комбинацию `Ctrl-B` на клавиатуре для входа в расширенное меню загрузки. На вопрос `Please input BootRom password`, просто нажмите ввод. По-умолчанию данный пароль пустой:

```bash
Starting……

*************************************  
* HP V1910-24G Switch BOOTROM, Version 158 *  
*************************************  
Copyright © 2010-2012 Hewlett-Packard Development Company, L.P.

Creation Date : Jun 15 2012  
CPU L1 Cache : 32KB  
CPU Clock Speed : 333MHz  
Memory Size : 128MB  
Flash Size : 128MB  
CPLD Version : 002  
PCB Version : Ver.B  
Mac Address : D07E284B2066

Press Ctrl-B to enter Extended Boot menu…0  
Please input BootRom password:

BOOT MENU

1. Download application file to flash  
2. Select application file to boot  
3. Display all files in flash  
4. Delete file from flash  
5. Modify BootRom password  
6. Enter BootRom upgrade menu  
7. Skip current system configuration  
8. Set BootRom password recovery  
9. Set switch startup mode  
10. Reboot

Enter your choice(0-9):
```

В данном меню выберите пункт `7 – Пропустить существующую системную настройку`, подтвердите свое желание, ответив `Y` на соответствующий вопрос, и выполните перезагрузку коммутатора, выбрав пункт меню `0`:

```bash
Enter your choice(0-9): 7  
The current setting will run with current configuration file when reboot.  
Are you sure you want to skip current configuration file when reboot? Yes or No  
(Y/N):Y  
Setting…Done!

BOOT MENU

1. Download application file to flash  
2. Select application file to boot  
3. Display all files in flash  
4. Delete file from flash  
5. Modify BootRom password  
6. Enter BootRom upgrade menu  
7. Skip current system configuration  
8. Set BootRom password recovery  
9. Set switch startup mode  
0. Reboot

Enter your choice(0-9): 0  
Starting……

*************************************  
* HP V1910-24G Switch BOOTROM, Version 158 *  
*************************************  
Copyright © 2010-2012 Hewlett-Packard Development Company, L.P.

Creation Date : Jun 15 2012  
CPU L1 Cache : 32KB  
CPU Clock Speed : 333MHz  
Memory Size : 128MB  
Flash Size : 128MB  
CPLD Version : 002  
PCB Version : Ver.B  
Mac Address : D07E284B2066

Press Ctrl-B to enter Extended Boot menu…0  
Starting to get the main application file—flash:/V1910-CMW520-R1513P06.bin!…  
……………………………………………………………………  
The main application file is self-decompressing……………………………  
……………………………………………………………………  
……Done!  
System is starting…  
Configuration file is skipped.  
User interface aux0 is available.

Press ENTER to get started.
```

Нажав ENTER, вы попадете сразу в командную строку. Нам надо войти в режим конфигурирования с помощью команды `_cmdline-mode on`, введя заводской пароль `512900`. После чего скопируем существующие настройки (если у вас есть такая необходимость) на встроенной флеш-карте в файл с другим названием:

```bash
_cmdline-mode on  
All commands can be displayed and executed. Continue? [Y/N]y  
Please input password:******  
Warning: Now you enter an all-command mode for developer's testing, some commands may affect operation  
by wrong use, please carefully use it with our engineer's direction.  
copy flash:/startup.cfg flash:/startup.bak  
Copy flash:/startup.cfg to flash:/startup.bak?[Y/N]:y  
.  
%Copy file flash:/startup.cfg to flash:/startup.bak...Done.
```

Теперь командой `initialize` произведем общий сброс устройства к заводским настройкам, после чего switch автоматически перезагрузится:

```bash
initialize  
The startup configuration file will be deleted and the system will be rebooted. Continue? [Y/N]:y  
Please wait…  
#Apr 26 12:03:27:703 2000 HP DEVM/1/REBOOT:  
Reboot device by command.

%Apr 26 12:03:27:793 2000 HP DEVM/5/SYSTEM_REBOOT: System is rebooting now.
```

При загрузке вы увидите информацию `Startup configuration file does not exist`. Все настройки были удалены. Логин и пароль по-умолчанию, используемые в коммутаторах данных серий:

- логин – Admin;
- пароль – пустой, его нет.

```bash
Starting……

*************************************  
* HP V1910-24G Switch BOOTROM, Version 158 *  
*************************************  
Copyright © 2010-2012 Hewlett-Packard Development Company, L.P.

Creation Date : Jun 15 2012  
CPU L1 Cache : 32KB  
CPU Clock Speed : 333MHz  
Memory Size : 128MB  
Flash Size : 128MB  
CPLD Version : 002  
PCB Version : Ver.B  
Mac Address : D07E284B2066

Press Ctrl-B to enter Extended Boot menu…0  
Starting to get the main application file—flash:/V1910-CMW520-R1513P06.bin!…  
……………………………………………………………………  
The main application file is self-decompressing……………………………  
……………………………………………………………………  
……Done!  
System is starting…  
Startup configuration file does not exist.  
User interface aux0 is available.

Press ENTER to get started.

Login authentication

Username:admin  
Password:  
```

Войдем снова в режим конфигурирования, а затем в `System View`, где доступны все существующие команды CLI с помощью `system-view` и просмотрим существующую конфигурацию по-умолчанию с помощью `display current-configuration`:

```bash
_cmdline-mode on  
All commands can be displayed and executed. Continue? [Y/N]y  
Please input password:******  
Warning: Now you enter an all-command mode for developer's testing, some commands may affect operation  
by wrong use, please carefully use it with our engineer's direction.  
system-view  
System View: return to User View with Ctrl+Z.  
[HP]display current-configuration  
#  
version 5.20, Release 1513P06  
#  
sysname HP  
#  
domain default enable system  
#  
ip ttl-expires enable  
#  
vlan 1  
#  
domain system  
access-limit disable  
state active  
idle-cut disable  
self-service-url disable  
#  
user-group system  
#  
local-user admin  
authorization-attribute level 3  
service-type ssh telnet terminal  
#  
stp mode rstp  
stp enable  
#  
interface NULL0  
#  
interface Vlan-interface1  
ip address dhcp-alloc  
#  
interface GigabitEthernet1/0/1  
stp edged-port enable  
#  
...  
interface GigabitEthernet1/0/28  
stp edged-port enable  
#  
user-interface aux 0  
authentication-mode scheme  
user-interface vty 0 15  
authentication-mode scheme  
#  
return  
[HP]
```

Выйти из этого режима можно с помощью `Ctrl+Z` или команды `quit`.

Во всех режимах, кроме `System View`, вам доступна команда `ipsetup`, с помощью которой вы можете быстро настроить сеть на данном коммутаторе, после чего мы можем изъять файл со старыми настройками, положив его на `tftp` сервер в вашей сети (или же скачать его через web-интерфейс управления свича на настроенном вами ip):

```bash
[HP]quit  
tftp 192.168.100.70 put flash:/startup.bak  
File will be transferred in binary mode  
Sending file to remote TFTP server. Please wait... |  
TFTP: 2839 bytes sent in 0 second(s).  
File uploaded successfully.
```

Подробнее про первоначальную настройку данного коммутатора в следующей статье.

Надеюсь, данная информация окажется кому-то полезной.

**PS**: Среди коммутаторов HP эту статью можно применить к моделям JE005A, JE006A, JE007A, JE008A, JE009A, JG348A, JG349A, JG350A

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)". 
