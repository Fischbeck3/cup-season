/* Cup Season service worker.
   Strategy: network-first for navigations (users must never get pinned to a
   stale build — version bumps ship via Netlify on every push), cache-first for
   same-origin static assets, and hands-off for everything cross-origin
   (Supabase auth/realtime, Google Fonts). Bump VERSION with the client version
   so each deploy retires the previous cache. */
const VERSION = 'v23.38';
const CACHE = `cupseason-${VERSION}`;
const SHELL = [
  '/',
  '/manifest.webmanifest',
  '/icon-192.png',
  '/icon-512.png',
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
          const copy = res.clone();
          caches.open(CACHE).then((c) => c.put('/', copy));
          return res;
        })
        .catch(() => caches.match('/'))
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
