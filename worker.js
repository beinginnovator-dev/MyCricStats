/**
 * Cloudflare Worker: serves PWA + proxies Sportmonks (fixes CORS)
 * Routes:
 *   /api/football/*  -> api.sportmonks.com/v3/football/*
 *   /api/cricket/*   -> cricket.sportmonks.com/api/v2.0/*
 * Token: query api_token OR header X-Sportmonks-Token
 */
const FB = 'https://api.sportmonks.com/v3/football';
const CK = 'https://cricket.sportmonks.com/api/v2.0';

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // --- API proxy ---
    if (url.pathname.startsWith('/api/football/') || url.pathname.startsWith('/api/cricket/')) {
      return proxySportmonks(request, url);
    }

    // --- Static assets from env.ASSETS (Pages) or embedded ---
    if (env.ASSETS) {
      return env.ASSETS.fetch(request);
    }

    // Fallback HTML message if no assets binding
    return new Response(
      '<!DOCTYPE html><html><body style="font-family:sans-serif;padding:2rem"><h1>Deploy with static assets</h1><p>Use Cloudflare Pages with this worker as functions, or bind ASSETS.</p></body></html>',
      { headers: { 'content-type': 'text/html;charset=utf-8' } }
    );
  }
};

async function proxySportmonks(request, url) {
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders(request) });
  }

  const isCricket = url.pathname.startsWith('/api/cricket/');
  const base = isCricket ? CK : FB;
  const rest = url.pathname.replace(isCricket ? '/api/cricket/' : '/api/football/', '');

  // Token from query or header (prefer header so token is not logged in referrers as much)
  const token =
    request.headers.get('X-Sportmonks-Token') ||
    url.searchParams.get('api_token') ||
    '';

  if (!token) {
    return json({ message: 'Missing api_token or X-Sportmonks-Token header' }, 401, request);
  }

  const upstream = new URL(base + '/' + rest.replace(/^\//, ''));
  // Copy query except we force api_token
  url.searchParams.forEach((v, k) => {
    if (k !== 'api_token') upstream.searchParams.set(k, v);
  });
  upstream.searchParams.set('api_token', token);

  try {
    const res = await fetch(upstream.toString(), {
      method: 'GET',
      headers: {
        Accept: 'application/json',
        'User-Agent': 'MyCricStats-Worker/1.0'
      }
    });
    const body = await res.text();
    const headers = corsHeaders(request);
    headers.set('Content-Type', res.headers.get('Content-Type') || 'application/json');
    headers.set('Cache-Control', 'public, max-age=15');
    return new Response(body, { status: res.status, headers });
  } catch (e) {
    return json({ message: 'Upstream fetch failed: ' + (e.message || String(e)) }, 502, request);
  }
}

function corsHeaders(request) {
  const origin = request.headers.get('Origin') || '*';
  return new Headers({
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, X-Sportmonks-Token',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin'
  });
}

function json(obj, status, request) {
  const headers = corsHeaders(request);
  headers.set('Content-Type', 'application/json');
  return new Response(JSON.stringify(obj), { status, headers });
}
