#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
before=$(sha256sum "$root/catalog/icons.json" "$root/catalog/generated-stats.json")
nix run "$root#generate"
after=$(sha256sum "$root/catalog/icons.json" "$root/catalog/generated-stats.json")

if [[ $before != "$after" ]]; then
  printf 'generated catalog is stale; run nix run .#generate\n' >&2
  exit 1
fi
