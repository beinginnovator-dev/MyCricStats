// Cloudflare Pages Function: /api/*
// File path on Pages: functions/api/[[path]].js

export async function onRequest(context) {
  const { request } = context;
  const url = new URL(request.url);

  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: cors(request) });
  }

  // /api/football/... or /api/cricket/...
  const parts = url.pathname.replace(/^\/api\//, '').split('/');
  const kind = parts[0]; // football | cricket
  const rest = parts.slice(1).join('/');

  if (kind !== 'football' && kind !== 'cricket') {
    return new Response(JSON.stringify({ message: 'Use /api/football/... or /api/cricket/...' }), {
      status: 404,
      headers: { ...Object.fromEntries(cors(request)), 'Content-Type': 'application/json' }
    });
  }

  const base =
    kind === 'cricket'
      ? 'https://cricket.sportmonks.com/api/v2.0'
      : 'https://api.sportmonks.com/v3/football';

  const token =
    request.headers.get('X-Sportmonks-Token') ||
    url.searchParams.get('api_token') ||
    '';

  if (!token) {
    return new Response(JSON.stringify({ message: 'Missing token. Pass api_token query or X-Sportmonks-Token header.' }), {
      status: 401,
      headers: { ...Object.fromEntries(cors(request)), 'Content-Type': 'application/json' }
    });
  }

  const upstream = new URL(base + '/' + rest);
  url.searchParams.forEach((v, k) => {
    if (k !== 'api_token') upstream.searchParams.set(k, v);
  });
  upstream.searchParams.set('api_token', token);

  try {
    const res = await fetch(upstream.toString(), {
      headers: { Accept: 'application/json', 'User-Agent': 'MyCricStats-Pages/1.0' }
    });
    const text = await res.text();
    const h = cors(request);
    h.set('Content-Type', res.headers.get('Content-Type') || 'application/json');
    h.set('Cache-Control', 'public, max-age=15');
    return new Response(text, { status: res.status, headers: h });
  } catch (e) {
    const h = cors(request);
    h.set('Content-Type', 'application/json');
    return new Response(JSON.stringify({ message: 'Proxy error: ' + (e.message || String(e)) }), {
      status: 502,
      headers: h
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
