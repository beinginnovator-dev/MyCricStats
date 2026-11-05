/**
 * Sportmonks proxy — CORS + optional server token for guests
 * Client: /api/proxy?sport=cricket&path=livescores&api_token=...
 * Guests (view=1): if no api_token, uses env.SPORTMONKS_TOKEN when set in Cloudflare
 */
export async function onRequest(context) {
  const { request, env } = context;
  const headers = new Headers({
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json',
    'Cache-Control': 'no-store, no-cache, must-revalidate'
  });
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers });

  try {
    const url = new URL(request.url);
    const sport = (url.searchParams.get('sport') || 'cricket').toLowerCase();
    const path = (url.searchParams.get('path') || '').replace(/^\/+/, '');
    let token = url.searchParams.get('api_token') || url.searchParams.get('token') || '';
    const guest = url.searchParams.get('guest') === '1' || url.searchParams.get('view') === '1';

    // Server token for shared/view-only users (set in Pages → Settings → Environment variables)
    if (!token && guest && env && env.SPORTMONKS_TOKEN) {
      token = env.SPORTMONKS_TOKEN;
    }
    if (!token && env && env.SPORTMONKS_TOKEN && !url.searchParams.get('api_token')) {
      // allow bare guest fetch when only server token exists
      if (guest) token = env.SPORTMONKS_TOKEN;
    }

    if (!path) {
      return new Response(JSON.stringify({ message: 'Missing path' }), { status: 400, headers });
    }
    if (!token) {
      return new Response(JSON.stringify({
        message: guest
          ? 'Host must set SPORTMONKS_TOKEN in Cloudflare Pages env, or guest needs own free token'
          : 'Missing api_token'
      }), { status: 401, headers });
    }

    const base = sport === 'football'
      ? 'https://soccer.sportmonks.com/api/v2.0/'
      : 'https://cricket.sportmonks.com/api/v2.0/';

    const dest = new URL(base + path);
    dest.searchParams.set('api_token', token);
    url.searchParams.forEach((v, k) => {
      if (['sport', 'path', 'api_token', 'token', 'guest', 'view'].includes(k)) return;
      dest.searchParams.set(k, v);
    });

    // Short Cloudflare edge cache coalesces repeated requests from viewers.
    // Keep cache keys token-specific so different subscriptions never share data.
    let cache = null;
    let cacheKey = null;
    let cacheTtl = 0;
    try {
      cache = caches.default;
      const requestPath = path.toLowerCase();
      cacheTtl = requestPath === 'livescores' ? 10
        : (requestPath.startsWith('fixtures/') ? 6
        : (requestPath === 'fixtures' ? 12 : 0));
      if (cache && cacheTtl > 0) {
        const keyUrl = new URL(request.url);
        keyUrl.pathname = '/__mcs_edge_cache/sportmonks';
        keyUrl.search = '';
        keyUrl.searchParams.set('request', dest.toString());
        cacheKey = new Request(keyUrl.toString(), { method: 'GET' });
        const hit = await cache.match(cacheKey);
        if (hit) {
          const hitHeaders = new Headers(headers);
          hitHeaders.set('Content-Type', hit.headers.get('Content-Type') || 'application/json');
          hitHeaders.set('X-MCS-Edge-Cache', 'HIT');
          return new Response(hit.body, { status: hit.status, headers: hitHeaders });
        }
      }
    } catch (_) {
      cache = null;
      cacheKey = null;
    }

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 12000);
    let res;
    try {
      res = await fetch(dest.toString(), {
        headers: { Accept: 'application/json', 'User-Agent': 'MyCricStats/1.0' },
        signal: controller.signal
      });
    } catch (err) {
      if (err && err.name === 'AbortError') {
        return new Response(JSON.stringify({ message: 'Sportmonks upstream timed out after 12 seconds' }), {
          status: 504, headers
        });
      }
      throw err;
    } finally {
      clearTimeout(timer);
    }
    const text = await res.text();
    const contentType = res.headers.get('Content-Type') || 'application/json';
    if (res.ok && cache && cacheKey && cacheTtl > 0) {
      try {
        const storedHeaders = new Headers({ 'Content-Type': contentType, 'Cache-Control': 'public, max-age=' + cacheTtl });
        await cache.put(cacheKey, new Response(text, { status: res.status, headers: storedHeaders }));
      } catch (_) {}
    }
    const outHeaders = new Headers(headers);
    outHeaders.set('Content-Type', contentType);
    outHeaders.set('X-MCS-Edge-Cache', 'MISS');
    return new Response(text, { status: res.status, headers: outHeaders });
  } catch (e) {
    return new Response(JSON.stringify({ message: String(e.message || e) }), { status: 502, headers });
  }
}
