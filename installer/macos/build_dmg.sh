#!/usr/bin/env bash
# Builds Mise.app and wraps it in a DMG a restaurant can download and drag to
# Applications.
#
# The result is unsigned unless CODESIGN_IDENTITY is set. Unsigned is fine and
# free — macOS will warn on first launch and the user opens it from the right
# click menu once. See docs/install-macos.md.
set -euo pipefail

cd "$(dirname "$0")/../.."
ROOT="$(pwd)"
OUT="$ROOT/installer/out"
APP_NAME="Mise"
VERSION="$(grep -E '^version:' app/pubspec.yaml | head -1 | sed -E 's/version: *([^+]+).*/\1/' | tr -d ' ')"
DMG="$OUT/${APP_NAME}-${VERSION}-macos.dmg"

echo "==> Staging the server into the app"
./app/scripts/bundle_server.sh

echo "==> Building ${APP_NAME} ${VERSION} (release)"
(cd app && flutter build macos --release)

APP="$ROOT/app/build/macos/Build/Products/Release/${APP_NAME}.app"
[ -d "$APP" ] || { echo "Build produced no app at $APP" >&2; exit 1; }

if [ -n "${CODESIGN_IDENTITY:-}" ]; then
  echo "==> Signing with ${CODESIGN_IDENTITY}"
  # --deep is deprecated but still the pragmatic way to reach the bundled
  # server binary; sign it explicitly first so it is never missed.
  codesign --force --options runtime --timestamp \
    --sign "$CODESIGN_IDENTITY" \
    "$APP/Contents/Frameworks/App.framework/Versions/A/Resources/flutter_assets/assets/server/pocketbase" 2>/dev/null || true
  codesign --force --deep --options runtime --timestamp \
    --sign "$CODESIGN_IDENTITY" "$APP"
  codesign --verify --strict --verbose=2 "$APP"
else
  echo "==> Not signing (set CODESIGN_IDENTITY to sign)"
fi

echo "==> Assembling the disk image"
rm -rf "$OUT/dmg" "$DMG"
mkdir -p "$OUT/dmg"
cp -R "$APP" "$OUT/dmg/"
ln -s /Applications "$OUT/dmg/Applications"

# A short note in the image itself, because the Gatekeeper warning is the first
# thing a stranger sees and it needs an answer in front of them.
cat > "$OUT/dmg/READ ME FIRST.txt" <<'NOTE'
Mise — free restaurant management

1. Drag Mise into the Applications folder next to it.
2. The first time you open it, macOS will say it cannot check the app.
   Right-click Mise in Applications, choose Open, then Open again.
   You only do this once.
3. On the computer that will run your restaurant, choose
   "Run the restaurant on this computer".
   On tablets and the kitchen screen, type in the address it shows you.

Everything stays on your own machines. Nothing is sent anywhere.
NOTE

hdiutil create -volname "$APP_NAME" -srcfolder "$OUT/dmg" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$OUT/dmg"

echo
echo "Built $DMG"
du -h "$DMG" | awk '{print "  " $1}'
