/**
 * Domestic matches published by the scoring app
 * GET  /api/domestic          -> list matches
 * POST /api/domestic          -> publish / update a match
 */
const TTL = 60 * 60 * 24 * 7; // 7 days

export async function onRequest(context) {
  const { request } = context;
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json',
    'Cache-Control': 'no-store'
  };
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers });

  try {
    if (request.method === 'GET') {
      const data = await readList();
      return new Response(JSON.stringify(data), { status: 200, headers });
    }
    if (request.method === 'POST') {
      const body = await request.json().catch(() => ({}));
      const id = String(body.id || ('d' + Date.now())).replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 40);
      const match = {
        id,
        name: String(body.name || 'Domestic Match').slice(0, 80),
        teamA: String(body.teamA || 'Team A').slice(0, 40),
        teamB: String(body.teamB || 'Team B').slice(0, 40),
        venue: String(body.venue || '').slice(0, 60),
        type: String(body.type || 'T20').slice(0, 20),
        when: body.when || new Date().toISOString(),
        status: String(body.status || 'upcoming').slice(0, 20),
        viewerUrl: body.viewerUrl || ('https://mysportzstats.being-innovator.workers.dev/?view=1&match=' + id)
      };
      const data = await readList();
      const idx = data.matches.findIndex(m => m.id === id);
      if (idx >= 0) data.matches[idx] = match;
      else data.matches.unshift(match);
      data.matches = data.matches.slice(0, 100);
      await writeList(data);
      return new Response(JSON.stringify(data), { status: 200, headers });
    }
    return new Response(JSON.stringify({ message: 'Method not allowed' }), { status: 405, headers });
  } catch (e) {
    return new Response(JSON.stringify({ message: String(e.message || e), matches: [] }), { status: 200, headers });
  }
}

async function readList() {
  try {
    const cache = caches.default;
    const key = new Request('https://mcs-domestic.internal/v1/list');
    const hit = await cache.match(key);
    if (hit) return await hit.json();
  } catch (e) {}
  return { matches: [] };
}

async function writeList(data) {
  try {
    const cache = caches.default;
    const key = new Request('https://mcs-domestic.internal/v1/list');
    await cache.put(key, new Response(JSON.stringify(data), {
      headers: { 'Content-Type': 'application/json', 'Cache-Control': 'public, max-age=' + TTL }
    }));
  } catch (e) {}
}
