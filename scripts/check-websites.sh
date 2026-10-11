#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
report=${1:-$root/website-health.md}

{
  printf '# Website health\n\n'
  printf '| Domain | Status | Effective URL |\n'
  printf '| --- | ---: | --- |\n'
  jq -r '.icons[].domains[]? | select(. != "*" and (startswith("*.") | not) and contains("."))' \
    "$root/catalog/icons.json" | sort -u | while IFS= read -r domain; do
      if ! result=$(curl --location --silent --show-error --max-time 15 \
        --output /dev/null --write-out '%{http_code}\t%{url_effective}' "https://$domain" 2>/dev/null); then
        result=$'000\t'"https://$domain"
      fi
      status=${result%%$'\t'*}
      effective=${result#*$'\t'}
      printf '| `%s` | %s | `%s` |\n' "$domain" "$status" "$effective"
    done
} > "$report"
