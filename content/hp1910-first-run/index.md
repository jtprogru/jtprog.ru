---
categories: howto
cover:
  alt: howto
  caption: 'Illustrated by [Igan Pol](https://www.behance.net/dreamwolf97d61e)'
  image: howto.png
  relative: false
date: "2018-01-07T22:10:30+03:00"
tags:
- hp1910
- network
title: '[HowTo] Начальная настройка коммутатора HP 1910 серии'
type: post
---


По собственному желанию напишу о том, как выполнить начальную настройку коммутаторов HP 1910 серии и братьев-близнецов от 3Com – Baseline Switch 2952 и подобной серии. Вся настройка будет производиться через CLI (Command Line Interface), так как пользоваться web-интерфейсом подчас просто неудобно!

Как осуществить подключение к данному коммутатору, синтаксис команд для входа в режим конфигурирования, я написал в [предыдущей статье](https://jtprog.ru/hp1910-reset-password/).

Итак, подключаемся к устройству и входим в режим `System View`. Просмотрим, что уже сконфигурировано, задаем имя нашему коммутатору (`Main-Switch`), устанавливаем часовую зону (Москва), устанавливаем время и текущую дату, любуемся результатами:

```bash
Press ENTER to get started.  
Login authentication  
Username:admin  
Password:  
<hp>
#Apr 26 12:00:32:638 2000 HP SHELL/4/LOGIN:  
Trap 1.3.6.1.4.1.25506.2.2.1.1.3.0.1:admin login from Console  
%Apr 26 12:00:32:763 2000 HP SHELL/5/SHELL_LOGIN: admin logged in from aux0.  
<hp>_cmdline-mode on  
All commands can be displayed and executed. Continue? [Y/N]y  
Please input password:******  
Warning: Now you enter an all-command mode for developer's testing, some commands may affect operation  
by wrong use, please carefully use it with our engineer's direction.  
<hp>system-view  
System View: return to User View with Ctrl+Z.  
[HP]display current-configuration  
[HP]sysname Main-Switch  
[Main-Switch]clock timezone MSK4 add 04:00:00  
[Main-Switch]quit  

clock datetime 12:47:00 02/06/2013  

system-view  
System View: return to User View with Ctrl+Z.  
[Main-Switch]display clock  
12:47:10 MSK4 Wed 02/06/2013  
Time Zone : MSK4 add 04:00:00  
[Main-Switch]
```

Теперь активируем необходимые сервисы (Telnet и SSH), задаем супер-пароль и пароль локальному пользователю `admin` (пароли задавайте свои). По желанию, вы можете завести своего пользователя (не забудьте только дать ему разрешение на интересующие вас сервисы: `ssh`, `telnet` или `terminal`):

```bash
[Main-Switch]telnet server enable  
% Start Telnet server  
[Main-Switch]ssh server enable  
Info: Enable SSH server.  
[Main-Switch]super password level 3 simple PASS1  
[Main-Switch]local-user admin  
[Main-Switch-luser-admin]password simple PASS2  
[Main-Switch-luser-admin]quit  
[Main-Switch]
```

Настроим параметры интерфейса `Vlan-interface1` (в который объединены по-умолчанию все сетевые интерфейсы коммутатора): его описание, ip-адрес, установим маршрут по-умолчанию (`192.168.0.1` – маршрутизатор), настроим сервис сетевого времени ntp (на `192.168.0.1` работает `ntpd` сети):

```bash
[Main-Switch]interface Vlan-interface1  
[Main-Switch-Vlan-interface1]description LOCALNET  
[Main-Switch-Vlan-interface1]ip address 192.168.0.10 255.255.255.0  
[Main-Switch-Vlan-interface1]quit  
[Main-Switch]ip route-static 0.0.0.0 0.0.0.0 192.168.0.1  
[Main-Switch]ntp-service source-interface Vlan-interface1  
[Main-Switch]ntp-service unicast-server 192.168.0.1
```

Зададим настройки для DNS:

```bash
[Main-Switch]dns domain domain.ru  
[Main-Switch]dns server 192.168.0.2  
[Main-Switch]dns source-interface Vlan-interface1
```

Пусть, к примеру, с 1 по 6 интерфейс нашего коммутатора будут не использованными. Зададим каждому из них описание и “опустим” его:

```bash
[Main-Switch]interface GigabitEthernet 1/0/1  
[Main-Switch-GigabitEthernet1/0/1]description NOT-USED  
[Main-Switch-GigabitEthernet1/0/1]shutdown  
[Main-Switch-GigabitEthernet1/0/1]quit  
[Main-Switch]
```

Если вы желаете собирать статистику с помощью `snmp`, вам необходимо сделать следующие настройки:

```bash
[Main-Switch]snmp-agent  
[Main-Switch]snmp-agent community read public  
[Main-Switch]snmp-agent community write private  
[Main-Switch]snmp-agent sys-info contact support@domain.ru  
[Main-Switch]snmp-agent sys-info location SIT, Domian  
[Main-Switch]snmp-agent sys-info version all
```

Про настройку `vlan`. Допустим в нашей сети существует `vlan 100`, предназначенный для гостей и сторонних пользователей. Разберем общий случай, когда наш настраиваемый сейчас коммутатор является “проходным”. Т.е. к нему непосредственно подключено два “гостя” из подсети, настроенной для `vlan 100` (порты `GigabitEthernet 1/0/20` и `GigabitEthernet 1/0/21`, в которых будет непосредственно тегированный трафик) и два порта являются транслирующими гибридными (`GigabitEthernet 1/0/27` и `GigabitEthernet 1/0/28`, по которым идет и тегированный трафик, и нетегированный).

Обозначим наличие нашего `vlan` и сделаем описание для портов `GigabitEthernet 1/0/20` и `GigabitEthernet 1/0/21`:

```bash
[Main-Switch]vlan 100  
[Main-Switch-vlan100]description GUESTNET  
[Main-Switch-vlan100]port GigabitEthernet 1/0/20  
[Main-Switch-vlan100]port GigabitEthernet 1/0/21  
[Main-Switch-vlan100]quit  
[Main-Switch]interface GigabitEthernet 1/0/20  
[Main-Switch-GigabitEthernet1/0/20]description GUEST1  
[Main-Switch-GigabitEthernet1/0/20]quit  
[Main-Switch]interface GigabitEthernet 1/0/21  
[Main-Switch-GigabitEthernet1/0/21]description GUEST2  
[Main-Switch-GigabitEthernet1/0/21]quit  
[Main-Switch]
```

Настроим гибридные порты `GigabitEthernet 1/0/27` и `GigabitEthernet 1/0/28`:

```bash
[Main-Switch]interface GigabitEthernet 1/0/27  
[Main-Switch-GigabitEthernet1/0/27]description TO-SERVERN  
[Main-Switch-GigabitEthernet1/0/27]port link-type hybrid  
[Main-Switch-GigabitEthernet1/0/27]port hybrid vlan 100 tagged  
Please wait... Done.  
[Main-Switch-GigabitEthernet1/0/27]port hybrid vlan 1 untagged  
Please wait... Done.  
[Main-Switch-GigabitEthernet1/0/27]quit  
[Main-Switch]interface GigabitEthernet 1/0/28  
[Main-Switch-GigabitEthernet1/0/28]description TO-OTHERS  
[Main-Switch-GigabitEthernet1/0/28]port link-type hybrid  
[Main-Switch-GigabitEthernet1/0/28]port hybrid vlan 100 tagged  
Please wait... Done.  
[Main-Switch-GigabitEthernet1/0/28]port hybrid vlan 1 untagged  
Please wait... Done.  
[Main-Switch-GigabitEthernet1/0/28]quit  
[Main-Switch]
```

Теперь можно просмотреть, что у нас получилось и сохраним сделанные изменения:

```bash
[Main-Switch]display current-configuration  
  
version 5.20, Release 1513P06  
  
sysname Main-Switch  
  
clock timezone MSK4 add 04:00:00  
  
super password level 3 cipher $c$3$b+gWAA1NfPIXi2Rnzk/ABXPTg6E+/38A2g==  
  
domain default enable system  
  
dns server 192.168.0.2  
dns domain domain.ru  
dns source-interface Vlan-interface1  
  
telnet server enable  
  
ip ttl-expires enable  
  
vlan 1  
  
vlan 100  
description GUESTNET  
  
domain system  
access-limit disable  
state active  
idle-cut disable  
self-service-url disable  
  
user-group system  
  
local-user admin  
password cipher $c$3$ef/TRA/SrMaU2S9HxDEhhGMIUoivTrkdnA==  
authorization-attribute level 3  
service-type ssh telnet terminal  
  
stp mode rstp  
stp enable  
  
interface NULL0  
  
interface Vlan-interface1  
description LOCALNET  
ip address 192.168.0.10 255.255.255.0  
  
interface GigabitEthernet1/0/1  
description NOT-USED  
shutdown  
stp edged-port enable  
...  
  
interface GigabitEthernet1/0/7  
stp edged-port enable  
...  
  
interface GigabitEthernet1/0/20  
description GUEST1  
port access vlan 100  
stp edged-port enable  
  
interface GigabitEthernet1/0/21  
description GUEST2  
port access vlan 100  
stp edged-port enable  
#  
interface GigabitEthernet1/0/22  
stp edged-port enable  
...  
#  
interface GigabitEthernet1/0/26  
stp edged-port enable  
#  
interface GigabitEthernet1/0/27  
description TO-SERVERN  
port link-type hybrid  
port hybrid vlan 100 tagged  
port hybrid vlan 1 untagged  
stp edged-port enable  
#  
interface GigabitEthernet1/0/28  
description TO-OTHERS  
port link-type hybrid  
port hybrid vlan 100 tagged  
port hybrid vlan 1 untagged  
stp edged-port enable  
#  
ip route-static 0.0.0.0 0.0.0.0 192.168.0.1  
#
snmp-agent  
snmp-agent local-engineid 800063A203D07E284B2068  
snmp-agent community read public  
snmp-agent community write private  
snmp-agent sys-info contact support@domain.ru  
snmp-agent sys-info location SIT, Domian  
snmp-agent sys-info version all  
#  
ntp-service source-interface Vlan-interface1  
ntp-service unicast-server 192.168.0.1  
#  
ssh server enable  
#  
user-interface aux 0  
authentication-mode scheme  
user-interface vty 0 15  
authentication-mode scheme  
# 
return  
[Main-Switch]save  
The current configuration will be written to the device. Are you sure? [Y/N]:y  
Please input the file name(*.cfg)[flash:/startup.cfg]  
(To leave the existing filename unchanged, press the enter key):  
Validating file. Please wait....  
Saved the current configuration to mainboard device successfully.  
Configuration is saved to device successfully.  
[Main-Switch]
```

Как настроен тот или иной элемент вашей конфигурации можно просмотреть с помощью команды `display` + ...

```bash
[Main-Switch]display dns server  
Type:  
D:Dynamic S:Static  
DNS Server Type IP Address  
1 S 192.168.0.2  
[Main-Switch]display ntp-service status  
Clock status: synchronized  
Clock stratum: 3  
Reference clock ID: 192.168.0.1  
Nominal frequency: 100.0000 Hz  
Actual frequency: 100.0000 Hz  
Clock precision: 2^17  
Clock offset: -0.0863 ms  
Root delay: 10.89 ms  
Root dispersion: 26.96 ms  
Peer dispersion: 16.68 ms  
Reference time: 10:34:41.318 UTC Feb 6 2013(D4BCB041.5177318F)  
[Main-Switch]display vlan 100  
VLAN ID: 100  
VLAN Type: static  
Route Interface: not configured  
Description: GUESTNET  
Name: VLAN 0100  
Tagged Ports:  
GigabitEthernet1/0/27 GigabitEthernet1/0/28  
Untagged Ports:  
GigabitEthernet1/0/20 GigabitEthernet1/0/21  
[Main-Switch]display ssh server status  
SSH server: Enable  
SSH version : 1.99  
SSH authentication-timeout : 60 second(s)  
SSH server key generating interval : 0 hour(s)  
SSH authentication retries : 3 time(s)  
SFTP server: Disable  
SFTP server Idle-Timeout: 10 minute(s)  
[Main-Switch]display snmp-agent sys-info  
The contact person for this managed node:  
support@domain.ru  
The physical location of this node:  
SIT, Domian  
SNMP version running in the system:  
SNMPv1 SNMPv2c SNMPv3
```

Отменить какую-либо настройку можно с помощью команды `undo`.

Вот, в принципе, и все. Именно с такими настройками у меня работает несколько коммутаторов в сети с поддержкой нескольких `vlan`.

**PS**: Среди коммутаторов HP эту статью можно применить к моделям JE005A, JE006A, JE007A, JE008A, JE009A, JG348A, JG349A, JG350A

---
Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).
