const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, PUT, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
  "Cache-Control": "no-store"
};

export async function onRequest({ request, env, params }) {
  const id = String(params.id || "").replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 80);
  if (!id) return new Response("Missing match id", { status: 400, headers: cors });
  if (request.method === "OPTIONS") return new Response(null, { headers: cors });
  if (!env.LIVE_DB) return Response.json({ error: "Live database is not configured" }, { status: 503, headers: cors });

  if (request.method === "GET") {
    const row = await env.LIVE_DB.prepare("SELECT payload, updated_at FROM live_matches WHERE match_id = ?").bind(id).first();
    if (!row) return Response.json({ error: "Live match not found" }, { status: 404, headers: cors });
    return Response.json({ matchId: id, updatedAt: row.updated_at, state: JSON.parse(row.payload) }, { headers: cors });
  }

  if (request.method === "PUT") {
    const raw = await request.text();
    if (raw.length > 200000) return new Response("Payload too large", { status: 413, headers: cors });
    let payload;
    try { payload = JSON.parse(raw); } catch { return new Response("Invalid JSON", { status: 400, headers: cors }); }
    const updatedAt = new Date().toISOString();
    await env.LIVE_DB.prepare("INSERT INTO live_matches (match_id, payload, updated_at) VALUES (?, ?, ?) ON CONFLICT(match_id) DO UPDATE SET payload=excluded.payload, updated_at=excluded.updated_at").bind(id, JSON.stringify(payload), updatedAt).run();
    return Response.json({ ok: true, matchId: id, updatedAt }, { headers: cors });
  }

  return new Response("Method not allowed", { status: 405, headers: cors });
}
