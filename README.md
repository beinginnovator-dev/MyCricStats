# MyCricStats v4 — deploy package

## Repo layout (do not flatten)

```
MyCricStats/
  public/
    index.html
    manifest.webmanifest
    sw.js
    icons/icon-192.png
    icons/icon-512.png
    icons/apple-touch-icon.png
  functions/
    api/
      proxy.js          ← Pages only (/api/proxy)
  worker.js             ← FULL worker for workers.dev (NOT placeholder)
  README.md
```

## Recommended: Cloudflare Pages (auto from GitHub)

1. Delete or ignore the old Worker URL if it stays broken.
2. Cloudflare → Workers & Pages → Create → **Pages** → Connect Git → this repo.
3. Build settings:
   - Framework preset: **None**
   - Build command: *(leave empty)*
   - **Build output directory: `public`**
4. Save and Deploy.
5. Open the **`*.pages.dev`** URL Cloudflare gives you (not workers.dev).
6. Test:
   `https://YOUR-PROJECT.pages.dev/api/proxy?sport=cricket&path=livescores&api_token=YOUR_TOKEN`
   - 404 = output directory wrong or functions folder missing
   - 401 / JSON = OK

## Optional: workers.dev (manual)

Only if you must keep `mycricstats.being-innovator.workers.dev`:

1. Open Worker **mycricstats** → Edit code.
2. Delete all code → paste **entire** `worker.js` from this repo.
3. Confirm the file does **not** contain `PLACEHOLDER`.
4. Deploy.
5. Clear phone site data / reinstall PWA.

Pushing to GitHub alone does **not** update a Worker unless Git integration is enabled and you deploy from it.

## App setup

1. Open site → Settings → paste Sportmonks token → Save.
2. Football / Cricket tabs load via `/api/proxy`.

## Free plan note

Sportmonks free plan only includes selected leagues. Empty match list can mean no live games on your plan.
