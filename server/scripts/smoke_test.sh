#!/usr/bin/env bash
# End-to-end check that the schema and the server-side money hooks behave.
# Runs against a throwaway database on port 8091; never touches real data.
set -euo pipefail

cd "$(dirname "$0")/.."

PORT=8091
API="http://127.0.0.1:${PORT}/api"
DATA="./pb_test_data"
SU_EMAIL="test@local.test"
SU_PASS="testpassword123"

pass=0; fail=0
check() { # check <label> <expected> <actual>
  if [ "$2" = "$3" ]; then
    printf '  \033[32mok\033[0m   %-28s %s\n' "$1" "$3"; pass=$((pass+1))
  else
    printf '  \033[31mFAIL\033[0m %-28s expected %s, got %s\n' "$1" "$2" "$3"; fail=$((fail+1))
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

post() { curl -sf -X POST "${API}/collections/$1/records" \
  -H "Authorization: ${TOKEN}" -H 'Content-Type: application/json' -d "$2"; }
get()  { curl -sf "${API}/collections/$1/records/$2" -H "Authorization: ${TOKEN}"; }

echo "Seeding..."
# 10% tax added on top, 5% service charge.
post restaurant '{"name":"Test Kitchen","currency_code":"USD","currency_symbol":"$",
  "tax_rate":10,"tax_inclusive":false,"service_charge_rate":5,"setup_complete":true}' >/dev/null

STAFF=$(post staff '{"name":"Owner","username":"owner","role":"owner","active":true,
  "password":"1234","passwordConfirm":"1234"}' | jq -r .id)
CAT=$(post categories '{"name":"Mains","active":true,"sort_order":1}' | jq -r .id)
ITEM=$(post menu_items "{\"category\":\"${CAT}\",\"name\":\"Steak\",\"price\":100,\"active\":true,\"available\":true}" | jq -r .id)
TABLE=$(post tables '{"label":"T1","seats":4,"status":"free","active":true}' | jq -r .id)

echo
echo "Order numbering"
O1=$(post orders "{\"type\":\"dine_in\",\"table\":\"${TABLE}\",\"staff\":\"${STAFF}\",\"status\":\"open\"}")
check "first order number" "001" "$(echo "$O1" | jq -r .number)"
ORDER=$(echo "$O1" | jq -r .id)
O2=$(post orders "{\"type\":\"takeaway\",\"staff\":\"${STAFF}\",\"status\":\"open\"}")
check "second order number" "002" "$(echo "$O2" | jq -r .number)"

echo
echo "Line totals  (\$100 steak + \$20 cheese) x2"
LINE=$(post order_items "{\"order\":\"${ORDER}\",\"menu_item\":\"${ITEM}\",\"name_snapshot\":\"Steak\",
  \"qty\":2,\"unit_price\":100,\"status\":\"queued\",
  \"modifiers\":[{\"name\":\"Extra cheese\",\"price_delta\":20}]}")
check "modifiers_total" "20" "$(echo "$LINE" | jq -r .modifiers_total)"
check "line_total" "240" "$(echo "$LINE" | jq -r .line_total)"
LINE_ID=$(echo "$LINE" | jq -r .id)

echo
echo "Order rollup  (5% service, then 10% tax)"
R=$(get orders "$ORDER")
check "subtotal" "240" "$(echo "$R" | jq -r .subtotal)"
check "service_amount" "12" "$(echo "$R" | jq -r .service_amount)"
check "tax_amount" "25.2" "$(echo "$R" | jq -r .tax_amount)"
check "total" "277.2" "$(echo "$R" | jq -r .total)"
check "paid" "false" "$(echo "$R" | jq -r .paid)"

echo
echo "Client cannot forge a total"
curl -sf -X PATCH "${API}/collections/orders/records/${ORDER}" \
  -H "Authorization: ${TOKEN}" -H 'Content-Type: application/json' \
  -d '{"total":1,"subtotal":1}' >/dev/null
check "total held" "277.2" "$(get orders "$ORDER" | jq -r .total)"

echo
echo "Payment settles the order"
post payments "{\"order\":\"${ORDER}\",\"method\":\"cash\",\"amount\":277.2,\"staff\":\"${STAFF}\"}" >/dev/null
R=$(get orders "$ORDER")
check "paid_amount" "277.2" "$(echo "$R" | jq -r .paid_amount)"
check "paid" "true" "$(echo "$R" | jq -r .paid)"

echo
echo "Voiding a line rebuilds the bill"
curl -sf -X PATCH "${API}/collections/order_items/records/${LINE_ID}" \
  -H "Authorization: ${TOKEN}" -H 'Content-Type: application/json' \
  -d '{"status":"void","void_reason":"sent back"}' >/dev/null
R=$(get orders "$ORDER")
check "subtotal after void" "0" "$(echo "$R" | jq -r .subtotal)"
check "total after void" "0" "$(echo "$R" | jq -r .total)"

echo
echo "Closing the order frees the table"
curl -sf -X PATCH "${API}/collections/orders/records/${ORDER}" \
  -H "Authorization: ${TOKEN}" -H 'Content-Type: application/json' \
  -d '{"status":"paid"}' >/dev/null
check "table status" "cleaning" "$(get tables "$TABLE" | jq -r .status)"

echo
printf '\033[1m%d passed, %d failed\033[0m\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
