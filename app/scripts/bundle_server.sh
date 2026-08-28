#!/usr/bin/env bash
# Stages the server into the app's assets so a desktop build can run it itself.
#
# A restaurant should download one thing. Bundling PocketBase and its schema
# means the app can start its own server on first run, with no second download,
# no terminal, and no internet needed after install.
#
# The binary is not committed — this copies whichever one server/fetch_pocketbase.sh
# pulled for the host platform, so a build always bundles a matching binary.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(cd .. && pwd)"
DEST="assets/server"

BIN="$ROOT/server/bin/pocketbase"
[ -f "$ROOT/server/bin/pocketbase.exe" ] && BIN="$ROOT/server/bin/pocketbase.exe"

if [ ! -f "$BIN" ]; then
  echo "PocketBase binary missing. Fetching it..."
  "$ROOT/server/fetch_pocketbase.sh"
fi

rm -rf "$DEST"
mkdir -p "$DEST/pb_migrations" "$DEST/pb_hooks" "$DEST/pb_public"

cp "$BIN" "$DEST/$(basename "$BIN")"
cp "$ROOT/server/pb_migrations/"*.js "$DEST/pb_migrations/"
cp "$ROOT/server/pb_hooks/"*.js "$DEST/pb_hooks/"
cp "$ROOT/server/pb_public/"* "$DEST/pb_public/"
cp "$ROOT/server/VERSION" "$DEST/VERSION"

# A manifest, because Flutter's asset bundle cannot be listed at runtime in a
# way that survives tree-shaking. The app reads this to know what to extract.
{
  echo "binary=$(basename "$BIN")"
  echo "version=$(cat "$ROOT/server/VERSION")"
  for f in "$DEST/pb_migrations/"*.js; do echo "migration=$(basename "$f")"; done
  for f in "$DEST/pb_hooks/"*.js;      do echo "hook=$(basename "$f")"; done
  for f in "$DEST/pb_public/"*;        do echo "public=$(basename "$f")"; done
} > "$DEST/manifest.txt"

echo "Bundled PocketBase $(cat "$ROOT/server/VERSION") into app/$DEST"
du -sh "$DEST" | awk '{print "  " $1}'
