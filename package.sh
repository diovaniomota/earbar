#!/bin/bash
set -euo pipefail

# Release build for direct distribution: builds Earbar.app and wraps it in a
# drag-to-Applications .dmg.
#
# Without SIGN_IDENTITY the app keeps build.sh's ad-hoc signature and the .dmg
# is unsigned. That is fine for sharing: people open it with right-click → Open
# (see the README).
#
# With a Developer ID identity the app is signed with the hardened runtime,
# notarized and stapled, and the .dmg is signed, notarized and stapled too, so
# Gatekeeper opens it without a warning:
#
#   SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
#   NOTARY_PROFILE=my-profile bash package.sh 1.0.0
#
# NOTARY_PROFILE is a notarytool keychain profile, created once per Mac with:
#   xcrun notarytool store-credentials my-profile --key AuthKey.p8 --key-id … --issuer …
#
# SKIP_NOTARIZE=1 signs without notarizing, for local checks.

APP_NAME="Earbar"
VERSION="${1:-1.0.0}"
DIST="dist"
STAGE="$DIST/stage"
DMG="$DIST/$APP_NAME-$VERSION.dmg"
IDENTITY="${SIGN_IDENTITY:-}"
PROFILE="${NOTARY_PROFILE:-}"

NOTARIZE=""
if [ -n "$IDENTITY" ] && [ -z "${SKIP_NOTARIZE:-}" ]; then
  if [ -z "$PROFILE" ]; then
    echo "error: set NOTARY_PROFILE to a notarytool keychain profile, or SKIP_NOTARIZE=1" >&2
    exit 1
  fi
  NOTARIZE=1
fi

echo "==> Building…"
bash build.sh

mkdir -p "$DIST"
if [ -n "$IDENTITY" ]; then
  echo "==> Signing $APP_NAME.app with Developer ID…"
  codesign --force --options runtime --timestamp \
    --entitlements Signing/Earbar-Direct.entitlements \
    --sign "$IDENTITY" "$APP_NAME.app"
  codesign --verify --deep --strict "$APP_NAME.app"

  if [ -n "$NOTARIZE" ]; then
    echo "==> Notarizing $APP_NAME.app…"
    ditto -c -k --keepParent "$APP_NAME.app" "$DIST/$APP_NAME.zip"
    xcrun notarytool submit "$DIST/$APP_NAME.zip" --keychain-profile "$PROFILE" --wait
    xcrun stapler staple "$APP_NAME.app"
    rm -f "$DIST/$APP_NAME.zip"
  fi
fi

echo "==> Staging $APP_NAME.app…"
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP_NAME.app" "$STAGE/$APP_NAME.app"
ln -s /Applications "$STAGE/Applications"

echo "==> Creating .dmg…"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGE" \
  -ov -format UDZO \
  "$DMG"
rm -rf "$STAGE"

if [ -n "$IDENTITY" ]; then
  codesign --force --timestamp --sign "$IDENTITY" "$DMG"
  if [ -n "$NOTARIZE" ]; then
    echo "==> Notarizing ${DMG}…"
    xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait
    xcrun stapler staple "$DMG"
    echo "==> Gatekeeper check:"
    spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG" 2>&1 | tail -1
  fi
fi

echo "==> Done: $DMG"
echo "    SHA256: $(shasum -a 256 "$DMG" | awk '{print $1}')"
