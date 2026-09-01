/* Cup Season service worker.
   Strategy: network-first for navigations (users must never get pinned to a
   stale build — version bumps ship via Netlify on every push), cache-first for
   same-origin static assets, and hands-off for everything cross-origin
   (Supabase auth/realtime, Google Fonts). Bump VERSION with the client version
   so each deploy retires the previous cache. */
const VERSION = '__CS_VERSION__';
const CACHE = `cupseason-${VERSION}`;
const SHELL = [
  '/',
  /* The data layer. Same-origin since 2026-09-01 (it was an esm.sh import, and
     line 34's cross-origin bypass meant it was NEVER cached — an installed PWA
     re-fetched it on every cold load and died silently without it). */
  '/vendor/supabase-js.js',
  '/manifest.webmanifest',
  '/icon-192.png',
  '/icon-512.png',
  '/icon-512-maskable.png',
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url);
  if (e.request.method !== 'GET') return;
  if (url.origin !== self.location.origin) return; // never intercept Supabase/fonts

  if (e.request.mode === 'navigate') {
    // Network-first: fresh HTML when online, cached shell when offline.
    e.respondWith(
      fetch(e.request)
        .then((res) => {
          // Only the app shell is cached under '/': a legal page or a 5xx body
          // used to overwrite the offline shell.
          if (res.ok && url.pathname === '/') {
            const copy = res.clone();
            caches.open(CACHE).then((c) => c.put('/', copy));
          }
          return res;
        })
        .catch(() => (url.pathname === '/' ? caches.match('/') : Response.error()))
    );
    return;
  }

  // Static same-origin assets: cache-first, backfill on miss.
  e.respondWith(
    caches.match(e.request).then(
      (hit) =>
        hit ||
        fetch(e.request).then((res) => {
          if (res.ok) {
            const copy = res.clone();
            caches.open(CACHE).then((c) => c.put(e.request, copy));
          }
          return res;
        })
    )
  );
});

self.addEventListener('push', (e) => {
  let d = {};
  try { d = e.data ? e.data.json() : {}; } catch (_) {}
  e.waitUntil(self.registration.showNotification(d.title || 'Cup Season', {
    body: d.body || '',
    icon: '/icon-192.png',
    badge: '/icon-192.png',
    data: { url: d.url || '/' },
  }));
});

self.addEventListener('notificationclick', (e) => {
  e.notification.close();
  const url = (e.notification.data && e.notification.data.url) || '/';
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
      for (const c of list) {
        if (!('focus' in c)) continue;
        /* focus() alone DISCARDED the target: an already-open tab stayed exactly
           where it was, so a notification's url was honoured only when no tab
           was open. Navigate first when it differs, then focus. A no-op today
           (every payload carries '/'), correct the moment one does not. */
        const target = new URL(url, self.location.origin).href;
        const go = (c.url !== target && 'navigate' in c)
          ? c.navigate(url).catch(() => c)
          : Promise.resolve(c);
        return go.then((t) => (t || c).focus());
      }
      return clients.openWindow(url);
    })
  );
});
