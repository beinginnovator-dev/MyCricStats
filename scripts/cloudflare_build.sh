#!/usr/bin/env bash
set -Eeuo pipefail

echo "=== MyCricStats Flutter Pages build starting ==="
export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true
export GIT_TERMINAL_PROMPT=0

FLUTTER_DIR="${RUNNER_TEMP:-/tmp}/flutter-sdk"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "=== Installing Flutter stable SDK ==="
  rm -rf "$FLUTTER_DIR"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
echo "=== Flutter version ==="
flutter --version

echo "=== Generate web platform scaffolding (skip nested pub get) ==="
flutter create --platforms=web --project-name mycricstats --org com.beinginnovator .

echo "=== Resolve Dart dependencies ==="
flutter pub get

echo "=== Build Flutter web release ==="
flutter build web --release --base-href /

cat > web/manifest.json <<'MANIFEST'
{
  "name": "MyCricStats - MySportzStats Cricket",
  "short_name": "MyCricStats",
  "description": "Professional cricket scoring and tournament centre",
  "start_url": "/",
  "scope": "/",
  "display": "standalone",
  "orientation": "any",
  "background_color": "#080d1b",
  "theme_color": "#080d1b",
  "icons": [
    {"src": "icons/Icon-192.png", "sizes": "192x192", "type": "image/png"},
    {"src": "icons/Icon-512.png", "sizes": "512x512", "type": "image/png"},
    {"src": "icons/Icon-maskable-192.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable"},
    {"src": "icons/Icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable"}
  ]
}
MANIFEST

echo "=== Verify build output ==="
test -s build/web/index.html
find build/web -maxdepth 1 -type f -printf '%f\n' | head -20
echo "=== MyCricStats Flutter Pages build completed ==="
