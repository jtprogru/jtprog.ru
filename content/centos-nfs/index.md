---
title: "[Linux] Установка NFS сервера на CentOS 7"
date: 2019-07-19T14:35:42+03:00
draft: false
slug: '/centos-nfs/'
description: 'Разворачиваем NFS сервер на базе CentOS 7'
categories: "Linux"
tags: ['centos', 'linux', 'nfs']
comments: true
noauthor: false
share: true
type: "post"
---
Привет, `%username%`! Рассмотрим довольно простую задачу: развернуть NFS-сервер на базе CentOS 7. Что и куда писать? Короче всё просто и легко!

### **Настройка NFS-сервера**
Выполняем в командной строке (нужны привилегии супер пользователя) следующие операции. Сначала устанавливает требуемые пакеты:
```bash
sudo yum install nfs-utils nfs-utils-lib
```
Затем включаем установленную службу:
```bash
sudo systemctl enable rpcbind
sudo systemctl enable nfs-server
sudo systemctl enable nfs-lock
sudo systemctl enable nfs-idmap
sudo systemctl start rpcbind
sudo systemctl start nfs-server
sudo systemctl start nfs-lock
sudo systemctl start nfs-idmap
```
После этого переходим к настройке каталога, который будет использоваться для раздачи контента нашим NFS сервером. Рекомендуется делать NFS шару в `/var/nfs_name`, чтобы не иметь проблем с записью файлов и назначением прав доступа. но мы не боимся трудностей и сделаем гораздо хитрожопее! Мы стандартно добавим отдельным LV раздел для шары, дабы в дальнейшем нам было легко и просто. В примере используется каталог `/nfs-share`. Итак, создаем папку и назначаем права доступа:
```bash
sudo mkdir -p /nfs-share
sudo chmod -R 777 /nfs-share
```
После этого необходимо добавить в файл `/etc/exports` информацию о предоставляемой шаре через NFS:
```bash
sudo nano /etc/exports
```
и добавляем строку:
```bash
/nfs-share      192.168.199.0/24(rw,sync,no_root_squash,no_all_squash)
```
При этом:

- `/nfs-share` – расшариваемая директория
- `192.168.199.0/24` – IP адрес клиента (в нашем случае подсеть - любой клиент из этой подсети)
- `rw` – разрешение на запись
- `sync` – синхронизация указанной директории
- `no_root_squash` – включение `root` привилегий
- `no_all_squash` — включение пользовательской авторизации

Выполняем в командной строке `exportfs -a`, чтобы подключить этот каталог в список экспортируемых. В завершение настройки NFS сервера перезапускаем его:
```bash
sudo systemctl restart nfs-server
```
Теперь добавляем (открываем) порты NFS сервера в брандмауэре (`firewalld`) для корректной работы в сети:
```bash
sudo firewall-cmd —permanent —add-port=111/tcp
sudo firewall-cmd —permanent —add-port=54302/tcp
sudo firewall-cmd —permanent —add-port=20048/tcp
sudo firewall-cmd —permanent —add-port=2049/tcp
sudo firewall-cmd —permanent —add-port=46666/tcp
sudo firewall-cmd —permanent —add-port=42955/tcp
sudo firewall-cmd —permanent —add-port=875/tcp
sudo firewall-cmd —permanent —zone=public —add-service=nfs
sudo firewall-cmd —permanent —zone=public —add-service=mountd
sudo firewall-cmd —permanent —zone=public —add-service=rpc-bind
sudo firewall-cmd —reload
```
Готово! Установка и настройка NFS сервера на CentOS 7 завершена.

### **Установка и настройка клиента NFS**

В завершении  рассмотрим процесс настройки клиента для подключения (работы) с развернутым ранее NFS сервером. Для чего выполняем следующие команды:
```bash
sudo yum install nfs-utils nfs-utils-lib
```
Включаем сервис и активируем автозагрузку:
```bash
sudo systemctl enable rpcbind
sudo systemctl enable nfs-server
sudo systemctl enable nfs-lock
sudo systemctl enable nfs-idmap
sudo systemctl start rpcbind
sudo systemctl start nfs-server
sudo systemctl start nfs-lock
sudo systemctl start nfs-idmap
```
Создаем каталог, куда будем монтировать шару:
```bash
sudo mkdir /media/nfs_share
sudo mount -t nfs 192.168.199.101:/nfs-share/ /media/nfs_share/
```
Добавление автомонтирования при включение системы:
```bash
sudo vim /etc/fstab
```
Примерное содержимое файла:
```bash
/dev/mapper/centos-root /                       xfs     defaults        1 1
UUID=2ba8d78a-c420-4792-b381-5405d755e544 /boot                   xfs     defaults        1 2
/dev/mapper/centos-swap swap                    swap    defaults        0 0
192.168.199.101:/nfs-share/ /media/nfs_share/ nfs rw,sync,hard,intr 0 0
```
Проверяем, что все примонтировалось правильно:
```bash
sudo mount -fav
```
Радуемся жизни! На этом всё!
