#!/bin/bash
set -euo pipefail

DMG_PATH="$1"

xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_SPECIFIC_PASSWORD" \
    --wait

xcrun stapler staple "$DMG_PATH"

echo "Notarization complete and stapled."
