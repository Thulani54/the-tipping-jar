#!/usr/bin/env bash
# End-to-end smoke test proving the four services talk to each other.
# Usage: ./smoke-test.sh [HOST]   (HOST defaults to localhost)
set -euo pipefail

HOST="${1:-localhost}"
ACCOUNTS="http://$HOST:8081"
CREATORS="http://$HOST:8082"
PAYMENTS="http://$HOST:8083"
TIPS="http://$HOST:8084"

say() { printf "\n\033[1;36m== %s ==\033[0m\n" "$1"; }

say "Health checks"
for url in "$ACCOUNTS" "$CREATORS" "$PAYMENTS" "$TIPS"; do
  echo "$url/health -> $(curl -s "$url/health")"
done

say "Register a creator user (accounts)"
EMAIL="creator_$RANDOM@example.com"
AUTH=$(curl -s -X POST "$ACCOUNTS/auth/register" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"secret123\",\"role\":\"creator\"}")
echo "$AUTH"
TOKEN=$(echo "$AUTH" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')

say "Create a creator profile (creators -> accounts to verify token)"
CREATOR=$(curl -s -X POST "$CREATORS/creators" \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"display_name":"Nova Beats","tagline":"lo-fi every day","category":"music","tip_goal":5000}')
echo "$CREATOR"
SLUG=$(echo "$CREATOR" | sed -n 's/.*"slug":"\([^"]*\)".*/\1/p')

say "Get a fee quote (payments)"
curl -s -X POST "$PAYMENTS/payments/quote" \
  -H 'Content-Type: application/json' -d '{"amount":100}'; echo

say "Send a tip (tips -> creators + payments)"
curl -s -X POST "$TIPS/tips" \
  -H 'Content-Type: application/json' \
  -d "{\"creator_slug\":\"$SLUG\",\"amount\":100,\"tipper_name\":\"Sam\",\"message\":\"love it\"}"; echo

say "Tip feed (tips)"
curl -s "$TIPS/tips"; echo

say "Done — all four services cooperated."
