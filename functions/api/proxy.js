/**
 * Cloudflare Pages Function — GET /api/proxy
 * Query:
 *   sport=football|cricket  (default football)
 *   path=livescores/inplay  (required)
 *   api_token=...           (or header X-Sportmonks-Token)
 *   include=participants;scores;state
 *   (any other query params are forwarded)
 */
export async function onRequest(context) {
  const { request } = context;
  const url = new URL(request.url);

  const headers = cors(request);

  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers });
  }

  if (request.method !== 'GET') {
    return new Response(JSON.stringify({ message: 'GET only' }), {
      status: 405,
      headers: withJson(headers)
    });
  }

  const sport = (url.searchParams.get('sport') || 'football').toLowerCase();
  const path = (url.searchParams.get('path') || '').replace(/^\/+/, '');
  const token =
    request.headers.get('X-Sportmonks-Token') ||
    url.searchParams.get('api_token') ||
    '';

  if (!path) {
    return new Response(
      JSON.stringify({
        message: 'Missing path. Example: /api/proxy?sport=football&path=livescores/inplay&api_token=TOKEN&include=participants;scores;state'
      }),
      { status: 400, headers: withJson(headers) }
    );
  }

  if (!token) {
    return new Response(JSON.stringify({ message: 'Missing api_token (query) or X-Sportmonks-Token header' }), {
      status: 401,
      headers: withJson(headers)
    });
  }

  const base =
    sport === 'cricket'
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
      headers: {
        Accept: 'application/json',
        'User-Agent': 'MyCricStats-Proxy/1.1'
      }
    });
    const text = await res.text();
    headers.set('Content-Type', res.headers.get('Content-Type') || 'application/json; charset=utf-8');
    headers.set('Cache-Control', 'public, max-age=10');
    return new Response(text, { status: res.status, headers });
  } catch (e) {
    return new Response(JSON.stringify({ message: 'Upstream error: ' + (e.message || String(e)) }), {
      status: 502,
      headers: withJson(headers)
    });
  }
}

function cors(request) {
  const origin = request.headers.get('Origin') || '*';
  return new Headers({
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, X-Sportmonks-Token',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin'
  });
}

function withJson(h) {
  h.set('Content-Type', 'application/json; charset=utf-8');
  return h;
}
