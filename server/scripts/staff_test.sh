#!/usr/bin/env bash
# Checks staff administration: that a manager can reset a forgotten PIN without
# the admin dashboard, that a manager cannot seize an owner's account by doing
# so, and that the venue can never be left with no owner.
set -euo pipefail

cd "$(dirname "$0")/.."

PORT=8096
API="http://127.0.0.1:${PORT}/api"
DATA="./pb_staff_test_data"

pass=0; fail=0
check() {
  if [ "$2" = "$3" ]; then
    printf '  \033[32mok\033[0m   %-38s %s\n' "$1" "$3"; pass=$((pass+1))
  else
    printf '  \033[31mFAIL\033[0m %-38s expected %s, got %s\n' "$1" "$2" "$3"; fail=$((fail+1))
  fi
}

cleanup() { pkill -f "pocketbase serve --dir=${DATA}" 2>/dev/null || true; rm -rf "$DATA"; }
trap cleanup EXIT

rm -rf "$DATA"
./bin/pocketbase migrate up --dir="$DATA" --migrationsDir=./pb_migrations >/dev/null
./bin/pocketbase serve --dir="$DATA" --migrationsDir=./pb_migrations --hooksDir=./pb_hooks \
  --http="127.0.0.1:${PORT}" >/dev/null 2>&1 &

for _ in $(seq 1 40); do
  curl -sf "${API}/health" >/dev/null 2>&1 && break
  sleep 0.25
done

# Bootstrap gives us the first owner without needing a superuser.
curl -sf -X POST "${API}/app/bootstrap" -H 'Content-Type: application/json' -d '{
  "restaurant_name":"The Ember","owner_name":"Owner","owner_username":"owner",
  "owner_pin":"1111","currency_code":"USD","currency_symbol":"$"}' >/dev/null

login() { curl -s -X POST "${API}/collections/staff/auth-with-password" \
  -H 'Content-Type: application/json' -d "{\"identity\":\"$1\",\"password\":\"$2\"}"; }

OWNER_TOKEN=$(login owner 1111 | jq -r .token)
OWNER_ID=$(login owner 1111 | jq -r .record.id)

mk() { # mk <token> <username> <role> -> id
  curl -s -X POST "${API}/collections/staff/records" -H "Authorization: $1" \
    -H 'Content-Type: application/json' \
    -d "{\"name\":\"$2\",\"username\":\"$2\",\"role\":\"$3\",\"active\":true,
        \"password\":\"1111\",\"passwordConfirm\":\"1111\"}" | jq -r .id
}
resetPin() { # resetPin <token> <staffId> <pin> -> http code
  curl -s -o /tmp/rp.json -w '%{http_code}' -X POST "${API}/app/staff/reset-pin" \
    -H "Authorization: $1" -H 'Content-Type: application/json' \
    -d "{\"staff_id\":\"$2\",\"pin\":\"$3\"}"
}

MANAGER=$(mk "$OWNER_TOKEN" manager manager)
WAITER=$(mk "$OWNER_TOKEN" waiter waiter)
MANAGER_TOKEN=$(login manager 1111 | jq -r .token)
WAITER_TOKEN=$(login waiter 1111 | jq -r .token)

echo "A manager can reset a forgotten PIN"
check "reset accepted" "200" "$(resetPin "$MANAGER_TOKEN" "$WAITER" 9876)"
check "old PIN stops working" "false" "$(login waiter 1111 | jq -r 'if .token then "true" else "false" end')"
check "new PIN works" "true" "$(login waiter 9876 | jq -r 'if .token then "true" else "false" end')"
check "it is written down" "reset_pin" \
  "$(curl -s -G "${API}/collections/audit_log/records" -H "Authorization: $OWNER_TOKEN" \
     --data-urlencode "filter=action='reset_pin'" | jq -r '.items[0].action // "none"')"

# Measured, not assumed: after a reset the holder's existing access token keeps
# working until it expires, but auth-refresh returns 401 so the session cannot
# be extended. The app calls authRefresh() on boot, so that terminal is bounced
# at next start. Not asserted here because the immediate behaviour is a
# PocketBase internal we should not pin down.
check "the old session cannot be extended" "401" \
  "$(curl -s -o /dev/null -w '%{http_code}' -X POST \
     "${API}/collections/staff/auth-refresh" -H "Authorization: $WAITER_TOKEN")"
WAITER_TOKEN=$(login waiter 9876 | jq -r .token)

echo
echo "A PIN reset cannot be used to climb"
check "a waiter cannot reset anyone" "403" "$(resetPin "$WAITER_TOKEN" "$MANAGER" 5555)"
check "signed out cannot reset anyone" "401" "$(resetPin "" "$WAITER" 5555)"
check "a short PIN is refused" "400" "$(resetPin "$OWNER_TOKEN" "$WAITER" 12)"
check "manager cannot reset an owner" "403" "$(resetPin "$MANAGER_TOKEN" "$OWNER_ID" 5555)"
check "owner can reset an owner" "200" "$(resetPin "$OWNER_TOKEN" "$OWNER_ID" 2222)"
# That reset invalidated our own session; sign back in with the new PIN.
OWNER_TOKEN=$(login owner 2222 | jq -r .token)
check "owner signs back in with the new PIN" "true" \
  "$(if [ -n "$OWNER_TOKEN" ] && [ "$OWNER_TOKEN" != "null" ]; then echo true; else echo false; fi)"

echo
echo "The venue can never be left without an owner"
patch() { curl -s -o /tmp/p.json -w '%{http_code}' -X PATCH "${API}/collections/staff/records/$2" \
  -H "Authorization: $1" -H 'Content-Type: application/json' -d "$3"; }

check "the only owner cannot be demoted" "400" "$(patch "$OWNER_TOKEN" "$OWNER_ID" '{"role":"manager"}')"
check "the only owner cannot be switched off" "400" "$(patch "$OWNER_TOKEN" "$OWNER_ID" '{"active":false}')"
check "the only owner cannot be deleted" "400" \
  "$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "${API}/collections/staff/records/${OWNER_ID}" -H "Authorization: $OWNER_TOKEN")"

echo
echo "With a second owner, the first is free to go"
SECOND=$(mk "$OWNER_TOKEN" second owner)
check "now demotable" "200" "$(patch "$OWNER_TOKEN" "$OWNER_ID" '{"role":"manager"}')"
check "a non-owner is unaffected by the guard" "200" "$(patch "$OWNER_TOKEN" "$WAITER" '{"active":false}')"

echo
printf '\033[1m%d passed, %d failed\033[0m\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
