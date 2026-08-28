#!/usr/bin/env bash
# Checks the table-side ordering routes: that a guest sees only what is on the
# menu, that every price is taken from the database rather than the request,
# and that a stranger on the wi-fi cannot put food straight on the pass.
set -euo pipefail

cd "$(dirname "$0")/.."

PORT=8098
API="http://127.0.0.1:${PORT}/api"
DATA="./pb_guest_test_data"
SU_EMAIL="test@local.test"
SU_PASS="testpassword123"

pass=0; fail=0
check() {
  if [ "$2" = "$3" ]; then
    printf '  \033[32mok\033[0m   %-40s %s\n' "$1" "$3"; pass=$((pass+1))
  else
    printf '  \033[31mFAIL\033[0m %-40s expected %s, got %s\n' "$1" "$2" "$3"; fail=$((fail+1))
  fi
}

cleanup() { pkill -f "pocketbase serve --dir=${DATA}" 2>/dev/null || true; rm -rf "$DATA"; }
trap cleanup EXIT

rm -rf "$DATA"
./bin/pocketbase migrate up --dir="$DATA" --migrationsDir=./pb_migrations >/dev/null
./bin/pocketbase superuser upsert "$SU_EMAIL" "$SU_PASS" --dir="$DATA" >/dev/null 2>&1
./bin/pocketbase serve --dir="$DATA" --migrationsDir=./pb_migrations --hooksDir=./pb_hooks \
  --http="127.0.0.1:${PORT}" >/dev/null 2>&1 &

for _ in $(seq 1 40); do curl -sf "${API}/health" >/dev/null 2>&1 && break; sleep 0.25; done

T=$(curl -sf -X POST "${API}/collections/_superusers/auth-with-password" \
  -H 'Content-Type: application/json' \
  -d "{\"identity\":\"${SU_EMAIL}\",\"password\":\"${SU_PASS}\"}" | jq -r .token)
post() { curl -sf -X POST "${API}/collections/$1/records" -H "Authorization: ${T}" \
  -H 'Content-Type: application/json' -d "$2"; }

post restaurant '{"name":"The Ember","currency_code":"BDT","currency_symbol":"Tk",
  "tax_rate":5,"service_charge_rate":10,"setup_complete":true}' >/dev/null
CAT=$(post categories '{"name":"Mains","active":true}' | jq -r .id)
ON=$(post menu_items "{\"category\":\"${CAT}\",\"name\":\"Sea bass\",\"price\":850,\"active\":true,\"available\":true}" | jq -r .id)
OFF=$(post menu_items "{\"category\":\"${CAT}\",\"name\":\"Sold out dish\",\"price\":500,\"active\":true,\"available\":false}" | jq -r .id)
HIDDEN=$(post menu_items "{\"category\":\"${CAT}\",\"name\":\"Secret\",\"price\":100,\"active\":false,\"available\":true}" | jq -r .id)
TABLE=$(post tables '{"label":"T4","seats":4,"status":"free","active":true}' | jq -r .id)
GONE=$(post tables '{"label":"T99","seats":2,"status":"free","active":false}' | jq -r .id)

SIZE=$(post modifier_groups '{"name":"Choose a size","min_select":1,"max_select":1,"required":true}' | jq -r .id)
LARGE=$(post modifiers "{\"group\":\"${SIZE}\",\"name\":\"Large\",\"price_delta\":150,\"active\":true}" | jq -r .id)
OTHER=$(post modifier_groups '{"name":"Unrelated","min_select":0,"max_select":1,"required":false}' | jq -r .id)
CHEAP=$(post modifiers "{\"group\":\"${OTHER}\",\"name\":\"Discount\",\"price_delta\":-800,\"active\":true}" | jq -r .id)
post menu_item_modifiers "{\"menu_item\":\"${ON}\",\"modifier_group\":\"${SIZE}\"}" >/dev/null

# Bodies are written with a heredoc rather than passed as an argument. Nesting
# escaped quotes through command substitution mangles the JSON before curl ever
# sees it, and every request then fails for the wrong reason.
BODY=/tmp/guest_body.json
order() {
  curl -s -o /tmp/g.json -w '%{http_code}' -X POST "${API}/app/guest-order" \
    -H 'Content-Type: application/json' --data-binary @"$BODY"
}

echo "The menu a guest sees"
M=$(curl -s "${API}/app/menu")
check "venue name" "The Ember" "$(echo "$M" | jq -r .restaurant.name)"
check "hidden items are not listed" "false" "$(echo "$M" | jq --arg i "$HIDDEN" 'any(.items[]; .id==$i)')"
check "sold-out items ARE listed" "true" "$(echo "$M" | jq --arg i "$OFF" 'any(.items[]; .id==$i)')"
check "and marked unavailable" "false" "$(echo "$M" | jq --arg i "$OFF" '.items[]|select(.id==$i)|.available')"
check "no cost or stock fields leak" "null" "$(echo "$M" | jq -r '.items[0].sku')"
check "takings are not exposed" "null" "$(echo "$M" | jq -r '.restaurant.tax_rate')"

echo
echo "Scanning a code"
check "a real table resolves" "T4" "$(curl -s "${API}/app/table/${TABLE}" | jq -r .label)"
check "a retired table does not" "404" "$(curl -s -o /dev/null -w '%{http_code}' "${API}/app/table/${GONE}")"
check "a made-up code does not" "404" "$(curl -s -o /dev/null -w '%{http_code}' "${API}/app/table/nonsense")"

echo
echo "Ordering"
cat > "$BODY" <<JSON
{"table":"${TABLE}","items":[]}
JSON
check "empty order refused" "400" "$(order)"

cat > "$BODY" <<JSON
{"table":"${TABLE}","items":[{"item_id":"${OFF}","qty":1}]}
JSON
check "sold-out item refused" "400" "$(order)"

cat > "$BODY" <<JSON
{"table":"${TABLE}","items":[{"item_id":"${HIDDEN}","qty":1}]}
JSON
check "hidden item refused" "400" "$(order)"

cat > "$BODY" <<JSON
{"table":"${TABLE}","items":[{"item_id":"${ON}","qty":999}]}
JSON
check "silly quantity refused" "400" "$(order)"

cat > "$BODY" <<JSON
{"table":"${TABLE}","items":[{"item_id":"${ON}","qty":1}]}
JSON
check "missing required choice refused" "400" "$(order)"

cat > "$BODY" <<JSON
{"table":"${TABLE}","items":[{"item_id":"${ON}","qty":1,"modifiers":["${LARGE}","${CHEAP}"]}]}
JSON
check "unrelated modifier refused" "400" "$(order)"

echo
echo "A good order"
cat > "$BODY" <<JSON
{"table":"${TABLE}","items":[{"item_id":"${ON}","qty":2,"modifiers":["${LARGE}"],"note":"no chilli"}]}
JSON
check "accepted" "200" "$(order)"
OID=$(curl -sf -G "${API}/collections/orders/records" -H "Authorization: ${T}" \
  --data-urlencode "filter=table='${TABLE}'" | jq -r '.items[0].id')
check "priced from the database" "2000" "$(curl -sf "${API}/collections/orders/records/${OID}" -H "Authorization: ${T}" | jq -r .subtotal)"
check "the bill is open, not sent" "open" "$(curl -sf "${API}/collections/orders/records/${OID}" -H "Authorization: ${T}" | jq -r .status)"
check "nothing reached the kitchen" "0" \
  "$(curl -sf -G "${API}/collections/order_items/records" -H "Authorization: ${T}" \
     --data-urlencode "filter=order='${OID}' && sent_at != null" | jq -r '.items|length')"
check "the table shows as occupied" "occupied" "$(curl -sf "${API}/collections/tables/records/${TABLE}" -H "Authorization: ${T}" | jq -r .status)"

echo
echo "A second round joins the same bill"
cat > "$BODY" <<JSON
{"table":"${TABLE}","items":[{"item_id":"${ON}","qty":1,"modifiers":["${LARGE}"]}]}
JSON
check "accepted" "200" "$(order)"
check "still one bill" "1" \
  "$(curl -sf -G "${API}/collections/orders/records" -H "Authorization: ${T}" \
     --data-urlencode "filter=table='${TABLE}'" | jq -r '.items|length')"
check "total grew" "3000" "$(curl -sf "${API}/collections/orders/records/${OID}" -H "Authorization: ${T}" | jq -r .subtotal)"

echo
echo "A guest cannot reach anything else"
check "collections stay staff-only" "0" \
  "$(curl -s "${API}/collections/menu_items/records" | jq -r '.items|length // 0')"
check "staff are not readable" "0" \
  "$(curl -s "${API}/collections/staff/records" | jq -r '.items|length // 0')"
check "takings are not readable" "0" \
  "$(curl -s "${API}/collections/payments/records" | jq -r '.items|length // 0')"

echo
printf '\033[1m%d passed, %d failed\033[0m\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
