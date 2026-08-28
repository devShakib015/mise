#!/usr/bin/env bash
# Checks that bills settle themselves when the money adds up, that partial
# payments accumulate, that discounts feed through, and that a cancelled bill
# refuses to take any more money.
set -euo pipefail

cd "$(dirname "$0")/.."

PORT=8095
API="http://127.0.0.1:${PORT}/api"
DATA="./pb_payments_test_data"
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
./bin/pocketbase serve --dir="$DATA" --migrationsDir=./pb_migrations --hooksDir=./pb_hooks --publicDir=./pb_public \
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
code()  { curl -s -o /dev/null -w '%{http_code}' -X POST "${API}/collections/$1/records" \
  -H "Authorization: ${TOKEN}" -H 'Content-Type: application/json' -d "$2"; }
patch() { curl -sf -X PATCH "${API}/collections/$1/records/$2" \
  -H "Authorization: ${TOKEN}" -H 'Content-Type: application/json' -d "$3"; }
get()   { curl -sf "${API}/collections/$1/records/$2" -H "Authorization: ${TOKEN}"; }

# No tax or service, so the arithmetic under test is only the payments.
post restaurant '{"name":"Test","currency_code":"USD","currency_symbol":"$",
  "tax_rate":0,"service_charge_rate":0,"setup_complete":true}' >/dev/null
STAFF=$(post staff '{"name":"Till","username":"till","role":"cashier","active":true,
  "password":"1234","passwordConfirm":"1234"}' | jq -r .id)
CAT=$(post categories '{"name":"Mains","active":true}' | jq -r .id)
ITEM=$(post menu_items "{\"category\":\"${CAT}\",\"name\":\"Soup\",\"price\":100,\"active\":true,\"available\":true}" | jq -r .id)
TABLE=$(post tables '{"label":"T9","seats":4,"status":"free","active":true}' | jq -r .id)

newBill() { # newBill <qty> -> orderId
  local oid=$(post orders "{\"type\":\"dine_in\",\"table\":\"${TABLE}\",\"staff\":\"${STAFF}\",\"status\":\"sent\"}" | jq -r .id)
  post order_items "{\"order\":\"${oid}\",\"menu_item\":\"${ITEM}\",\"name_snapshot\":\"Soup\",
    \"qty\":$1,\"unit_price\":100,\"status\":\"queued\"}" >/dev/null
  echo "$oid"
}

echo "A part payment leaves the bill open"
O=$(newBill 3)
check "total" "300" "$(get orders "$O" | jq -r .total)"
post payments "{\"order\":\"${O}\",\"method\":\"cash\",\"amount\":100,\"staff\":\"${STAFF}\"}" >/dev/null
R=$(get orders "$O")
check "paid_amount" "100" "$(echo "$R" | jq -r .paid_amount)"
check "paid" "false" "$(echo "$R" | jq -r .paid)"
check "still in service" "sent" "$(echo "$R" | jq -r .status)"

echo
echo "The payment that covers it settles the bill"
post payments "{\"order\":\"${O}\",\"method\":\"card\",\"amount\":200,\"staff\":\"${STAFF}\"}" >/dev/null
R=$(get orders "$O")
check "paid" "true" "$(echo "$R" | jq -r .paid)"
check "status" "paid" "$(echo "$R" | jq -r .status)"
check "closed_at set" "true" "$(echo "$R" | jq -r 'if (.closed_at // "") != "" then "true" else "false" end')"
check "table released" "cleaning" "$(get tables "$TABLE" | jq -r .status)"

echo
echo "A discount feeds through to what is owed"
O2=$(newBill 4)
check "before discount" "400" "$(get orders "$O2" | jq -r .total)"
patch orders "$O2" '{"discount_amount":150,"discount_reason":"Staff meal"}' >/dev/null
check "after discount" "250" "$(get orders "$O2" | jq -r .total)"
post payments "{\"order\":\"${O2}\",\"method\":\"cash\",\"amount\":250,\"staff\":\"${STAFF}\"}" >/dev/null
check "settles at the discounted total" "paid" "$(get orders "$O2" | jq -r .status)"

echo
echo "A discount can never exceed the bill"
O3=$(newBill 1)
patch orders "$O3" '{"discount_amount":9999}' >/dev/null
R=$(get orders "$O3")
check "discount capped at subtotal" "100" "$(echo "$R" | jq -r .discount_amount)"
check "total floors at zero" "0" "$(echo "$R" | jq -r .total)"

echo
echo "Bad payments are refused"
O4=$(newBill 1)
check "zero amount" "400" "$(code payments "{\"order\":\"${O4}\",\"method\":\"cash\",\"amount\":0,\"staff\":\"${STAFF}\"}")"
check "negative amount" "400" "$(code payments "{\"order\":\"${O4}\",\"method\":\"cash\",\"amount\":-50,\"staff\":\"${STAFF}\"}")"
patch orders "$O4" '{"status":"cancelled"}' >/dev/null
check "against a cancelled bill" "400" "$(code payments "{\"order\":\"${O4}\",\"method\":\"cash\",\"amount\":100,\"staff\":\"${STAFF}\"}")"

echo
echo "Overpaying still settles, and records what was taken"
O5=$(newBill 1)
post payments "{\"order\":\"${O5}\",\"method\":\"cash\",\"amount\":100,\"tendered\":500,\"change_due\":400,\"staff\":\"${STAFF}\"}" >/dev/null
R=$(get orders "$O5")
check "status" "paid" "$(echo "$R" | jq -r .status)"
check "paid_amount is the bill" "100" "$(echo "$R" | jq -r .paid_amount)"

echo
printf '\033[1m%d passed, %d failed\033[0m\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
