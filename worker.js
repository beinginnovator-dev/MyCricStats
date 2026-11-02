/**
 * Full Worker for workers.dev: static HTML + /api/proxy
 * Deploy: wrangler deploy  OR paste in CF dashboard as Worker module
 * Bind nothing required if HTML is inlined below — for production use Pages.
 */
const INDEX_HTML = `PLACEHOLDER`;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/api/proxy' || url.pathname.startsWith('/api/proxy')) {
      return handleProxy(request, url);
    }

    // Serve SPA assets from ASSETS binding if present
    if (env && env.ASSETS) {
      return env.ASSETS.fetch(request);
    }

    if (url.pathname === '/' || url.pathname === '/index.html') {
      return new Response(INDEX_HTML, {
        headers: { 'Content-Type': 'text/html;charset=utf-8', 'Cache-Control': 'no-cache' }
      });
    }

    if (url.pathname === '/manifest.webmanifest') {
      return new Response(JSON.stringify({
        name: 'MyCricStats', short_name: 'MyCricStats', start_url: '/', display: 'standalone',
        background_color: '#0b1220', theme_color: '#0b1220',
        icons: [{ src: '/icons/icon-192.png', sizes: '192x192', type: 'image/png' }]
      }), { headers: { 'Content-Type': 'application/manifest+json' } });
    }

    return new Response('Not found: ' + url.pathname + ' — use Pages deploy with public/ + functions/', {
      status: 404,
      headers: { 'Content-Type': 'text/plain' }
    });
  }
};

async function handleProxy(request, url) {
  const h = cors(request);
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: h });

  const sport = (url.searchParams.get('sport') || 'football').toLowerCase();
  const path = (url.searchParams.get('path') || '').replace(/^\/+/, '');
  const token = request.headers.get('X-Sportmonks-Token') || url.searchParams.get('api_token') || '';

  if (!path) {
    h.set('Content-Type', 'application/json');
    return new Response(JSON.stringify({ message: 'Missing path' }), { status: 400, headers: h });
  }
  if (!token) {
    h.set('Content-Type', 'application/json');
    return new Response(JSON.stringify({ message: 'Missing api_token' }), { status: 401, headers: h });
  }

  const base = sport === 'cricket'
    ? 'https://cricket.sportmonks.com/api/v2.0'
    : 'https://api.sportmonks.com/v3/football';
  const upstream = new URL(base + '/' + path);
  url.searchParams.forEach((v, k) => {
    if (k === 'sport' || k === 'path' || k === 'api_token') return;
    upstream.searchParams.set(k, v);
  });
  upstream.searchParams.set('api_token', token);

  try {
    const res = await fetch(upstream.toString(), {
      headers: { Accept: 'application/json', 'User-Agent': 'MyCricStats-Worker/1.1' }
    });
    const text = await res.text();
    h.set('Content-Type', res.headers.get('Content-Type') || 'application/json');
    return new Response(text, { status: res.status, headers: h });
  } catch (e) {
    h.set('Content-Type', 'application/json');
    return new Response(JSON.stringify({ message: String(e.message || e) }), { status: 502, headers: h });
  }
}

function cors(request) {
  return new Headers({
    'Access-Control-Allow-Origin': request.headers.get('Origin') || '*',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, X-Sportmonks-Token',
    Vary: 'Origin'
  });
}
