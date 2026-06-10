#!/usr/bin/env bash
# Builds an unsigned (ad-hoc) Hush.dmg for GitHub Releases.
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/dd/Build/Products/Release/Hush.app"
DMG="Hush.dmg"

xcodegen generate
rm -rf build "$DMG"

xcodebuild build -project Hush.xcodeproj -scheme Hush -configuration Release -derivedDataPath build/dd \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="-" DEVELOPMENT_TEAM="" PROVISIONING_PROFILE_SPECIFIER="" \
  CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=NO

codesign --force --deep --sign - "$APP"

STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Hush" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
rm -rf "$STAGE"

echo "Built $DMG"
shasum -a 256 "$DMG"
