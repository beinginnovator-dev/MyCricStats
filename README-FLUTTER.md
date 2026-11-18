# MyCricStats Flutter

This is the Flutter rebuild of **MyCricStats (MCS)**. It is a cricket-only application and is not the MySportzStats football scorer.

## Current foundation
- MyCricStats navy / red / gold match-centre visual language
- Home, Matches, Scorecard, Commentary and Tournament & Tools destinations
- Domestic match feed loaded from `/api/domestic` and refreshed every 20 seconds
- Match selection and scorecard overview
- Cricket-only Sportmonks proxy client using `/api/proxy?path=...` with guest/server token support
- Flutter Web and Android targets

## Build
```bash
flutter pub get
flutter run -d chrome
flutter build web --release --base-href /
flutter build apk --release
```

Cloudflare Pages uses `bash scripts/cloudflare_build.sh` with output directory `build/web`.

## Cricket API
The existing Pages Function `/api/proxy` is restricted to Sportmonks Cricket API v2 resources. Set `SPORTMONKS_TOKEN` in Cloudflare Pages environment variables for guest API calls. The Flutter client must not route to a football API.

## Migration status
This commit establishes the correct MCS Flutter app shell and domestic feed connection. Full migration of live fixture scorecards, ball-by-ball commentary/TTS, match-room chat, scorer controls, history, tournament calculations, advertisements and player/squad management remains staged work. Those modules are not represented as completed integrations.
