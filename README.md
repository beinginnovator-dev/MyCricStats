# MyCricStats (Sportmonks + Cloudflare PWA)

Live football & cricket scores via **Sportmonks**, with a **Cloudflare proxy** so data works in the browser (no CORS failures).

## Why fetch failed before

Sportmonks API does **not** allow browser calls from random origins (CORS).  
Calling `api.sportmonks.com` from your Pages/Workers **frontend** fails with *Failed to fetch*.

**Fix:** this package includes a **same-origin proxy**:

- Browser → `https://yoursite.pages.dev/api/football/livescores/inplay?...`
- Cloudflare Function → `https://api.sportmonks.com/v3/football/livescores/inplay?...`

## Folder layout

```
mycricstats/
  public/
    index.html              # App (PWA)
    manifest.webmanifest
    sw.js
    icons/icon-192.png
    icons/icon-512.png
  functions/
    api/[[path]].js         # Cloudflare Pages Function (proxy)
  worker.js                 # Optional standalone Worker
  README.md
```

## Deploy on Cloudflare Pages (recommended)

### A) From GitHub (mobile-friendly)

1. Create repo **mycricstats** on GitHub (empty).
2. Upload **all files** keeping folders:
   - Upload `public/index.html`, `public/manifest.webmanifest`, `public/sw.js`, `public/icons/...`
   - Upload `functions/api/[[path]].js` (folder name must be `functions/api/`)
3. Cloudflare Dashboard → **Workers & Pages** → **Create** → **Pages** → **Connect to Git**
4. Select repo **mycricstats**
5. Build settings:
   - Framework preset: **None**
   - Build command: *(empty)*
   - **Build output directory: `public`**
6. **Save and Deploy**

After deploy, open the `*.pages.dev` URL.

### B) Re-deploy to existing Worker URL

If you use `mycricstats.being-innovator.workers.dev`:

- Prefer **Pages** (has Functions) over a bare Worker that only serves HTML.
- Or attach this Worker as a **Pages** project custom domain / route.

## Use the app

1. Open site → **⚙** → **Add Sportmonks token** → Save  
2. Football / Cricket switch  
3. Matches load via `/api/...` (no CORS error)

Test proxy in browser address bar (replace TOKEN):

```
https://YOUR-DOMAIN/api/football/livescores/inplay?api_token=TOKEN&include=participants;scores;state
```

You should see JSON, not a CORS error.

## Install as app (PWA)

- **Android Chrome:** menu → **Install app** / **Add to Home screen**
- **iPhone Safari:** Share → **Add to Home Screen**

If you still see “cannot be installed”:

- Must be **HTTPS** (Pages is)
- `manifest.webmanifest` must be reachable
- Icons 192 + 512 must load
- Soft reload once after first deploy

## Local test (optional)

```bash
npx wrangler pages dev public --compatibility-date=2024-01-01
```

## Security note

Token stays in the user’s browser (`localStorage`) and is sent as query/header to **your** `/api` proxy only. Do not commit tokens to Git.


## Fix HTTP 404 on /api

**Cause:** Proxy Function missing or wrong path (common if only `index.html` was uploaded to a Worker).

**Correct structure for Cloudflare Pages:**

```
your-repo/
  public/
    index.html
    manifest.webmanifest
    sw.js
    icons/
  functions/
    api/
      proxy.js          ← MUST exist (handles /api/proxy)
```

**Build output directory:** `public`

**Test after deploy:**
```
https://YOUR-DOMAIN/api/proxy?sport=football&path=livescores/inplay&api_token=YOUR_TOKEN&include=participants;scores;state
```

- **404** → Function not deployed (check `functions/api/proxy.js` is in the repo root `functions/`, not inside `public/`)
- **401** → Token missing
- **200 + JSON** → Proxy works; open the app and refresh matches
