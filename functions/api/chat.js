/**
 * Room chat — improved for multi-user visibility
 * GET/POST /api/chat?room=
 */
const MAX = 120;
const TTL = 60 * 60 * 8;

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

  const url = new URL(request.url);
  let room = (url.searchParams.get('room') || 'lobby').replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 40) || 'lobby';

  try {
    if (request.method === 'GET') {
      const data = await readRoom(room);
      return new Response(JSON.stringify(data), { status: 200, headers });
    }
    if (request.method === 'POST') {
      const body = await request.json().catch(() => ({}));
      room = String(body.room || room).replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 40) || 'lobby';
      const name = String(body.name || 'Fan').slice(0, 24);
      const text = String(body.text || '').slice(0, 280);
      const type = String(body.type || 'chat').slice(0, 20);

      const data = await readRoom(room);
      data.messages = data.messages || [];
      data.viewers = data.viewers || [];

      // Update presence
      const now = Date.now();
      let viewer = data.viewers.find(v => v.name === name);
      if (!viewer) {
        viewer = { name, joined: now, last: now, online: true };
        data.viewers.push(viewer);
      } else {
        viewer.last = now;
        viewer.online = true;
      }
      // Mark others offline if inactive > 45s
      data.viewers.forEach(v => {
        if (v.name !== name && (now - (v.last || 0)) > 45000) v.online = false;
      });
      data.viewers = data.viewers.slice(-80);

      if (type === 'join' || type === 'view') {
        if (text) data.messages.push({ id: id(), name: 'System', text: name + ' joined the chat', type: 'system', t: now });
      } else if (type === 'leave') {
        viewer.online = false;
      } else if (text) {
        data.messages.push({ id: id(), name, text, type: 'chat', t: now });
      }
      data.messages = data.messages.slice(-MAX);
      await writeRoom(room, data);
      return new Response(JSON.stringify(data), { status: 200, headers });
    }
    return new Response(JSON.stringify({ message: 'Method not allowed' }), { status: 405, headers });
  } catch (e) {
    return new Response(JSON.stringify({ message: String(e.message || e), messages: [], viewers: [] }), { status: 200, headers });
  }
}

function id() {
  return Date.now() + '-' + Math.random().toString(36).slice(2, 8);
}

async function readRoom(room) {
  try {
    const cache = caches.default;
    const key = new Request('https://mcs-chat.internal/v3/room/' + room);
    const hit = await cache.match(key);
    if (hit) return await hit.json();
  } catch (e) {}
  return { messages: [], viewers: [] };
}

async function writeRoom(room, data) {
  try {
    const cache = caches.default;
    const key = new Request('https://mcs-chat.internal/v3/room/' + room);
    await cache.put(key, new Response(JSON.stringify(data), {
      headers: { 'Content-Type': 'application/json', 'Cache-Control': 'public, max-age=' + TTL }
    }));
  } catch (e) {}
}
