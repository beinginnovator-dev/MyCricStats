/**
 * Persistent MyCricStats room chat backed by Cloudflare D1.
 * Required binding: MCS_DB
 * POST actions: heartbeat, send, edit, delete, moderate
 * Moderation actions: remove, block, unblock
 */
const MAX_MESSAGES = 200;
const clean = (v, max = 80) => String(v || '').replace(/[\u0000-\u001f]/g, '').trim().slice(0, max);
const json = (body, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store, no-cache, must-revalidate' }
});

async function sha256(value) {
  const bytes = new TextEncoder().encode(String(value));
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  return Array.from(new Uint8Array(digest)).map(x => x.toString(16).padStart(2, '0')).join('');
}

async function logActivity(db, room, memberId, name, event, detail, now) {
  try {
    await db.prepare('INSERT INTO mcs_activity (id, room_id, member_id, name, event, detail, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)')
      .bind(crypto.randomUUID(), room, memberId, name, event, detail, now).run();
  } catch (error) {
    // Keep chat working if an older deployment has not applied migration 0002 yet.
    if (!String(error && error.message || error).toLowerCase().includes('no such table')) throw error;
  }
}

async function roomData(db, room, memberId, isHost) {
  const [messages, viewers] = await Promise.all([
    db.prepare('SELECT id, member_id AS memberId, name, text, type, created_at AS t, edited FROM mcs_messages WHERE room_id = ? ORDER BY created_at DESC LIMIT ?').bind(room, MAX_MESSAGES).all(),
    db.prepare('SELECT member_id AS memberId, name, role, last_seen AS last, blocked, removed FROM mcs_members WHERE room_id = ? AND removed = 0 ORDER BY joined_at ASC').bind(room).all()
  ]);
  let activity = { results: [] };
  try { activity = await db.prepare('SELECT id, member_id AS memberId, name, event, detail, created_at AS createdAt FROM mcs_activity WHERE room_id = ? ORDER BY created_at DESC LIMIT 80').bind(room).all(); }
  catch (error) { if (!String(error && error.message || error).toLowerCase().includes('no such table')) throw error; }
  const now = Date.now();
  const list = (viewers.results || []).map(v => ({
    ...v, online: now - Number(v.last || 0) < 45000,
    blocked: !!v.blocked, removed: !!v.removed
  }));
  return {
    messages: (messages.results || []).reverse().map(m => ({ ...m, edited: !!m.edited })),
    viewers: list,
    activity: isHost ? (activity.results || []) : [],
    isHost: !!isHost, memberId, message: 'Connected'
  };
}

export async function onRequest({ request, env }) {
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: {
    'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type'
  }});
  const db = env && env.MCS_DB;
  if (!db) return json({ message: 'Chat database is not connected. Add the Cloudflare D1 binding named MCS_DB.' }, 503);
  const url = new URL(request.url);
  if (request.method === 'GET') {
    const room = clean(url.searchParams.get('room') || 'lobby', 40);
    try {
      const messages = await db.prepare('SELECT id, member_id AS memberId, name, text, type, created_at AS t, edited FROM mcs_messages WHERE room_id = ? ORDER BY created_at DESC LIMIT ?').bind(room, MAX_MESSAGES).all();
      const viewers = await db.prepare('SELECT member_id AS memberId, name, role, last_seen AS last, blocked, removed FROM mcs_members WHERE room_id = ? AND removed = 0 ORDER BY joined_at ASC').bind(room).all();
      const now = Date.now();
      return json({ messages: (messages.results || []).reverse(), viewers: (viewers.results || []).map(v => ({...v, online: now - Number(v.last || 0) < 45000, blocked: !!v.blocked})) });
    } catch (e) { return json({ message: String(e.message || e) }, 500); }
  }
  if (request.method !== 'POST') return json({ message: 'Method not allowed' }, 405);

  try {
    const body = await request.json();
    const room = clean(body.room, 40);
    const memberId = clean(body.memberId, 100);
    const name = clean(body.name || 'Fan', 24) || 'Fan';
    const action = clean(body.action || 'heartbeat', 20);
    const ownerToken = clean(body.ownerToken, 160);
    if (!room || !memberId) return json({ message: 'Room and member identity are required.' }, 400);

    let roomRow = await db.prepare('SELECT room_id, owner_hash FROM mcs_rooms WHERE room_id = ?').bind(room).first();
    if (!roomRow && ownerToken) {
      const hash = await sha256(ownerToken);
      await db.prepare('INSERT OR IGNORE INTO mcs_rooms (room_id, owner_hash, created_at) VALUES (?, ?, ?)').bind(room, hash, Date.now()).run();
      roomRow = await db.prepare('SELECT room_id, owner_hash FROM mcs_rooms WHERE room_id = ?').bind(room).first();
    }
    if (!roomRow) return json({ message: 'This match room has not been created by its host yet.' }, 404);
    const isHost = !!(ownerToken && await sha256(ownerToken) === roomRow.owner_hash);

    const existing = await db.prepare('SELECT blocked, removed, last_seen FROM mcs_members WHERE room_id = ? AND member_id = ?').bind(room, memberId).first();
    if (existing && (existing.blocked || existing.removed) && !isHost) {
      return json({ message: existing.blocked ? 'You are blocked from this room.' : 'You were removed from this room.' }, 403);
    }
    const now = Date.now();
    if (action === 'leave') {
      if (existing) {
        await db.prepare('UPDATE mcs_members SET last_seen = ? WHERE room_id = ? AND member_id = ?').bind(now - 60000, room, memberId).run();
        await logActivity(db, room, memberId, name, 'leave', 'Viewer left the match room', now);
      }
      return json(await roomData(db, room, memberId, isHost));
    }

    const isNewSession = !existing || (now - Number(existing.last_seen || 0) > 45000);
    await db.prepare(`INSERT INTO mcs_members (room_id, member_id, name, role, joined_at, last_seen, blocked, removed)
      VALUES (?, ?, ?, ?, ?, ?, 0, 0)
      ON CONFLICT(room_id, member_id) DO UPDATE SET name=excluded.name, role=excluded.role, last_seen=excluded.last_seen`)
      .bind(room, memberId, name, isHost ? 'host' : 'member', now, now).run();

    if (action === 'join' && isNewSession) {
      await logActivity(db, room, memberId, name, 'join', 'Viewer joined the match room', now);
    }

    if (action === 'send') {
      const text = clean(body.text, 500);
      if (!text) return json({ message: 'Message is empty.' }, 400);
      const id = crypto.randomUUID ? crypto.randomUUID() : `${now}-${Math.random().toString(36).slice(2)}`;
      const type = clean(body.type || 'chat', 20);
      await db.prepare('INSERT INTO mcs_messages (id, room_id, member_id, name, text, type, created_at, edited) VALUES (?, ?, ?, ?, ?, ?, ?, 0)')
        .bind(id, room, memberId, name, text, type, now).run();
      await logActivity(db, room, memberId, name, 'message', type === 'emoji' ? 'Sent a reaction' : 'Sent a chat message', now);
    } else if (action === 'edit' || action === 'delete') {
      const id = clean(body.id, 100);
      if (!id) return json({ message: 'Message id is required.' }, 400);
      const msg = await db.prepare('SELECT member_id FROM mcs_messages WHERE id = ? AND room_id = ?').bind(id, room).first();
      if (!msg) return json({ message: 'Message not found.' }, 404);
      if (!isHost && msg.member_id !== memberId) return json({ message: 'You can only edit or delete your own messages.' }, 403);
      if (action === 'delete') await db.prepare('DELETE FROM mcs_messages WHERE id = ? AND room_id = ?').bind(id, room).run();
      else {
        const text = clean(body.text, 500);
        if (!text) return json({ message: 'Edited message cannot be empty.' }, 400);
        await db.prepare('UPDATE mcs_messages SET text = ?, edited = 1 WHERE id = ? AND room_id = ?').bind(text, id, room).run();
      }
    } else if (action === 'moderate') {
      if (!isHost) return json({ message: 'Only the room host can manage members.' }, 403);
      const target = clean(body.targetMemberId, 100);
      const moderation = clean(body.moderation, 20);
      if (!target || target === memberId) return json({ message: 'Choose another room member.' }, 400);
      if (moderation === 'remove') {
        await db.prepare('UPDATE mcs_members SET removed = 1, last_seen = ? WHERE room_id = ? AND member_id = ?').bind(now, room, target).run();
      } else if (moderation === 'block') {
        await db.prepare('UPDATE mcs_members SET blocked = 1, last_seen = ? WHERE room_id = ? AND member_id = ?').bind(now, room, target).run();
      } else if (moderation === 'unblock') {
        await db.prepare('UPDATE mcs_members SET blocked = 0, removed = 0, last_seen = ? WHERE room_id = ? AND member_id = ?').bind(now, room, target).run();
      } else return json({ message: 'Unknown moderation action.' }, 400);
      const targetRow = await db.prepare('SELECT name FROM mcs_members WHERE room_id = ? AND member_id = ?').bind(room, target).first();
      await logActivity(db, room, target, targetRow?.name || 'Member', moderation, `Host ${moderation} member`, now);
    }

    // Bound room history and keep one live membership row per device/user.
    await db.prepare(`DELETE FROM mcs_messages WHERE room_id = ? AND id NOT IN
      (SELECT id FROM mcs_messages WHERE room_id = ? ORDER BY created_at DESC LIMIT ?)`)
      .bind(room, room, MAX_MESSAGES).run();
    return json(await roomData(db, room, memberId, isHost));
  } catch (e) {
    return json({ message: String(e.message || e) }, 500);
  }
}
