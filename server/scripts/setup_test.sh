#!/usr/bin/env bash
# Checks the two public first-run endpoints against a virgin database:
# /api/app/status must report an unconfigured server, and /api/app/bootstrap
# must create the venue and its first owner exactly once and never again.
set -euo pipefail

cd "$(dirname "$0")/.."

PORT=8092
API="http://127.0.0.1:${PORT}/api"
DATA="./pb_setup_test_data"

pass=0; fail=0
check() {
  if [ "$2" = "$3" ]; then
    printf '  \033[32mok\033[0m   %-30s %s\n' "$1" "$3"; pass=$((pass+1))
  else
    printf '  \033[31mFAIL\033[0m %-30s expected %s, got %s\n' "$1" "$2" "$3"; fail=$((fail+1))
  fi
}

cleanup() { pkill -f "pocketbase serve --dir=${DATA}" 2>/dev/null || true; rm -rf "$DATA"; }
trap cleanup EXIT

rm -rf "$DATA"
./bin/pocketbase migrate up --dir="$DATA" --migrationsDir=./pb_migrations >/dev/null
./bin/pocketbase serve --dir="$DATA" --migrationsDir=./pb_migrations --hooksDir=./pb_hooks --publicDir=./pb_public \
  --http="127.0.0.1:${PORT}" >/dev/null 2>&1 &

for _ in $(seq 1 40); do
  curl -sf "${API}/health" >/dev/null 2>&1 && break
  sleep 0.25
done

echo "A virgin server reports itself unconfigured"
S=$(curl -s "${API}/app/status")
check "configured" "false" "$(echo "$S" | jq -r .configured)"
check "has_staff" "false" "$(echo "$S" | jq -r .has_staff)"

echo
echo "Bootstrap validates before it writes"
R=$(curl -s -o /dev/null -w '%{http_code}' -X POST "${API}/app/bootstrap" \
  -H 'Content-Type: application/json' -d '{"restaurant_name":"X"}')
check "missing fields rejected" "400" "$R"

R=$(curl -s -X POST "${API}/app/bootstrap" -H 'Content-Type: application/json' \
  -d '{"restaurant_name":"X","owner_name":"Y","owner_username":"y","owner_pin":"12"}')
check "short PIN rejected" "PIN must be at least 4 characters." "$(echo "$R" | jq -r .message)"

R=$(curl -s -X POST "${API}/app/bootstrap" -H 'Content-Type: application/json' \
  -d '{"restaurant_name":"X","owner_name":"Y","owner_username":"bad user!","owner_pin":"1234"}')
check "bad username rejected" "400" "$(echo "$R" | jq -r 'if .message then 400 else 200 end')"

echo
echo "A failed bootstrap leaves the server still setup-able"
check "still unconfigured" "false" "$(curl -s "${API}/app/status" | jq -r .configured)"

echo
echo "Bootstrap creates the venue and its first owner"
R=$(curl -s -X POST "${API}/app/bootstrap" -H 'Content-Type: application/json' -d '{
  "restaurant_name":"The Ember","owner_name":"Shakib","owner_username":"Shakib",
  "owner_pin":"4821","currency_code":"BDT","currency_symbol":"Tk",
  "tax_rate":5,"service_charge_rate":10}')
check "owner created" "shakib" "$(echo "$R" | jq -r .username)"

S=$(curl -s "${API}/app/status")
check "now configured" "true" "$(echo "$S" | jq -r .configured)"
check "venue name" "The Ember" "$(echo "$S" | jq -r .name)"

echo
echo "The new owner can sign in with their PIN"
A=$(curl -s -X POST "${API}/collections/staff/auth-with-password" \
  -H 'Content-Type: application/json' -d '{"identity":"shakib","password":"4821"}')
check "auth role" "owner" "$(echo "$A" | jq -r .record.role)"
check "auth token issued" "true" "$(echo "$A" | jq -r 'if (.token // "") != "" then "true" else "false" end')"

echo
echo "Bootstrap can never run twice"
R=$(curl -s -o /dev/null -w '%{http_code}' -X POST "${API}/app/bootstrap" \
  -H 'Content-Type: application/json' -d '{
  "restaurant_name":"Hijack","owner_name":"Attacker","owner_username":"attacker","owner_pin":"9999"}')
check "second bootstrap refused" "409" "$R"

echo
printf '\033[1m%d passed, %d failed\033[0m\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
