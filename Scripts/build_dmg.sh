#!/usr/bin/env bash
set -euo pipefail

APP_NAME="MinNote"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
DERIVED_DATA_DIR="$ROOT_DIR/build/DerivedData"
CONFIGURATION="${CONFIGURATION:-Release}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"

mkdir -p "$DIST_DIR"

xcodebuild \
  -project "$ROOT_DIR/$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
  CODE_SIGN_STYLE=Manual \
  build

APP_PATH="$DERIVED_DATA_DIR/Build/Products/$CONFIGURATION/$APP_NAME.app"
DIST_APP="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"

rm -rf "$DIST_APP" "$DMG_PATH"
cp -R "$APP_PATH" "$DIST_APP"

codesign --verify --deep --strict --verbose=2 "$DIST_APP"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DIST_APP" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "Created $DMG_PATH"
