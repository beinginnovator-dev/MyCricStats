MYCRICSTATS MATCH CENTRE UPDATE
================================
Cloudflare Pages deployment. Preserve the supplied folder paths.

1) GITHUB STRUCTURE
functions/api/proxy.js
functions/api/chat.js
functions/api/domestic.js
functions/api/news.js
migrations/0001_mcs_chat.sql
migrations/0002_domestic_matches.sql
public/index.html
public/manifest.webmanifest
public/sw.js
public/audio/crowd_chant.mp3
public/audio/crowd_cheer.mp3
public/audio/crowd_whistle.mp3

2) CLOUDFLARE PAGES
Root directory: /
Build command: blank
Build output directory: public
Keep SPORTMONKS_TOKEN as a Cloudflare environment variable.

3) D1 DATABASE
Create or reuse the D1 database named mycricstats-chat.
Bind it to the Pages project using variable name MCS_DB.
If 0001_mcs_chat.sql was already applied, run ONLY 0002_domestic_matches.sql now.
If setting up from scratch, run 0001 then 0002 in order.

4) DOMESTIC SCORER FEED
The viewer polls GET https://mycricstats.pages.dev/api/domestic every 10 seconds.
The separate scoring app must POST each newly started match and every score/status update
as JSON to https://mycricstats.pages.dev/api/domestic.
A ready-to-adapt helper is supplied in SCORER-DOMESTIC-PUBLISH.js.
Call publishDomesticMatch(match) after match creation and each scoring update.
The endpoint accepts id, name, teamA, teamB, teamAId, teamBId, status, scoreA,
scoreB, wicketsA, wicketsB, oversA, oversB, runs, batting, bowling, balls and lineup.
The API is CORS-enabled for cross-origin scorer deployments.

5) WHAT CHANGED
- White ball animation now races from the bowling side to the batting side.
- Current tab and match are restored on refresh; URL retains tab and match context.
- Batter and bowler name typography is unified; striker has a gold asterisk.
- Match invite includes inviter, match name, current score, live commentary/chat message,
  and a generated score-card image when Web Share file support is available.
- Chat popover has invite, room-members, minimize, maximize/restore and close controls.
- Room tab explicitly refreshes online members and shows online count.
- Domestic feed is loaded on startup, every 10 seconds and on tab visibility.
- Domestic match records persist in D1 instead of depending on edge cache alone.

6) DEPLOY
Commit the contents of the package to the existing GitHub repository and let Pages deploy.
For a fresh PWA load, close the installed app and reopen it after deployment. The service
worker cache version is bumped to mcs-v8-matchcentre-room-chat.

IMPORTANT
The domestic viewer feed cannot show scorer matches until the separate scorer app sends
POST updates to /api/domestic. The included helper shows the required integration call.
The invite image is shared as an image on devices whose Web Share API supports files;
otherwise the invite shares a rich text message and live link.
