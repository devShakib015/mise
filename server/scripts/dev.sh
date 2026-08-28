#!/usr/bin/env bash
# Starts PocketBase for local development, with hooks and migrations wired up.
set -euo pipefail
cd "$(dirname "$0")/.."

[ -x bin/pocketbase ] || ./fetch_pocketbase.sh

exec ./bin/pocketbase serve \
  --dir=./pb_data \
  --migrationsDir=./pb_migrations \
  --hooksDir=./pb_hooks \
  --publicDir=./pb_public \
  --http=127.0.0.1:8090 \
  --dev
