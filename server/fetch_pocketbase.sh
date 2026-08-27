#!/usr/bin/env bash
# Downloads the pinned PocketBase binary for this machine into server/bin/.
# PocketBase is not vendored into git — it is fetched on demand.
set -euo pipefail

cd "$(dirname "$0")"
VERSION="$(cat VERSION)"

case "$(uname -s)" in
  Darwin) OS="darwin" ;;
  Linux)  OS="linux" ;;
  MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
  *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

case "$(uname -m)" in
  arm64|aarch64) ARCH="arm64" ;;
  x86_64|amd64)  ARCH="amd64" ;;
  armv7l)        ARCH="armv7" ;;
  *) echo "Unsupported arch: $(uname -m)" >&2; exit 1 ;;
esac

BIN="bin/pocketbase"
[ "$OS" = "windows" ] && BIN="bin/pocketbase.exe"

if [ -x "$BIN" ] && "./$BIN" --version 2>/dev/null | grep -q "$VERSION"; then
  echo "PocketBase $VERSION already present."
  exit 0
fi

ASSET="pocketbase_${VERSION}_${OS}_${ARCH}.zip"
URL="https://github.com/pocketbase/pocketbase/releases/download/v${VERSION}/${ASSET}"

echo "Downloading $ASSET ..."
mkdir -p bin
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
curl -fsSL "$URL" -o "$TMP/pb.zip"
unzip -qo "$TMP/pb.zip" -d "$TMP"
mv "$TMP/pocketbase"* "bin/"
chmod +x "$BIN"

echo "PocketBase $VERSION ready at server/$BIN"
