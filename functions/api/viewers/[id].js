const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
  "Cache-Control": "no-store"
};

export async function onRequest({ request, env, params }) {
  const matchId = String(params.id || "").replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 80);
  if (!matchId) return new Response("Missing match id", { status: 400, headers: cors });
  if (request.method === "OPTIONS") return new Response(null, { headers: cors });
  if (!env.LIVE_DB) return Response.json({ error: "Live database is not configured" }, { status: 503, headers: cors });

  const now = new Date();
  const cutoff = new Date(now.getTime() - 45000).toISOString();

  if (request.method === "POST") {
    let body;
    try {
      const raw = await request.text();
      if (raw.length > 2048) return new Response("Payload too large", { status: 413, headers: cors });
      body = JSON.parse(raw);
    } catch {
      return new Response("Invalid JSON", { status: 400, headers: cors });
    }
    const viewerId = String(body.viewerId || "").replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 100);
    if (!viewerId) return new Response("Missing viewer id", { status: 400, headers: cors });
    await env.LIVE_DB.prepare(
      "INSERT INTO viewer_presence (match_id, viewer_id, last_seen) VALUES (?, ?, ?) ON CONFLICT(match_id, viewer_id) DO UPDATE SET last_seen=excluded.last_seen"
    ).bind(matchId, viewerId, now.toISOString()).run();
  } else if (request.method !== "GET") {
    return new Response("Method not allowed", { status: 405, headers: cors });
  }

  await env.LIVE_DB.prepare("DELETE FROM viewer_presence WHERE match_id = ? AND last_seen < ?").bind(matchId, cutoff).run();
  const row = await env.LIVE_DB.prepare(
    "SELECT COUNT(*) AS count FROM viewer_presence WHERE match_id = ? AND last_seen >= ?"
  ).bind(matchId, cutoff).first();
  return Response.json({ matchId, count: Number(row?.count || 0), updatedAt: now.toISOString() }, { headers: cors });
}
