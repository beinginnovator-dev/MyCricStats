#!/usr/bin/env bash
set -euo pipefail
FLUTTER_DIR="${RUNNER_TEMP:-/tmp}/flutter-sdk"
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  rm -rf "$FLUTTER_DIR"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"
flutter --version
flutter config --enable-web
# Generate Android platform files as well as web scaffolding when first building.
flutter create --platforms=android,web --project-name mycricstats --org com.beinginnovator .
flutter pub get
flutter build web --release --base-href /
