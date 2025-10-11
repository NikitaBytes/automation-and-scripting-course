#!/usr/bin/env bash
set -euo pipefail
: "${API_KEY:?API_KEY is required}"

BASE_URL="${LAB02_BASE_URL:-http://host.docker.internal:8080/}"
FROM="MDL"
TO="USD"

# Определяем диапазон прошлой недели
start=$(date -d 'last week monday' +%F)
end=$(date -d 'last week sunday' +%F)
cur="$start"

while [[ "$cur" != "$(date -d "$end + 1 day" +%F)" ]]; do
  python3 /opt/lab03/currency_exchange_rate.py --from "$FROM" --to "$TO" --date "$cur" \
  --api-key "$API_KEY" --base-url "$BASE_URL" >> /var/log/cron.log 2>&1
  cur=$(date -d "$cur + 1 day" +%F)
done