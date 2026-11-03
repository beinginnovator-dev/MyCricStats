const CACHE='mcs-v6';
const ASSETS=['/','/index.html','/manifest.webmanifest','/icons/icon-192.png','/icons/icon-512.png'];
self.addEventListener('install',e=>{e.waitUntil(caches.open(CACHE).then(c=>c.addAll(ASSETS)).then(()=>self.skipWaiting()));});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim()));});
self.addEventListener('fetch',e=>{
  const u=new URL(e.request.url);
  if(u.pathname.startsWith('/api/')) return;
  if(e.request.method!=='GET') return;
  e.respondWith(fetch(e.request).then(res=>{const c=res.clone();caches.open(CACHE).then(cache=>cache.put(e.request,c));return res;}).catch(()=>caches.match(e.request).then(r=>r||caches.match('/index.html'))));
});
