const cors = {"Access-Control-Allow-Origin":"*","Access-Control-Allow-Methods":"GET,OPTIONS","Access-Control-Allow-Headers":"Content-Type","Cache-Control":"no-store"};
export async function onRequest({request,env}) {
  if(request.method==="OPTIONS") return new Response(null,{headers:cors});
  if(request.method!=="GET") return new Response("Method not allowed",{status:405,headers:cors});
  if(!env.LIVE_DB) return Response.json({error:"Live database is not configured"},{status:503,headers:cors});
  const rows=await env.LIVE_DB.prepare("SELECT match_id, payload, updated_at FROM live_matches ORDER BY updated_at DESC LIMIT 100").all();
  const matches=(rows.results||[]).map(row=>{let state={};try{state=JSON.parse(row.payload||"{}")}catch{}const m=state.match||{};return {id:row.match_id,updatedAt:row.updated_at,matchDate:m.completedAt||m.createdAt||row.updated_at,title:m.settings?.title||"MATCH DAY",teamA:m.teamA||state.teamA?.name||"Team A",teamB:m.teamB||state.teamB?.name||"Team B",status:m.status||"Unknown"};});
  return Response.json({matches},{headers:cors});
}