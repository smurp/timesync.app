// TimeSync PWA Service Worker with Smart Update Strategy
const CACHE_VERSION = '0.6.0';
const CACHE_NAME = `timesync-v${CACHE_VERSION}`;

const urlsToCache = [
  '/',
  '/index.html',
  '/manifest.json',
  '/img/icon-72x72.png',
  '/img/icon-96x96.png',
  '/img/icon-128x128.png',
  '/img/icon-144x144.png',
  '/img/icon-152x152.png',
  '/img/icon-192x192.png',
  '/img/icon-384x384.png',
  '/img/icon-512x512.png'
];

// Install event - cache resources
self.addEventListener('install', (event) => {
  console.log(`Service Worker v${CACHE_VERSION}: Install event`);
  
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log(`Service Worker v${CACHE_VERSION}: Caching files`);
        return cache.addAll(urlsToCache);
      })
      .then(() => {
        console.log(`Service Worker v${CACHE_VERSION}: All files cached`);
        // Force the new service worker to take control immediately
        return self.skipWaiting();
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log(`Service Worker v${CACHE_VERSION}: Activate event`);
  
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME && cacheName.startsWith('timesync-')) {
            console.log(`Service Worker v${CACHE_VERSION}: Deleting old cache:`, cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      console.log(`Service Worker v${CACHE_VERSION}: Claiming clients`);
      // Take control of all open tabs immediately
      return self.clients.claim();
    }).then(() => {
      // Notify all clients that a new version is ready
      // Include uncontrolled clients to ensure all tabs get the message
      return self.clients.matchAll({ includeUncontrolled: true }).then(clients => {
        console.log(`Service Worker v${CACHE_VERSION}: Notifying ${clients.length} clients`);
        clients.forEach(client => {
          client.postMessage({
            type: 'SERVICE_WORKER_UPDATED',
            version: CACHE_VERSION
          });
        });
      });
    })
  );
});

// Fetch event - network-first for HTML, cache-first for assets
self.addEventListener('fetch', (event) => {
  const { request } = event;
  
  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }

  // Skip external requests
  if (!request.url.startsWith(self.location.origin)) {
    return;
  }

  // Parse URL to determine strategy
  const url = new URL(request.url);
  
  // Network-first strategy for HTML, manifest, and service worker
  if (request.mode === 'navigate' || 
      url.pathname === '/' || 
      url.pathname === '/index.html' ||
      url.pathname === '/manifest.json' ||
      url.pathname === '/sw.js' ||
      (request.headers.get('accept') && request.headers.get('accept').includes('text/html'))) {
    
    event.respondWith(
      fetch(request)
        .then((response) => {
          // Update cache with fresh response
          if (response && response.status === 200 && response.type === 'basic') {
            const responseToCache = response.clone();
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(request, responseToCache);
            });
          }
          return response;
        })
        .catch(() => {
          // Fallback to cache if network fails (offline mode)
          return caches.match(request).then((response) => {
            if (response) {
              console.log(`Service Worker v${CACHE_VERSION}: Serving from cache (offline):`, request.url);
              return response;
            }
            
            // Return custom offline page for navigation requests
            if (request.mode === 'navigate' || 
                (request.headers.get('accept') && request.headers.get('accept').includes('text/html'))) {
              return new Response(`
                <!DOCTYPE html>
                <html lang="en">
                <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <title>TimeSync - Offline</title>
                  <style>
                    body {
                      background: #000033;
                      color: white;
                      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                      display: flex;
                      justify-content: center;
                      align-items: center;
                      height: 100vh;
                      margin: 0;
                      text-align: center;
                    }
                    .offline-message {
                      padding: 20px;
                    }
                    h1 { 
                      color: #ff5555;
                      margin-bottom: 20px;
                    }
                    p { 
                      color: #87ceeb;
                      margin: 10px 0;
                    }
                    .clock {
                      font-family: 'Courier New', monospace;
                      font-size: 1.5rem;
                      margin-top: 20px;
                      color: #ffffff;
                    }
                  </style>
                </head>
                <body>
                  <div class="offline-message">
                    <h1>⏰ TimeSync</h1>
                    <p>You're currently offline</p>
                    <p>The app will work again when you reconnect</p>
                    <div class="clock" id="offline-clock"></div>
                  </div>
                  <script>
                    function updateClock() {
                      const now = new Date();
                      const time = now.toISOString().slice(11, 19) + 'Z';
                      document.getElementById('offline-clock').textContent = time;
                    }
                    updateClock();
                    setInterval(updateClock, 1000);
                  </script>
                </body>
                </html>
              `, {
                status: 503,
                statusText: 'Service Unavailable',
                headers: new Headers({
                  'Content-Type': 'text/html; charset=utf-8'
                })
              });
            }
            
            // Generic offline response for other requests
            return new Response('Offline - Please check your connection', {
              status: 503,
              statusText: 'Service Unavailable',
              headers: new Headers({
                'Content-Type': 'text/plain'
              })
            });
          });
        })
    );
    return;
  }

  // Cache-first strategy for static assets (images, etc.)
  event.respondWith(
    caches.match(request)
      .then((response) => {
        if (response) {
          // Return cached version for static assets
          return response;
        }

        // Fetch from network if not in cache
        return fetch(request).then((response) => {
          // Don't cache if not successful
          if (!response || response.status !== 200 || response.type !== 'basic') {
            return response;
          }

          // Clone and cache the response
          const responseToCache = response.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(request, responseToCache);
          });

          return response;
        });
      })
      .catch((error) => {
        console.log(`Service Worker v${CACHE_VERSION}: Fetch failed:`, error);
        throw error;
      })
  );
});

// Handle messages from clients
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'CHECK_UPDATE') {
    console.log(`Service Worker v${CACHE_VERSION}: Manual update check requested`);
    self.registration.update();
  }
  
  if (event.data && event.data.type === 'GET_VERSION') {
    // Send version back through message channel
    if (event.ports && event.ports[0]) {
      event.ports[0].postMessage({ version: CACHE_VERSION });
    }
  }
  
  // Request version message - useful for newly loaded pages
  if (event.data && event.data.type === 'REQUEST_VERSION') {
    if (event.source) {
      event.source.postMessage({
        type: 'SERVICE_WORKER_UPDATED',
        version: CACHE_VERSION
      });
    }
  }
});

// Handle background sync for offline functionality
self.addEventListener('sync', (event) => {
  console.log(`Service Worker v${CACHE_VERSION}: Background sync:`, event.tag);
  
  if (event.tag === 'timesync-data') {
    event.waitUntil(
      // Could implement syncing of stored time logs here in the future
      console.log(`Service Worker v${CACHE_VERSION}: Processing background sync`)
    );
  }
});

// Handle push notifications (if you want to add them later)
self.addEventListener('push', (event) => {
  console.log(`Service Worker v${CACHE_VERSION}: Push received`);
  
  const options = {
    body: event.data ? event.data.text() : 'TimeSync notification',
    icon: '/img/icon-192x192.png',
    badge: '/img/icon-72x72.png',
    vibrate: [200, 100, 200],
    data: {
      url: '/'
    }
  };

  event.waitUntil(
    self.registration.showNotification('TimeSync', options)
  );
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log(`Service Worker v${CACHE_VERSION}: Notification clicked`);
  
  event.notification.close();
  
  event.waitUntil(
    clients.openWindow(event.notification.data.url || '/')
  );
});

// Log when service worker is ready
console.log(`Service Worker v${CACHE_VERSION}: Script loaded`);