# MyCricStats — Flutter migration branch

This branch is the Flutter Web + Android implementation track. It is isolated from `main`.

## Local development
1. Install the Flutter stable SDK.
2. From the repository root run:
   ```sh
   flutter pub get
   flutter run -d chrome
   ```
3. For Android: `flutter run` with an Android device/emulator, or `flutter build apk --release`.

## Cloudflare Pages
The Pages project build is configured to run `bash scripts/cloudflare_build.sh` and publish `build/web`. The script installs the stable Flutter SDK in the build environment, enables web, resolves packages, and builds the web app.

## Current migration scope
The first Flutter milestone establishes the responsive match-centre shell and interactive Toss setup. The current HTML app remains the reference for Sportmonks, scoring, commentary, chat, domestic feeds, tournament history and administration. Those integrations must be ported and verified before this Flutter version is considered feature-complete. No production branch changes are made here.
