#!/usr/bin/env bash
# Checks that an order's status follows its lines through the kitchen, and that
# bills which are not in service are never touched by that derivation.
set -euo pipefail

cd "$(dirname "$0")/.."

PORT=8094
API="http://127.0.0.1:${PORT}/api"
DATA="./pb_kitchen_test_data"
SU_EMAIL="test@local.test"
SU_PASS="testpassword123"

pass=0; fail=0
check() {
  if [ "$2" = "$3" ]; then
    printf '  \033[32mok\033[0m   %-34s %s\n' "$1" "$3"; pass=$((pass+1))
  else
    printf '  \033[31mFAIL\033[0m %-34s expected %s, got %s\n' "$1" "$2" "$3"; fail=$((fail+1))
  fi
}

cleanup() { pkill -f "pocketbase serve --dir=${DATA}" 2>/dev/null || true; rm -rf "$DATA"; }
trap cleanup EXIT

rm -rf "$DATA"
./bin/pocketbase migrate up --dir="$DATA" --migrationsDir=./pb_migrations >/dev/null
./bin/pocketbase superuser upsert "$SU_EMAIL" "$SU_PASS" --dir="$DATA" >/dev/null 2>&1
./bin/pocketbase serve --dir="$DATA" --migrationsDir=./pb_migrations --hooksDir=./pb_hooks \
  --http="127.0.0.1:${PORT}" >/dev/null 2>&1 &

for _ in $(seq 1 40); do
  curl -sf "${API}/health" >/dev/null 2>&1 && break
  sleep 0.25
done

TOKEN=$(curl -sf -X POST "${API}/collections/_superusers/auth-with-password" \
  -H 'Content-Type: application/json' \
  -d "{\"identity\":\"${SU_EMAIL}\",\"password\":\"${SU_PASS}\"}" | jq -r .token)

post()  { curl -sf -X POST "${API}/collections/$1/records" \
  -H "Authorization: ${TOKEN}" -H 'Content-Type: application/json' -d "$2"; }
patch() { curl -sf -X PATCH "${API}/collections/$1/records/$2" \
  -H "Authorization: ${TOKEN}" -H 'Content-Type: application/json' -d "$3"; }
get()   { curl -sf "${API}/collections/$1/records/$2" -H "Authorization: ${TOKEN}"; }
status(){ get orders "$1" | jq -r .status; }

post restaurant '{"name":"Test","currency_code":"USD","currency_symbol":"$",
  "tax_rate":0,"service_charge_rate":0,"setup_complete":true}' >/dev/null
STAFF=$(post staff '{"name":"Chef","username":"chef","role":"kitchen","active":true,
  "password":"1234","passwordConfirm":"1234"}' | jq -r .id)
CAT=$(post categories '{"name":"Mains","active":true}' | jq -r .id)
ITEM=$(post menu_items "{\"category\":\"${CAT}\",\"name\":\"Soup\",\"price\":10,\"active\":true,\"available\":true}" | jq -r .id)

line() { # line <orderId> -> id
  post order_items "{\"order\":\"$1\",\"menu_item\":\"${ITEM}\",\"name_snapshot\":\"Soup\",
    \"qty\":1,\"unit_price\":10,\"status\":\"queued\"}" | jq -r .id
}
NOW=$(date -u +"%Y-%m-%d %H:%M:%S.000Z")

echo "An unsent bill is never advanced"
O=$(post orders "{\"type\":\"takeaway\",\"staff\":\"${STAFF}\",\"status\":\"open\"}" | jq -r .id)
L1=$(line "$O"); L2=$(line "$O")
patch order_items "$L1" '{"status":"preparing"}' >/dev/null
check "open stays open" "open" "$(status "$O")"

echo
echo "Once sent, status follows the lines"
patch order_items "$L1" "{\"sent_at\":\"${NOW}\",\"status\":\"queued\"}" >/dev/null
patch order_items "$L2" "{\"sent_at\":\"${NOW}\"}" >/dev/null
patch orders "$O" '{"status":"sent"}' >/dev/null
check "both queued" "sent" "$(status "$O")"

patch order_items "$L1" '{"status":"preparing"}' >/dev/null
check "one cooking" "preparing" "$(status "$O")"

patch order_items "$L1" '{"status":"ready"}' >/dev/null
check "one ready, one queued" "sent" "$(status "$O")"

patch order_items "$L2" '{"status":"ready"}' >/dev/null
check "all ready" "ready" "$(status "$O")"

patch order_items "$L1" '{"status":"served"}' >/dev/null
check "one served, one ready" "ready" "$(status "$O")"

patch order_items "$L2" '{"status":"served"}' >/dev/null
check "all served" "served" "$(status "$O")"

echo
echo "A voided line does not hold the ticket back"
O2=$(post orders "{\"type\":\"takeaway\",\"staff\":\"${STAFF}\",\"status\":\"open\"}" | jq -r .id)
A=$(line "$O2"); B=$(line "$O2")
patch order_items "$A" "{\"sent_at\":\"${NOW}\"}" >/dev/null
patch order_items "$B" "{\"sent_at\":\"${NOW}\"}" >/dev/null
patch orders "$O2" '{"status":"sent"}' >/dev/null
patch order_items "$B" '{"status":"void","void_reason":"86"}' >/dev/null
patch order_items "$A" '{"status":"ready"}' >/dev/null
check "ready despite the void" "ready" "$(status "$O2")"

echo
echo "A settled bill is left alone"
O3=$(post orders "{\"type\":\"takeaway\",\"staff\":\"${STAFF}\",\"status\":\"open\"}" | jq -r .id)
C=$(line "$O3")
patch order_items "$C" "{\"sent_at\":\"${NOW}\"}" >/dev/null
patch orders "$O3" '{"status":"paid"}' >/dev/null
patch order_items "$C" '{"status":"preparing"}' >/dev/null
check "paid stays paid" "paid" "$(status "$O3")"

patch orders "$O3" '{"status":"cancelled"}' >/dev/null
patch order_items "$C" '{"status":"ready"}' >/dev/null
check "cancelled stays cancelled" "cancelled" "$(status "$O3")"

echo
printf '\033[1m%d passed, %d failed\033[0m\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
