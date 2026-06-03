// PWA Service Worker - Offline First with Smart Strategies
const CACHE_VERSION = 'v5';
const STATIC_CACHE = `lingo-static-${CACHE_VERSION}`;
const DATA_CACHE = `lingo-data-${CACHE_VERSION}`;
const RUNTIME_CACHE = `lingo-runtime-${CACHE_VERSION}`;

const STATIC_URLS = [
  './',
  './index.html',
  './data-gen.html',
  './manifest.json',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/icon-1024.png',
  './icons/apple-touch-icon.png',
  './icons/favicon-32.png',
  './icons/favicon-16.png',
  './icons/favicon.ico',
];

// Data files use network-first (always try fresh, fallback to cache)
const DATA_URLS = [
  './phrases_ollama.json',
];

// Install: precache static assets
self.addEventListener('install', (e) => {
  e.waitUntil(
    Promise.all([
      caches.open(STATIC_CACHE).then((cache) => cache.addAll(STATIC_URLS)),
      caches.open(DATA_CACHE).then((cache) =>
        Promise.all(
          DATA_URLS.map((u) =>
            fetch(u).then((r) => r.ok && cache.put(u, r.clone())).catch(() => {})
          )
        )
      ),
    ]).catch((err) => console.warn('[SW] Install failed:', err))
  );
  self.skipWaiting();
});

// Activate: clean old caches
self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((names) =>
      Promise.all(
        names
          .filter((n) => ![STATIC_CACHE, DATA_CACHE, RUNTIME_CACHE].includes(n))
          .map((n) => caches.delete(n))
      )
    )
  );
  self.clients.claim();
});

// Helper: determine cache strategy by URL
function getCacheStrategy(url) {
  // Data: network-first (always fetch fresh, cache as fallback)
  if (DATA_URLS.some((u) => url.endsWith(u.replace('./', '/')))) {
    return 'network-first';
  }
  // HTML: stale-while-revalidate (fast load, update in background)
  if (url.endsWith('.html') || url.endsWith('/')) {
    return 'stale-while-revalidate';
  }
  // Static assets: cache-first
  if (url.includes('/icons/') || url.includes('.png') || url.includes('.svg') || url.includes('manifest.json')) {
    return 'cache-first';
  }
  // Default: stale-while-revalidate
  return 'stale-while-revalidate';
}

// Fetch: smart routing
self.addEventListener('fetch', (e) => {
  const { request } = e;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return; // skip external

  const strategy = getCacheStrategy(url.pathname);

  if (strategy === 'network-first') {
    e.respondWith(
      fetch(request)
        .then((res) => {
          if (res && res.ok) {
            const clone = res.clone();
            caches.open(DATA_CACHE).then((cache) => cache.put(request, clone));
          }
          return res;
        })
        .catch(() => caches.match(request))
    );
    return;
  }

  if (strategy === 'cache-first') {
    e.respondWith(
      caches.match(request).then((cached) => {
        if (cached) return cached;
        return fetch(request).then((res) => {
          if (res && res.ok) {
            const clone = res.clone();
            caches.open(STATIC_CACHE).then((cache) => cache.put(request, clone));
          }
          return res;
        }).catch(() => caches.match('./index.html')); // offline fallback
      })
    );
    return;
  }

  // stale-while-revalidate (default)
  e.respondWith(
    caches.match(request).then((cached) => {
      const fetchPromise = fetch(request).then((res) => {
        if (res && res.ok) {
          const clone = res.clone();
          caches.open(STATIC_CACHE).then((cache) => cache.put(request, clone));
        }
        return res;
      }).catch(() => cached);
      return cached || fetchPromise;
    })
  );
});

// Listen for messages from app (skip waiting, clear cache, etc.)
self.addEventListener('message', (e) => {
  if (e.data && e.data.type === 'SKIP_WAITING') self.skipWaiting();
  if (e.data && e.data.type === 'CLEAR_CACHE') {
    caches.keys().then((names) => Promise.all(names.map((n) => caches.delete(n))));
  }
});
