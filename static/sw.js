// PWA kill-switch.
//
// Раньше блог регистрировал service worker и кешировал HTML/статику.
// PWA отключён (params.PWA.enabled: false), но у части посетителей в
// браузере остался зарегистрированный SW от прошлой версии — он мог
// перехватывать запросы (например, отдавать 404 для /index.json).
//
// При апдейте SW браузер делает install→activate новой версии. Мы:
//   1. На install сразу skipWaiting, чтобы старый воркер не блокировал.
//   2. На activate чистим все кеши, unregister-имся и просим открытые
//      вкладки сделать reload — после этого SW исчезает из браузера.
//   3. Все fetch — passthrough в сеть, никакого кеша.
//
// Файл лежит в static/ (а не в теме), чтобы оставаться по адресу /sw.js
// даже при выключенной PWA-логике темы.

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    try {
      const keys = await caches.keys();
      await Promise.all(keys.map((k) => caches.delete(k)));
    } catch (_) {}
    try {
      await self.registration.unregister();
    } catch (_) {}
    try {
      const clients = await self.clients.matchAll({ type: 'window' });
      clients.forEach((client) => client.navigate(client.url));
    } catch (_) {}
  })());
});

self.addEventListener('fetch', (event) => {
  event.respondWith(fetch(event.request));
});
