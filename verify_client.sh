#!/usr/bin/env bash
set -euo pipefail

URL="${1:-https://uptimeproof.io/poa/v1/verify}"

if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl not found" >&2
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq not found" >&2
  exit 2
fi

JSON="$(curl -fsS --connect-timeout 5 --max-time 10 "$URL")"

VERDICT="$(jq -r '.verdict // ""' <<<"$JSON")"
V2="$(jq -r '.verification.verdict // ""' <<<"$JSON")"
DNS_LAG_OK="$(jq -r '.verification.checks.dns_lag_ok // false' <<<"$JSON")"
NOT_EXPIRED="$(jq -r '.verification.checks.not_expired // false' <<<"$JSON")"
MSG="$(jq -r '.message // ""' <<<"$JSON")"

if [[ "$VERDICT" == "OK" && "$V2" == "VALID" && "$DNS_LAG_OK" == "true" && "$NOT_EXPIRED" == "true" ]]; then
  echo "UP - $MSG"
  exit 0
else
  echo "DOWN - verdict=$VERDICT verification=$V2 dns_lag_ok=$DNS_LAG_OK not_expired=$NOT_EXPIRED - $MSG"
  exit 1
fi
