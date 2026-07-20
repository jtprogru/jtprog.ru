---
title: 'Что происходит, когда ты открываешь сайт'
description: "Полный путь запроса от нажатия Enter до пикселя на экране: кэши браузера, DNS, TCP и TLS, CDN и BGP, приём пакета ядром Linux, nginx и рендеринг."
keywords:
  - что происходит когда открываешь сайт
  - путь HTTP-запроса
  - DNS resolution
  - TCP three-way handshake
  - TLS handshake
  - NAPI softirq
  - сетевой стек Linux
  - рендеринг браузера
  - HTTP/3 QUIC
  - BGP Anycast
  - congestion control
  - вопрос на собеседовании
date: "2026-07-20T12:00:00+03:00"
lastmod: "2026-07-20T12:00:00+03:00"
tags:
  - networking
  - linux
  - dns
  - tls
  - basics
categories: ["Basics"]
cover:
  image: cover.png
  alt: 'Разрез стека: этажи от браузера до приложения, светится один'
  relative: true
type: post
slug: 'what-happens-when-you-open-website'
aliases:
  - '/what-happens-when-you-open-website/'
params:
  math: false
---

Привет, `%username%`! Ты вводишь адрес, жмёшь Enter — и через мгновение видишь страницу. Выглядит как одно действие. Под капотом же — [каскад процессов](https://aws.amazon.com/blogs/mobile/what-happens-when-you-type-a-url-into-your-browser/), прошивающий все уровни системы: от физических прерываний процессора до алгоритмов рендеринга браузера. Разберём [весь путь](https://habr.com/ru/companies/gnivc/articles/861432/) — локальный и глобальный — от нажатия клавиши до отрисовки последнего пикселя на экране.

Спойлер: этот вопрос не зря любят на собеседованиях — по тому, где кандидат останавливается, видно всю его карту знаний. Про то, что там спрашивают ещё, я писал [после полусотни собесов](/posts/after-50-interview/). И полезен он не ради галочки: когда знаешь, из каких этажей состоит путь, «сайт тормозит» перестаёт быть магией и превращается в конкретный этаж, на котором надо копать.

## Локальный компьютер: до первого пакета

### Ввод URL и обработка клавиатурных событий

Всё начинается с физического нажатия клавиши. Каждое нажатие генерирует **hardware interrupt** (аппаратное прерывание), которое передаётся процессору. Клавиатура, как периферийное устройство, отправляет сигнал контроллеру прерываний, тот приостанавливает текущее выполнение процессора и вызывает **interrupt service routine (ISR)** — специальную процедуру обработки прерывания.

Во время обработки прерывания происходит [**context switch**](https://www.lenovo.com/us/en/glossary/context-switch/) — сохранение состояния текущего процесса (регистры процессора, program counter, stack pointer) и загрузка контекста обработчика. После обработки нажатия система генерирует события [`keydown`](https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent), которые браузер перехватывает через JavaScript API и прогоняет через свой [**event loop**](https://javascript.plainenglish.io/understand-javascripts-event-loop-36c021f850f7) — механизм, управляющий очередями задач и синхронизирующий их с **rendering pipeline**.

После ввода полного URL и нажатия Enter браузер парсит адрес, разделяя его на компоненты: протокол (`https://`), доменное имя (`example.com`), путь (`/page`) и query-параметры. По умолчанию браузеры используют HTTPS (порт 443).

### Проверка кэшей браузера до сетевого запроса

Прежде чем инициировать DNS resolution, браузер проходит цепочку локальных кэшей — и во многих случаях сетевой запрос вообще не понадобится. Порядок такой: сначала **HTTP-кэш браузера** (memory cache для текущей сессии и disk cache между запусками) — если ресурс ещё свежий по [`Cache-Control`/`Expires`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Caching), он отдаётся со статусом `from memory cache` / `from disk cache`, без единого пакета в сеть. Если ресурс формально устарел, но у него есть валидатор (`ETag` или `Last-Modified`), браузер отправляет [**conditional request**](https://datatracker.ietf.org/doc/html/rfc9111) (`If-None-Match` / `If-Modified-Since`) и может получить `304 Not Modified` — заголовки приходят, тело не передаётся.

Выше HTTP-кэша стоит **Service Worker**: если на origin зарегистрирован SW, он перехватывает `fetch` и способен отдать ответ из **Cache Storage** полностью офлайн, вообще минуя сеть. Отдельно существует **bfcache (back/forward cache)** — снимок полностью живой страницы (с DOM и состоянием JS), который позволяет мгновенно вернуться по кнопкам «назад/вперёд» без повторного парсинга и рендеринга.

Только промах во всей этой цепочке приводит к реальному сетевому пути, описанному ниже. Именно поэтому повторное открытие сайта визуально мгновенно: львиная доля ресурсов не доходит даже до стадии DNS.

### DNS Resolution: преобразование имени в IP-адрес

Прежде чем браузер сможет установить соединение с сервером, ему надо преобразовать человекочитаемое доменное имя в IP-адрес — процесс, называемый [**DNS resolution**](https://cycle.io/learn/dns-resolution-process). Процесс многоступенчатый, с несколькими уровнями кэширования.

Сначала браузер проверяет свой **локальный DNS-кэш**. Если записи нет, запрос уходит операционной системе, которая проверяет системный кэш (на современных дистрибутивах за это отвечает `systemd-resolved` — про его настройку у меня есть [отдельный пост](/posts/systemd-resolved/)). При промахе в обоих кэшах запрос отправляется к **DNS resolver** — обычно это DNS-сервер провайдера или публичный DNS (Google 8.8.8.8, Cloudflare 1.1.1.1).

Resolver выполняет **рекурсивный запрос** от имени клиента. Если у него нет кэшированной записи, он обращается к [**Root DNS-серверам**](https://www.geeksforgeeks.org/computer-networks/address-resolution-in-dns-domain-name-server/) — 13 логических серверов (`a`–`m.root-servers.net`), каждый из которых на деле Anycast-кластер из сотен нод по всему миру. Root DNS не знает конкретного IP-адреса, но направляет запрос к **TLD-серверам**, отвечающим за зоны верхнего уровня (`.com`, `.org`, `.ru`).

TLD-сервер направляет запрос к **Authoritative DNS-серверу** конкретного домена, который и возвращает финальный IP. Весь процесс обычно занимает от 20 до 120 миллисекунд в зависимости от удалённости серверов и состояния кэшей.

[Рекурсивный и итеративный запросы](https://dev.to/wallacefreitas/understanding-domain-name-system-dns-recursive-iterative-queries-with-root-level-domains-581n) — не одно и то же: при рекурсивном resolver берёт на себя всю работу по обходу иерархии, при итеративном клиент сам последовательно обращается к каждому уровню.

### CDN, Anycast и edge: куда на самом деле резолвится имя

Описанная выше цепочка для крупного сайта почти никогда не заканчивается на origin-сервере. Authoritative DNS для домена вроде `cnn.com` обычно делегирован **CDN** (Cloudflare, Akamai, Fastly, CloudFront), и он возвращает не фиксированный IP конкретного дата-центра, а адрес ближайшей **edge-точки**.

Работают два механизма приближения:

- **GeoDNS / EDNS Client Subnet** — authoritative-сервер смотрит на подсеть резолвера (или клиента) и отдаёт разный ответ в зависимости от географии.
- [**Anycast**](https://www.cloudflare.com/learning/cdn/glossary/anycast-network/) — один и тот же IP-адрес анонсируется по BGP из десятков локаций мира, так что пакет естественным образом доходит до топологически ближайшей ноды.

В результате TCP- и TLS-handshake происходят не с origin в другом полушарии, а с edge-нодой в десятках километров: **RTT** падает с ~100–150 мс до единиц миллисекунд. А это ключевой множитель для TCP slow start и числа TLS round-trips. На edge отдаётся закэшированный статический контент, а к origin запрос уходит только при cache miss или за динамикой — часто по уже прогретому keep-alive соединению. Попутно CDN обычно терминирует TLS на edge и первым в цепочке поддерживает свежие протоколы (HTTP/3, TLS 1.3), даже если origin о них не знает.

### Установление TCP-соединения: трёхстороннее рукопожатие

Получив IP-адрес, браузер готов установить транспортное соединение. Для HTTP/HTTPS используется **TCP** — надёжный протокол с установлением соединения, а само установление идёт через [**three-way handshake**](https://networkwalks.com/tcp-3-way-handshake-process/).

Клиент отправляет [**SYN-пакет**](https://www.geeksforgeeks.org/computer-networks/tcp-3-way-handshake-process/) с начальным sequence number — случайным числом для синхронизации и защиты от подделки. Сервер отвечает **SYN-ACK**, который одновременно подтверждает SYN клиента (увеличивая sequence number на 1) и несёт собственный SYN со своим sequence number. Клиент завершает рукопожатие **ACK-пакетом**.

В процессе ОС выполняет [системные вызовы](https://www.gta.ufrj.br/ensino/eel878/sockets/syscalls.html) `socket()` и `connect()` для создания сокета и инициации соединения. Сокет — это конечная точка двунаправленной связи между процессами. Клиент использует эфемерный порт (IANA-диапазон 49152–65535; Linux по умолчанию берёт из 32768–60999, см. `net.ipv4.ip_local_port_range`), а сервер слушает на стандартном порту (80 для HTTP, 443 для HTTPS). Кто хочет увидеть, как эфемерные порты ломают жизнь на практике, — почитай про [активный и пассивный режимы FTP](/posts/ftp-passive-vs-active/).

### Управление потоком и перегрузкой: MSS, MTU, congestion control

Three-way handshake — это не только синхронизация sequence numbers. В SYN-пакетах стороны согласуют опции, критичные для производительности:

- **MSS (Maximum Segment Size)** — максимальный размер полезной нагрузки TCP-сегмента, выводимый из **MTU** канала (обычно 1500 байт для Ethernet → MSS ≈ 1460).
- **Window Scale** — множитель, позволяющий окну превышать 64 КБ.
- **SACK (Selective Acknowledgment)** и timestamps.

Если по пути встречается канал с меньшим MTU, срабатывает фрагментация или (при выставленном бите DF) [**Path MTU Discovery**](https://datatracker.ietf.org/doc/html/rfc1191) через ICMP. А вот если ICMP заботливо прибит на файрволе — получаешь «PMTU black hole»: соединение устанавливается, мелкие пакеты ходят, а крупные молча теряются и передача виснет. Классика жанра, на которую убивают часы, прежде чем догадаться посмотреть на MTU.

После установки соединения объём данных «в полёте» ограничен сразу двумя окнами: **receive window** (flow control — сколько готов принять получатель) и **congestion window / cwnd** (congestion control — сколько сеть готова пропустить без потерь). TCP стартует с малого cwnd (**initial window**, обычно 10 сегментов) и в фазе [**slow start**](https://datatracker.ietf.org/doc/html/rfc5681) наращивает его экспоненциально каждый RTT, затем переходит в линейный рост (**congestion avoidance**); при потере (таймаут или три dup ACK) окно резко сокращается.

Именно slow start объясняет ценность первых ~14 КБ ответа (см. видео [«Почему ваш сайт должен весить 14 КБ»](https://youtu.be/fmiqceS8ZNg)) — они умещаются в initial window и приходят за один round-trip, тогда как всё сверх того требует новых RTT на «раскачку». Современные стеки используют **CUBIC** (дефолт Linux, реагирует на потери) и [**BBR**](https://queue.acm.org/detail.cfm?id=3022184) (моделирует пропускную способность и RTT, а не ждёт потерь).

### TLS Handshake: установление защищённого канала

Для HTTPS после установления TCP следует ещё один этап — [**TLS handshake**](https://www.cloudflare.com/learning/ssl/what-happens-in-a-tls-handshake/). Он устанавливает зашифрованный канал и подтверждает, что сервер — тот, за кого себя выдаёт.

Клиент отправляет **ClientHello**: версию TLS (обычно [TLS 1.3](https://datatracker.ietf.org/doc/html/rfc8446)), список поддерживаемых [**cipher suites**](https://en.wikipedia.org/wiki/Cipher_suite), 32 байта случайных данных и расширения (например, SNI — Server Name Indication). Cipher suites в TLS 1.3 используют только AEAD-алгоритмы вроде [AES-256-GCM с SHA384](https://ciphersuite.info/cs/TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384/) и обязательно применяют ECDHE для обмена ключами, что даёт forward secrecy.

Сервер отвечает [**ServerHello**](https://www.ibm.com/docs/en/ibm-mq/9.3.x?topic=tls-overview-ssltls-handshake), выбирая cipher suite из предложенных, и отправляет свой набор случайных данных. Затем передаёт **цифровой сертификат**, который клиент проверяет: сертификат содержит публичный ключ сервера и подписан доверенным Certificate Authority.

Далее — **обмен ключами**: клиент генерирует [pre-master secret](https://wiki.osdev.org/TLS_Handshake), шифрует его публичным ключом сервера и отправляет в **ClientKeyExchange**. Обе стороны из обменянных случайных данных и pre-master secret независимо вычисляют одинаковый master secret, из которого выводятся симметричные ключи.

Финальный этап — обмен **ChangeCipherSpec** и **Finished**, уже зашифрованными новыми ключами. [TLS 1.3 срезал](https://www.encryptionconsulting.com/tls-1-2-and-tls-1-3/) handshake с двух RTT до одного (а с session resumption — до нуля, 0-RTT) и выкинул устаревшие небезопасные алгоритмы вроде RSA key exchange.

### Формирование и отправка HTTP-запроса

После установления защищённого соединения браузер готов отправить HTTP-запрос. [Структура запроса](https://www.linode.com/docs/guides/http-get-request/) состоит из **request line** (метод, путь, версия HTTP), **заголовков** и опционального **тела**.

Request line для главной страницы обычно выглядит как `GET / HTTP/1.1`. За ним следуют [заголовки](https://beeceptor.com/docs/concepts/http-headers/), каждый на отдельной строке: `Host: example.com` (обязательный), `User-Agent: Mozilla/5.0...`, `Accept: text/html,application/xhtml+xml...`, `Accept-Language: ru,en`, `Accept-Encoding: gzip, deflate, br`, `Connection: keep-alive`, `Cache-Control: max-age=0`.

Сформированный запрос передаётся через системный вызов `send()` или `write()`, который копирует данные из user space в kernel space в [socket buffer](https://www.linuxjournal.com/article/6345). Дальше ядро обрабатывает их через network stack, готовя к передаче по сети.

### HTTP→HTTPS, редиректы и HSTS

Реальный первый запрос редко сразу попадает в целевой ресурс. Если пользователь ввёл голый домен или `http`-URL, срабатывает несколько механизмов.

Первый — [**HSTS (HTTP Strict Transport Security)**](https://datatracker.ietf.org/doc/html/rfc6797): если домен есть в HSTS **preload list**, вшитом в браузер, или ранее прислал заголовок `Strict-Transport-Security`, браузер ещё до выхода в сеть сам заменяет `http://` на `https://` (internal redirect 307), исключая небезопасный первый хоп и возможность SSL-stripping.

Второй — [**серверные редиректы**](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Redirections): сервер отвечает статусами `301`/`302`/`307`/`308` с заголовком `Location`, и браузер повторяет путь для нового URL — иногда с новым DNS/TCP/TLS, если сменился хост.

Типичная цепочка выглядит как `http://cnn.com` → `https://cnn.com` → `https://www.cnn.com`. Каждый лишний редирект — дополнительный RTT (а при смене хоста ещё и новый TLS-handshake), поэтому их число минимизируют. Различается и семантика кэширования: `301` и `308` (permanent) браузер кэширует и в следующий раз идёт по конечному адресу сразу, тогда как `302` и `307` (temporary) не кэшируются.

### Версии протокола: HTTP/1.1, HTTP/2, HTTP/3 (QUIC)

Показанный выше `GET / HTTP/1.1` — упрощение: версия прикладного протокола согласуется ещё в TLS через **ALPN (Application-Layer Protocol Negotiation)** внутри ClientHello.

[**HTTP/1.1**](https://httpwg.org/specs/rfc9112.html) — текстовый протокол, где одно соединение обслуживает один запрос в момент времени; параллелизм достигается открытием 6+ TCP-соединений на домен, и он страдает от **head-of-line (HoL) blocking** на уровне запросов.

[**HTTP/2**](https://datatracker.ietf.org/doc/html/rfc9113) — бинарный, мультиплексирует множество **streams** в одном TCP-соединении, добавляет сжатие заголовков (**HPACK**) и server push (ныне депрекейтед); но остаётся уязвим к **TCP-level HoL blocking** — потеря одного пакета тормозит все streams, потому что упорядочивание идёт на уровне TCP.

[**HTTP/3**](https://datatracker.ietf.org/doc/html/rfc9114) работает поверх [**QUIC**](https://datatracker.ietf.org/doc/html/rfc9000) — транспорта на UDP вместо TCP. QUIC объединяет транспортный и криптографический handshake (TLS 1.3 встроен внутрь), устанавливая соединение за 1-RTT или даже 0-RTT, а мультиплексирование делает на своём уровне — потеря пакета в одном stream не блокирует остальные, то есть transport-level HoL blocking устранён. Дополнительно QUIC переживает смену сети через **connection migration** по Connection ID: соединение не рвётся при переключении Wi-Fi ↔ LTE.

Для сайта за CDN клиент почти наверняка говорит по HTTP/2 или HTTP/3, а не по «учебному» HTTP/1.1.

## Сетевой путь: от пакета к кадру

### Прохождение через сетевой стек: инкапсуляция

Данные HTTP-запроса проходят вниз по [сетевому стеку](https://blog.nicolasmesa.co/posts/2018/08/what-happens-when-you-type-a-url-in-your-browser-and-press-enter/) через **инкапсуляцию** — последовательное добавление заголовков на каждом уровне.

На **транспортном уровне (L4)** данные разбиваются на **TCP-сегменты**. К каждому добавляется TCP-заголовок: source port (эфемерный порт клиента), destination port (443 для HTTPS), sequence number, acknowledgment number, flags (ACK, PSH и др.), window size, checksum.

На **сетевом уровне (L3)** сегмент инкапсулируется в [**IP-пакет**](https://textbook.cs168.io/routing/ip-header.html). IP-заголовок включает: version (4 для IPv4), header length, total length, identification (для сборки фрагментов), flags и fragment offset, [**TTL (Time To Live)**](https://networklessons.com/ip-routing/ipv4-packet-header) — счётчик, уменьшающийся на каждом роутере, **protocol field** (6 для TCP, 17 для UDP), header checksum, source IP, destination IP.

Каждый роутер на пути декрементирует TTL на 1, и если значение достигает 0, пакет отбрасывается, а отправителю уходит ICMP Time Exceeded. Это предотвращает routing loops — и заодно на этом механизме работает `traceroute`.

На [**канальном уровне (L2)**](https://chessman7.substack.com/p/layer-2-network-operations-how-ethernet) IP-пакет инкапсулируется в [**Ethernet frame**](https://www.networkacademy.io/ccna/network-fundamentals/data-link-layer). Заголовок содержит destination MAC (6 байт), source MAC (6 байт), EtherType (2 байта, `0x0800` для IPv4, `0x86DD` для IPv6). В конце кадра добавляется FCS (Frame Check Sequence) — контрольная сумма для обнаружения ошибок передачи.

### ARP Resolution: преобразование IP в MAC-адрес

Прежде чем отправить кадр, система должна определить MAC-адрес следующего узла в локальной сети — обычно это адрес default gateway. Для этого используется [**ARP (Address Resolution Protocol)**](https://en.wikipedia.org/wiki/Address_Resolution_Protocol).

Система сначала проверяет [**ARP cache**](https://blogs.oracle.com/linux/arp-internals) — таблицу соответствий IP → MAC в оперативной памяти. Если соответствия нет, отправляется **ARP Request** — широковещательный пакет с destination MAC `FF:FF:FF:FF:FF:FF`, который получают все устройства в локальной сети. Смысл запроса: «Кто имеет IP 192.168.1.1? Сообщите на MAC AA:BB:CC:DD:EE:FF».

Устройство с этим IP отвечает [**ARP Reply**](https://www.fortinet.com/resources/cyberglossary/what-is-arp) — unicast-пакетом со своим MAC. Система обновляет ARP cache и отправляет кадр. В Linux запись держится в состоянии reachable около 30 секунд (`base_reachable_time` с джиттером), потом переходит в stale и перед следующим использованием перепроверяется.

### Маршрутизация: путь через роутеры

После определения MAC-адреса кадр передаётся сетевому адаптеру (NIC) через [**DMA (Direct Memory Access)**](https://en.wikipedia.org/wiki/Direct_memory_access) — NIC напрямую копирует данные из системной памяти без участия CPU.

Кадр попадает в [**transmit ring buffer**](https://stackoverflow.com/questions/47450231/what-is-the-relationship-of-dma-ring-buffer-and-tx-rx-ring-for-a-network-card) — кольцевой буфер дескрипторов пакетов в оперативной памяти, разделяемый между драйвером и NIC. NIC читает дескрипторы, получает адреса пакетов в памяти и передаёт данные на физический уровень.

Пакет достигает первого роутера (обычно домашнего шлюза), который выполняет **de-encapsulation и re-encapsulation**: снимает Ethernet-заголовок, анализирует IP-заголовок, проверяет [**routing table**](https://en.wikipedia.org/wiki/Routing_table) для определения next hop, декрементирует TTL, пересчитывает IP checksum и создаёт новый Ethernet-кадр с новыми MAC-адресами.

Процесс повторяется на каждом роутере. Ключевое: **IP-пакет (L3) остаётся неизменным от источника до получателя** (за исключением TTL и checksum), тогда как **Ethernet-кадр (L2) пересоздаётся на каждом hop**. IP-адреса определяют конечную точку назначения, MAC-адреса используются только для доставки кадра на следующий hop.

Routing table содержит записи в формате: network prefix, netmask, next hop, interface. При получении пакета роутер выполняет [**longest prefix match**](https://jumpcloud.com/it-index/what-is-a-forwarding-table) — находит наиболее специфичное правило, соответствующее destination IP. Если соответствия нет, пакет отправляется через default route (`0.0.0.0/0`).

### BGP: маршрутизация между автономными системами

Longest prefix match объясняет, как роутер выбирает next hop среди известных ему маршрутов, но не откуда берётся сама глобальная карта интернета. Домашний роутер знает лишь default route «всё незнакомое — провайдеру». Дальше пакет попадает в сеть ISP и движется между **автономными системами (AS)** — независимо управляемыми сетями (провайдеры, дата-центры, CDN), каждой из которых присвоен номер **ASN**. Маршруты между AS распространяет [**BGP (Border Gateway Protocol)**](https://datatracker.ietf.org/doc/html/rfc4271) — протокол, на котором держится весь междоменный роутинг.

BGP-роутеры на границах AS обмениваются анонсами достижимости префиксов (например, «сеть `151.101.0.0/16` доступна через `AS54113`») и выбирают путь не по кратчайшей метрике, а по **политикам**: длина AS-path, local preference, коммерческие отношения (peering vs transit). BGP-анонсы и делают возможным Anycast из раздела про CDN: один префикс анонсируется из многих точек, и каждый узел выбирает ближайшую по своим политикам.

Уязвимость модели — доверие к анонсам: ошибочный или злонамеренный анонс чужого префикса (**BGP hijack**) уводит трафик не туда. Классика жанра — 2008 год, когда Pakistan Telecom, пытаясь заблокировать YouTube внутри страны, анонсировал его префикс на весь мир и уронил сервис глобально. Частичная защита — **RPKI** и фильтрация маршрутов. Внутри одной AS работают уже IGP-протоколы (**OSPF**, **IS-IS**), а BGP отвечает именно за стык между AS.

## Сервер: от прерывания до приложения

### Приём пакета: hardware interrupt и DMA

Когда пакет достигает NIC сервера, начинается [обратный процесс](https://metebalci.com/blog/how-a-nic-rx-works/). NIC получает электрические сигналы, декодирует их в биты, проверяет FCS и сравнивает destination MAC с собственным адресом.

При успешной проверке NIC через **DMA копирует пакет** из своей внутренней памяти в системную RAM, помещая его в [**receive ring buffer**](https://maxnilz.com/docs/004-network/005-linux-rx/) — кольцевой массив дескрипторов в kernel space, предварительно выделенный драйвером.

После завершения DMA-передачи NIC генерирует [**hardware interrupt (IRQ)**](https://blog.packagecloud.io/monitoring-tuning-linux-networking-stack-receiving-data/), сигнализируя CPU, что пакет готов к обработке. Прерывания сетевых карт бывают трёх типов: **MSI-X**, **MSI** и **legacy interrupts**. MSI-X предпочтительнее — позволяет назначить отдельное прерывание каждой receive queue, что улучшает параллелизм на многоядерных системах.

### Обработка прерывания: ISR и контекстное переключение

При получении hardware interrupt процессор выполняет **context switch** в kernel mode. Процессоры поддерживают несколько [**privilege levels**](https://www.geeksforgeeks.org/operating-systems/difference-between-user-mode-and-kernel-mode/): **Ring 0 (kernel mode)** — полный доступ ко всем системным ресурсам, и **Ring 3 (user mode)** — доступ только к адресному пространству процесса.

При переключении в kernel mode CPU сохраняет текущее состояние (program counter, stack pointer, регистры, flags) в PCB (Process Control Block) текущего процесса. Затем загружается адрес **interrupt handler (ISR)** из interrupt vector table и начинается его выполнение.

Для сетевых карт ISR выполняет минимум работы: подтверждает прерывание, **отключает дальнейшие прерывания от NIC** и планирует обработку пакета на уровне **softirq**. Зачем отключать: если бы NIC продолжал генерировать hardware interrupt на каждый пакет при высоком трафике, система тратила бы всё CPU-время на обработку прерываний, не успевая фактически обрабатывать пакеты — явление, известное как [**interrupt storm** или **livelock**](https://lwn.net/Articles/1008399/).

### NAPI и SoftIRQ: эффективная batch-обработка

Для решения проблемы interrupt overload в Linux используется механизм [**NAPI (New API)**](https://docs.kernel.org/networking/napi.html). NAPI комбинирует [interrupt-driven подход с polling](https://wiki.linuxfoundation.org/networking/napi): первый пакет генерирует прерывание, после чего драйвер переключается в режим polling для batch-обработки последующих.

ISR вызывает `napi_schedule()`, которая добавляет NAPI-структуру драйвера в список запланированных softirq и поднимает флаг **NET_RX_SOFTIRQ**. [Softirq](https://mirror.xyz/fanyadan.eth/OVMiK-NGKk_nYgX5AY75TcGJDZozfL2mYBdcslTnyi8) — механизм отложенной обработки в ядре, выполняющийся с приоритетом ниже hardware interrupts, но выше обычных процессов.

**Softirq processing** происходит в контексте ядра сразу после обработки hardware interrupts или при выходе из системного вызова. Softirq может выполняться **параллельно на нескольких CPU** — на этом держится масштабирование сетевой обработки. Для каждого CPU ядро поддерживает отдельную очередь softirq.

При выполнении NET_RX_SOFTIRQ вызывается `net_rx_action()`, которая обходит список NAPI-структур и вызывает `poll()` каждого драйвера. Poll-функция [извлекает пакеты из receive ring buffer](https://blog.packagecloud.io/illustrated-guide-monitoring-tuning-linux-networking-stack-receiving-data/) (до определённого budget — обычно 64 пакета), обрабатывает их и передаёт выше по стеку. Если poll обработал всё доступное (или упёрся в budget), он вызывает `napi_complete()`, которая повторно включает hardware interrupts от NIC.

Если сервер держит серьёзную нагрузку, тюнинг всего этого хозяйства (размеры очередей, backlog, TCP-параметры) делается через `sysctl` — по этому поводу есть [отдельная шпаргалка](/posts/sysctl-hl/).

### RPS/RFS: распределение нагрузки по CPU

Для масштабирования на многоядерных системах Linux использует [**RPS (Receive Packet Steering)** и **RFS (Receive Flow Steering)**](https://docs.kernel.org/networking/scaling.html). RPS — программная реализация RSS (Receive Side Scaling), распределяющая обработку пакетов по разным CPU.

RPS вычисляет хэш от заголовков пакета (source/destination IP и port) и по нему выбирает целевой CPU из настроенного списка. Пакет помещается в **per-CPU backlog queue** этого CPU, и генерируется **IPI (Inter-Processor Interrupt)**, чтобы разбудить обработку на удалённом CPU. Так все пакеты одного потока обрабатываются одним CPU — лучше cache locality.

RFS идёт дальше, пытаясь направить обработку пакета на тот же CPU, где работает приложение, принимающее эти данные. Данные с большой вероятностью уже в CPU cache — latency ниже.

### Прохождение через network stack: от Ethernet к TCP

Извлечённый из ring buffer пакет представлен в ядре структурой [**sk_buff (socket buffer)**](https://thinkpalm.com/blogs/how-linux-kernel-handles-network-packets/) — универсальной структурой для сетевых пакетов в Linux. Она содержит указатели на заголовки разных уровней и на сами данные, что позволяет передавать пакет между уровнями стека без копирования.

На **канальном уровне (L2)** ядро проверяет Ethernet-заголовок: сравнивает destination MAC с адресами локальных интерфейсов, проверяет FCS, извлекает EtherType.

На **сетевом уровне (L3)** вызывается `ip_rcv()`: проверяет версию, валидирует header length и total length, проверяет IP checksum, декрементирует TTL (если TTL=0 — пакет отбрасывается), пересчитывает checksum, выполняет routing decision через lookup в routing table. Если пакет предназначен локальной машине, он передаётся на транспортный уровень; если требует forwarding — выполняется маршрутизация и re-encapsulation.

Перед передачей на транспортный уровень пакет проходит через **Netfilter hooks** — точки перехвата для firewall-правил (iptables/nftables), NAT и connection tracking. Именно здесь пакет может тихо умереть по правилу, которое кто-то накатил полгода назад — [шпаргалка по iptables](/posts/iptables-manual/) в помощь.

На **транспортном уровне (L4)** функция протокола (для TCP — `tcp_v4_rcv()`) проверяет TCP checksum, выполняет **socket demultiplexing** — поиск соответствующего сокета по 4-tuple (source IP, source port, destination IP, destination port), обновляет состояние TCP-соединения, обрабатывает TCP flags и помещает данные в **socket receive buffer** — очередь, из которой приложение будет читать.

Для TLS-соединений данные всё ещё зашифрованы на этом этапе и будут расшифрованы уже в user space приложением или TLS-библиотекой.

### Load balancer: распределение перед web server

У крупного сайта пакет, дошедший до дата-центра, почти никогда не попадает напрямую на процесс web server — сначала он проходит через [**балансировщик нагрузки**](https://www.cloudflare.com/learning/performance/what-is-load-balancing/). Различают два уровня.

**L4-балансировщик** (транспортный) распределяет по IP и порту, не заглядывая в HTTP, и работает в двух режимах:

- **proxy / in-line** — весь трафик, туда и обратно, идёт через балансировщик, который терминирует TCP;
- **DSR (Direct Server Return)** — запрос приходит через LB, но ответ backend отправляет клиенту напрямую, минуя балансировщик, что снимает с него обратный (обычно куда более объёмный) трафик.

**L7-балансировщик / reverse proxy** (прикладной) терминирует TLS, читает HTTP и маршрутизирует по `Host`/path/cookie, обеспечивает sticky sessions, health checks, retry и circuit breaking (Nginx, HAProxy, Envoy, облачные ALB). Про то, как это настраивается в nginx, у меня есть пост про [балансировку бэкендов](/posts/nginx-lb/), а про архитектуру в целом — [про кластеризацию и доступность](/posts/ha-clustering/).

Алгоритмы распределения — round-robin, least connections, hash по IP или URL, weighted. За балансировщиком стоит пул backend-серверов, и уже выбранный экземпляр проходит путь «сокет → приложение». На практике перед origin выстраивается целая цепочка: **CDN edge → L4 LB → L7 reverse proxy → web server → application server**, и на каждом стыке возможны свои keep-alive пулы соединений и собственный слой кэширования.

### Web Server: от сокета к приложению

Web server (Nginx, Apache) узнаёт о доступности данных через механизмы **event notification**: `epoll` (Linux), `kqueue` (BSD) или `select`/`poll`. Они позволяют мониторить тысячи сокетов одновременно и получать уведомления, только когда данные доступны для чтения или записи.

При получении события сервер вызывает [`recv()`](https://man7.org/linux/man-pages/man2/recv.2.html) или `recvmsg()`, который копирует данные из kernel socket buffer в user space buffer приложения. Копирование пересекает границу kernel-user space, что стоит денег. Для минимизации существуют техники zero-copy (`sendfile`, `splice`).

Получив запрос, web server **парсит его структуру**: request line (метод, URI, версия HTTP), заголовки, опциональное тело.

Nginx использует [асинхронную event-driven архитектуру](https://nginx.org/en/docs/http/request_processing.html) с небольшим числом worker-процессов (обычно по одному на CPU core). Каждый worker обрабатывает множество одновременных соединений в одном потоке через non-blocking I/O и event loop. Так Nginx держит десятки тысяч соединений с минимумом памяти. Apache традиционно использовал **prefork MPM**, где каждый запрос обрабатывается отдельным процессом, или **worker MPM** с thread pool; современные версии поддерживают и **event MPM**, аналогичный nginx.

Дальше web server выполняет **routing** на основе конфигурации: для статических файлов читает файл с диска и отправляет клиенту, для динамического контента перенаправляет запрос к application server (PHP-FPM, Python WSGI, Node.js) через FastCGI, HTTP proxy или другие протоколы. Какой именно [server block](/posts/virt-host-nginx/) обработает запрос — определяется по заголовку `Host`, и это, кстати, частый источник сюрпризов, когда запрос улетает в дефолтный виртуалхост.

### Обработка приложением и формирование ответа

Application server выполняет бизнес-логику: парсинг query-параметров и request body, валидацию и аутентификацию, обращения к базе, вызовы внешних API, рендеринг шаблонов, формирование ответа.

После обработки формируется **HTTP response**: status line (`HTTP/1.1 200 OK`), заголовки (Content-Type, Content-Length, Cache-Control, Set-Cookie), пустая строка-разделитель, тело ответа.

[**Cache-Control заголовки**](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Cache-Control) управляют [кэшированием на стороне клиента и промежуточных proxy](https://web.dev/articles/http-cache):

- `Cache-Control: max-age=31536000, immutable` — для статики с версионированием (CSS, JS с hash в имени);
- `Cache-Control: no-cache` — для ресурсов, требующих revalidation перед использованием;
- `Cache-Control: no-store` — для приватных данных, которые кэшировать нельзя вообще.

Response передаётся обратно через `send()` или `sendfile()` (для статических файлов), данные копируются в kernel space, TCP-стек сегментирует их, IP-стек инкапсулирует в пакеты, Ethernet-стек создаёт кадры. Пакеты помещаются в **transmit ring buffer**, NIC через DMA читает их и передаёт на физический уровень. Response идёт обратным путём через интернет к клиенту.

## Браузер: рендеринг и отображение

### Приём и парсинг HTTP response

Сервер ответил — мяч снова на стороне клиента. Response-пакеты проходят тот же путь: hardware interrupt, DMA в ring buffer, softirq, network stack, TCP reassembly — и попадают в socket buffer.

Браузерный network thread вызывает `recv()` для чтения данных. [Response parser](https://dev.to/bennyxguo/learn-how-the-browser-works-in-practice-http-request-and-parsing-4fdg) обрабатывает структуру: status line (200, 301, 404, 500), response headers (Content-Type определяет тип контента и способ парсинга, Content-Length — для прогресса загрузки, `Transfer-Encoding: chunked` — для streaming), тело — собственно HTML, CSS, JavaScript, изображения.

### HTML Parsing и построение DOM

Получив HTML, браузер начинает [**parsing**](https://dev.to/ayush_maurya_/how-browsers-parse-and-render-html-from-request-to-paint-1ogp) — преобразование текстового HTML в DOM (Document Object Model).

Процесс начинается с **tokenization**: парсер читает байты, декодирует их в символы согласно charset (обычно UTF-8), сканирует символы и выделяет токены — start tags (`<div>`), end tags (`</div>`), attributes (`class="container"`), text content, comments.

Из токенов строится **DOM tree**: открывающий тег создаёт новый node и становится текущим родителем, текстовое содержимое создаёт text node как дочерний, закрывающий тег возвращает контекст к родителю. DOM tree — иерархическая структура, где каждый HTML-элемент представлен объектом со свойствами, методами и связями parent-child-sibling.

Во время парсинга браузер обнаруживает ссылки на внешние ресурсы (CSS, JavaScript, images, fonts) и начинает их загрузку параллельно. Для этого используется **preload scanner** — лёгковесный парсер, который сканирует HTML на предмет ресурсов, не дожидаясь основного парсера.

### CSS Parsing и CSSOM

Когда браузер встречает `<link rel="stylesheet">` или `<style>`, он загружает CSS и начинает парсинг в [**CSSOM (CSS Object Model)**](https://leapcell.io/blog/how-css-affects-parsing-and-rendering). CSS-парсер похож на HTML-парсер: tokenization, парсинг селекторов и правил, построение CSSOM tree, где каждый node представляет CSS rule с селектором и объявлениями свойств.

**CSS блокирует рендеринг.** Браузер не будет отрисовывать страницу, пока не загрузит и не распарсит все CSS-файлы, на которые есть ссылки в `<head>`. Это предотвращает FOUC (Flash of Unstyled Content), но замедляет initial render. Поэтому критический CSS инлайнят в `<head>`, а некритический загружают асинхронно.

### JavaScript: выполнение и блокировка

JavaScript имеет особое влияние на парсинг и рендеринг. Когда браузер встречает `<script>`, **парсинг HTML останавливается**. Почему? Потому что скрипт может манипулировать DOM (`document.write()`, создание/удаление элементов), и браузер не знает заранее, что он там сделает, поэтому обязан дождаться выполнения.

Процесс: браузер загружает скрипт (если src внешний), компилирует JavaScript в байт-код или machine code (JIT в V8, SpiderMonkey, JavaScriptCore), выполняет его, и только после этого возобновляется HTML-парсинг.

Для оптимизации используются атрибуты:

- `async` — скрипт загружается параллельно и выполняется, как только загрузится, не блокируя парсинг загрузкой (но выполнение всё равно блокирует);
- `defer` — скрипт загружается параллельно, но выполняется только после полного парсинга HTML, перед событием DOMContentLoaded.

### Render Tree и Layout

После построения DOM и CSSOM браузер объединяет их в [**Render Tree**](https://bytebytego.com/guides/how-does-the-browser-render-a-web-page/) — структуру, содержащую только видимые элементы с их вычисленными стилями. Render Tree не включает элементы с `display: none`, `<head>`, `<script>` и другие невидимые nodes.

Следующий этап — **Layout (reflow)**, где браузер вычисляет точное положение и размеры каждого элемента: расчёт box model (content, padding, border, margin), применение positioning (static, relative, absolute, fixed, sticky), вычисление flexbox и grid, обработку text flow и word wrapping.

Layout — дорогая операция, особенно на сложных страницах. Изменения, влияющие на layout (resize, изменение font-size, добавление/удаление элементов), вызывают reflow всего дерева или его части.

### Painting и Compositing

После Layout следует **Paint** — растеризация элементов в пиксели. Браузер создаёт **paint records** — команды для рисования каждого элемента: заполнение фонов, отрисовка границ, текста и теней, применение эффектов (box-shadow, border-radius).

Дальше — **compositing**: разделение страницы на слои (layers) и отдельный рендеринг каждого. Элементы с `transform`, `opacity`, `position: fixed`, `will-change` часто создают отдельные слои. Compositing слоёв делает GPU — отсюда плавные анимации и скроллинг.

Финальный этап — **display**: скомпозированные слои отправляются в графический буфер, который выводится на экран. На мониторе с частотой 60 Hz это должно происходить каждые ~16.67 мс.

### Event Loop и Rendering Pipeline

Браузерный [**Event Loop**](https://webperf.tips/tip/event-loop/) координирует выполнение JavaScript и рендеринг. Цикл работает так: из **task queue** (macrotask queue) берётся одна задача (timer callbacks, I/O, events), задача выполняется до завершения, затем полностью обрабатывается [**microtask queue**](https://adityaprabhat.hashnode.dev/event-loop-and-asynchrony-in-javascript) (Promise callbacks, MutationObserver), после чего проверяется, нужно ли рендерить.

**Rendering pipeline** выполняется примерно раз в 16 мс (для 60 fps). Если подошло время рендера: выполняются **requestAnimationFrame callbacks**, вычисляется Layout, выполняется Paint, делается Compositing.

Если JavaScript-задача выполняется слишком долго (long task > 50 мс), она блокирует Event Loop — рендеринг не происходит, страница перестаёт отвечать. Поэтому тяжёлые операции разбивают на chunks, а фоновые вычисления уносят в Web Workers.

## Ключевые прерывания и системные вызовы

Путь пройден целиком — теперь шпаргалка: соберём в одном месте всё, что по дороге дёргало ядро.

### Hardware Interrupts

За время открытия сайта **hardware interrupts** случаются постоянно: **keyboard interrupts** при вводе URL, **network interrupts (IRQ)** при приёме/отправке пакетов, **timer interrupts** — для preemptive multitasking.

Каждое прерывание вызывает context switch, сохранение состояния CPU, выполнение ISR, восстановление состояния. Частые прерывания создают overhead, поэтому применяют interrupt coalescing (группировка нескольких событий в одно прерывание) и NAPI polling для batch-обработки.

### Software Interrupts (SoftIRQ)

**Softirq** — механизм отложенной обработки в ядре. Основные типы для сети: **NET_RX_SOFTIRQ** для приёма пакетов (обработка receive ring buffer, передача пакетов вверх по стеку) и **NET_TX_SOFTIRQ** для отправки (завершение передачи, освобождение буферов).

Softirq выполняются в kernel context на высоком приоритете, но ниже hardware interrupts. Они могут прерывать user processes, но не могут прерывать hardware interrupt handlers.

### System Calls

**System calls** — интерфейс между user space и ядром:

| Группа | Вызовы | Что делают |
| --- | --- | --- |
| Socket operations | `socket()`, `bind()`, `listen()`, `accept()`, `connect()` | создание сокета, привязка к адресу, приём и инициация соединений |
| Data transfer | `send()`, `sendto()`, `sendmsg()`, `recv()`, `recvfrom()`, `recvmsg()` | отправка и приём данных |
| File operations | `read()`, `write()`, `open()`, `close()` | чтение/запись (работают и с сокетами), работа с дескрипторами |
| I/O multiplexing | `select()`, `poll()`, `epoll()` | мониторинг множества файловых дескрипторов |

Каждый system call вызывает переключение из user mode в kernel mode: процессор переходит в [Ring 0](https://unix-learn.moabukar.co.uk/kernel/kernel-privilege-levels/), выполняет операцию в kernel space, копирует результаты обратно в user space и возвращается в Ring 3. Эти переключения не бесплатны (context switch, TLB flush), поэтому оптимизация часто сводится к минимизации числа system calls. Посмотреть, что именно процесс дёргает у ядра, можно через [`strace`](/posts/strace/) — очень отрезвляющее упражнение.

## Что с этим делать на практике

Главная ценность этой карты не в том, чтобы пересказать её на собеседовании, а в том, чтобы по симптому сразу понимать, на каком этаже искать. Вот примерное соответствие:

| Симптом | Этаж | Чем смотреть |
| --- | --- | --- |
| Долгая пауза до начала загрузки | DNS resolution | `dig +trace example.com`, `resolvectl query` |
| Соединение висит на connect | TCP handshake, файрвол | `tcpdump -ni any port 443`, `ss -tan`, [iptables](/posts/iptables-manual/) |
| Мелкие запросы идут, крупные виснут | PMTU black hole | `ping -M do -s 1472`, проверка ICMP на пути |
| Высокий TTFB при быстрой сети | backend, БД, application server | логи с временем ответа ([nginx в JSON](/posts/nginx-json-logs/)) |
| Скачет latency под нагрузкой | congestion control, очереди ядра | `ss -ti`, `netstat -s`, [тюнинг sysctl](/posts/sysctl-hl/) |
| Запрос улетел не в тот бэкенд | L7-роутинг, `Host`, [server blocks](/posts/virt-host-nginx/) | `curl -v -H 'Host: ...'`, логи балансировщика |
| Страница загрузилась, но «тупит» | Event Loop, long tasks, reflow | вкладка Performance в DevTools |
| Сеть «медленная» без конкретики | пропускная способность канала | [`iperf3`](/posts/iperf3/) между узлами |

Эта же карта работает и в обратную сторону — когда систему надо не чинить, а спроектировать: примерно так я разбирал [задачку с собеса про высоконагруженный сервис](/posts/interview-task-0003/).

Порядок диагностики — сверху вниз по стеку, а не наугад: сначала убеждаешься, что имя резолвится, потом что соединение устанавливается, потом что сервер отвечает, и только потом лезешь в приложение. Половина «загадочных» инцидентов разваливается уже на первых двух шагах.

## Тонкие места, на которых легко споткнуться

- **ICMP не «лишний трафик».** Заблокировав его целиком «для безопасности», ты ломаешь Path MTU Discovery и получаешь соединения, которые устанавливаются, но зависают на крупных ответах. Симптом максимально неочевидный.
- **TTL кэша DNS живёт дольше, чем ты думаешь.** Между твоим изменением записи и реальным переключением трафика стоят кэши браузера, ОС, резолвера провайдера и промежуточных нод. Снижай TTL заранее, до миграции, а не в момент.
- **HSTS — билет в один конец.** Отдал заголовок с большим `max-age` — и браузеры пользователей будут ходить только по HTTPS всё это время, даже если у тебя сломался сертификат. Тестируй с маленьким `max-age`.
- **`301` кэшируется навсегда.** Ошибочный permanent-редирект прилипает в браузерах пользователей, и откатить его на своей стороне ты уже не можешь. Пока не уверен — отдавай `302`.
- **Первые ~14 КБ бесплатны, остальное — нет.** Из-за initial window всё, что не влезло в первый round-trip, требует дополнительных RTT. Критический CSS в `<head>` — не мода, а арифметика.
- **HTTP/2 не лечит потери пакетов.** Мультиплексирование в одном TCP-соединении означает, что одна потеря тормозит все streams разом. На плохих каналах HTTP/2 может оказаться хуже HTTP/1.1 с несколькими соединениями — вот от этого и лечит QUIC.
- **Каждый редирект — это RTT.** Цепочка `http` → `https` → `www` на мобильном канале с RTT 150 мс стоит почти полсекунды ещё до того, как придёт первый байт HTML.
- **Эфемерные порты кончаются.** На балансировщике или прокси с большим числом исходящих соединений диапазон `net.ipv4.ip_local_port_range` и `TIME_WAIT` становятся реальным потолком. Проявляется внезапно и под нагрузкой.

## Заключение

От первого hardware interrupt до последнего пикселя — каждый этап этого пути вылизан десятилетиями инженерной работы. Но полезен он не как энциклопедическая справка, а как карта для дебага: когда понимаешь, где живут DNS resolution, TLS handshake, softirq и reflow, «сайт тормозит» перестаёт быть магией. У каждой проблемы появляется конкретный этаж, на котором её надо искать: где-то поможет `tcpdump`, где-то — вкладка Performance в DevTools, а где-то — просто [нормальный мониторинг](/posts/wat-monitoring/), который покажет проблему до того, как о ней напишут в поддержку.

И в следующий раз, когда страница откроется «мгновенно», ты будешь знать, сколько всего успело случиться за эти пару сотен миллисекунд.

---

Если у тебя есть вопросы, комментарии и/или замечания – заходи в [чат](https://ttttt.me/jtprogru_chat), а так же подписывайся на [канал](https://ttttt.me/jtprogru_channel).

О способах отблагодарить автора можно почитать на странице "[Донаты](https://jtprog.ru/donations/)".
