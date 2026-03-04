#!/bin/bash
set -euo pipefail

APP_PATH="$1"
DMG_PATH="$2"
VOLUME_NAME="SystemPulse"
STAGING_DIR=$(mktemp -d)

cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

rm -rf "$STAGING_DIR"
echo "Created $DMG_PATH"
