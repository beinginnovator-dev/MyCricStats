# MyCricStats Flutter migration

This branch now builds the Flutter Web app from `lib/main.dart` and is also the Android app source.

- Flutter project: repository root (`pubspec.yaml`, `lib/`, `web/`)
- Local web: `flutter run -d chrome`
- Android APK: `flutter build apk --release`
- Cloudflare test project: `mycricstats-flutter-test.pages.dev`
- Cloudflare build command: `bash scripts/cloudflare_build.sh`
- Cloudflare output directory: `build/web`

The initial UI milestone contains Match, Toss, Squads and Stats screens. It is a UI foundation, not yet a feature-complete port of the current HTML app. Sportmonks live scores, scoring controls, commentary/TTS, chat, D1 history, domestic feeds, ads and tournament calculations still need to be migrated and tested before replacing the existing scorer.
