#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
old_lock=$1
report=${2:-$root/update-report.md}

revision() {
  jq -r --arg input "$1" '.nodes[$input].locked.rev // .nodes[$input].locked.narHash // .nodes[$input].locked.url // "unknown"' "$2"
}

{
  printf '# Catalog update\n\n'
  printf '| Source | Before | After |\n'
  printf '| --- | --- | --- |\n'
  for input in mini-nvim nerd-fonts simple-icons; do
    printf '| %s | `%s` | `%s` |\n' "$input" "$(revision "$input" "$old_lock")" "$(revision "$input" "$root/flake.lock")"
  done
  printf '\n## Generated statistics\n\n```json\n'
  jq . "$root/catalog/generated-stats.json"
  printf '```\n'
} > "$report"
