/*
 * Add this helper to the separate scoring app.
 * Call publishDomesticMatch(match) after match creation and after every score,
 * innings, status or result update. Replace the URL if your Pages domain changes.
 */
const MYCRICSTATS_DOMESTIC_FEED = 'https://mycricstats.pages.dev/api/domestic';

async function publishDomesticMatch(match) {
  const payload = {
    id: String(match.id),
    name: match.name || match.tournament || 'Domestic Match',
    teamA: match.teamA || match.localteam?.name || match.homeTeam,
    teamB: match.teamB || match.visitorteam?.name || match.awayTeam,
    teamAId: match.teamAId || match.localteam_id,
    teamBId: match.teamBId || match.visitorteam_id,
    venue: match.venue?.name || match.venue || '',
    type: match.type || match.format || 'T20',
    when: match.starting_at || match.when || new Date().toISOString(),
    status: match.status || (match.isLive ? 'live' : 'upcoming'),
    scoreA: match.scoreA ?? match.runsA ?? match.teamAScore ?? null,
    scoreB: match.scoreB ?? match.runsB ?? match.teamBScore ?? null,
    wicketsA: match.wicketsA ?? null,
    wicketsB: match.wicketsB ?? null,
    oversA: match.oversA ?? null,
    oversB: match.oversB ?? null,
    runs: Array.isArray(match.runs) ? match.runs : [],
    batting: Array.isArray(match.batting) ? match.batting : [],
    bowling: Array.isArray(match.bowling) ? match.bowling : [],
    balls: Array.isArray(match.balls) ? match.balls : [],
    lineup: Array.isArray(match.lineup) ? match.lineup : []
  };
  const response = await fetch(MYCRICSTATS_DOMESTIC_FEED, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
    keepalive: true
  });
  if (!response.ok) throw new Error('Domestic publish failed: HTTP ' + response.status + ' ' + await response.text());
  return response.json();
}
