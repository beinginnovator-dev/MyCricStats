/**
 * Cloudflare Pages Function — GET /api/proxy
 * Query: sport=football|cricket, path=livescores/inplay, api_token=..., include=...
 */
export async function onRequest(context) {
  const { request } = context;
  const url = new URL(request.url);
  const headers = cors(request);

  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers });
  }
  if (request.method !== 'GET') {
    return json({ message: 'GET only' }, 405, headers);
  }

  const sport = (url.searchParams.get('sport') || 'football').toLowerCase();
  const path = (url.searchParams.get('path') || '').replace(/^\/+/, '');
  const token = request.headers.get('X-Sportmonks-Token') || url.searchParams.get('api_token') || '';

  if (!path) return json({ message: 'Missing path' }, 400, headers);
  if (!token) return json({ message: 'Missing api_token' }, 401, headers);

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
      headers: { Accept: 'application/json', 'User-Agent': 'MyCricStats-Pages/4.0' }
    });
    const text = await res.text();
    headers.set('Content-Type', res.headers.get('Content-Type') || 'application/json');
    headers.set('Cache-Control', 'public, max-age=10');
    return new Response(text, { status: res.status, headers });
  } catch (e) {
    return json({ message: 'Upstream: ' + (e.message || String(e)) }, 502, headers);
  }
}

function cors(request) {
  return new Headers({
    'Access-Control-Allow-Origin': request.headers.get('Origin') || '*',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, X-Sportmonks-Token',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin'
  });
}
function json(obj, status, headers) {
  headers.set('Content-Type', 'application/json');
  return new Response(JSON.stringify(obj), { status, headers });
}
