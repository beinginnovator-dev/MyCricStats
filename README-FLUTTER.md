# MyCricStats — Flutter migration branch

This branch is the Flutter Web + Android implementation track. It is isolated from `main`.

## Local development
1. Install the Flutter stable SDK and Android Studio (for Android builds).
2. From the repository root, generate platform folders once:
   ```sh
   flutter create --platforms=android,web --project-name mycricstats --org com.beinginnovator .
   flutter pub get
   ```
3. Run the web app with `flutter run -d chrome`.
4. Build Android with `flutter build apk --release`.

## Cloudflare Pages
The separate Pages project `mycricstats-flutter-test` runs `bash scripts/cloudflare_build.sh` and publishes `build/web`. The build script installs Flutter stable, generates platform scaffolding, resolves packages, and builds the web app.

## Current migration scope
The first Flutter milestone establishes the responsive match-centre shell and interactive Toss setup, plus Squads and Stats screens. It is a UI foundation, not yet a complete port. Sportmonks live scores, scoring controls, commentary/TTS, chat, D1 history, domestic feeds, advertisements, tournament calculations and administration still need to be migrated and verified. No production branch changes are made here.
