# MyCricStats

Live cricket scores (Sportmonks) — Cloudflare **Pages** only.

## Folder layout (keep this structure)

```
MyCricStats/
  public/
    index.html
    manifest.webmanifest
    sw.js
    icons/
      icon-192.png
      icon-512.png
      apple-touch-icon.png
  functions/
    api/
      proxy.js
  README.md
```

## Deploy on Cloudflare Pages

1. Push this repo to GitHub.
2. Cloudflare → Workers & Pages → Create → **Pages** → Connect Git → this repo.
3. Build settings:
   - Framework preset: **None**
   - Build command: *(empty)*
   - **Build output directory: `public`**
4. Save and Deploy.
5. Open **https://YOUR-PROJECT.pages.dev** (not workers.dev).

### Test API proxy

```
https://YOUR-PROJECT.pages.dev/api/proxy?sport=cricket&path=livescores&api_token=YOUR_TOKEN
```

Expect JSON or 401 — not 404.

## App setup

1. Open site → ⚙ → paste Sportmonks token → Save.
2. Free plan leagues only: T20I, BBL, CSA T20 (as per Sportmonks).

## Do not use Workers for this project

Use **Pages** only so GitHub pushes update the live site and `/api/proxy` works.
