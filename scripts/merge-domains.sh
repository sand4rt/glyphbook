#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  printf 'usage: merge-domains CATALOG_JSON CANDIDATES_JSON\n' >&2
  exit 2
fi

catalog=$1
candidates=$2
temporary=$(mktemp "${catalog}.XXXXXX")
trap 'rm -f "$temporary"' EXIT

jq --slurpfile candidates "$candidates" '
  def neutral_color:
    .dark == "#8B949E" and .light == "#8B949E";
  def valid_domain:
    test("^(\\*|(?:\\*\\.)?(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\\.)*[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)$");
  def candidate_error($message): error("invalid domain candidate: " + $message);

  . as $catalog
  | ($candidates[0].candidates // candidate_error("missing candidates array")) as $proposals
  | ([.icons[].domains[]?]) as $claimed
  | ([$proposals[].proposedDomains[]?]) as $proposed_domains
  | if ($proposals | type) != "array" then candidate_error("candidates must be an array")
    elif any($proposals[]; (.glyph | type) != "string" or (.glyph | length) == 0) then candidate_error("candidate glyph is required")
    elif any($proposals[]; (.color | type) != "string" or (.color | test("^#[0-9A-Fa-f]{6}$") | not)) then candidate_error("candidate color must be #RRGGBB")
    elif any($proposals[]; (.proposedDomains | type) != "array" or (.proposedDomains | length) == 0) then candidate_error("candidate proposedDomains is required")
    elif any($proposed_domains[]; (type != "string") or (valid_domain | not) or . == "*") then candidate_error("domain must be an exact host or wildcard suffix")
    elif ($proposed_domains | length) != ($proposed_domains | unique | length) then candidate_error("duplicate domain in candidate file")
    elif any($proposed_domains[]; . as $domain | ($claimed | index($domain))) then candidate_error("domain is already owned by the catalog")
    elif any($proposals[]; .glyph as $glyph | ([$catalog.icons[] | select(.glyph == $glyph)] | length) != 1) then candidate_error("candidate glyph must match exactly one catalog record")
    elif any($proposals | group_by(.glyph)[]; ([.[].color] | unique | length) != 1) then candidate_error("candidate glyph has conflicting colors")
    else .
    end
  | .icons |= map(
      . as $icon
      | [$proposals[] | select(.glyph == $icon.glyph)] as $matches
      | if ($matches | length) == 0 then .
        else
          ($matches | map(.proposedDomains[]) | unique | sort_by(if startswith("*.") then 1 else 0 end)) as $domains
          | ($matches[0].color) as $color
          | .domains = ((.domains // []) + $domains | unique | sort_by(if . == "*" then 2 elif startswith("*.") then 1 else 0 end))
          | if .color | neutral_color then .color = { dark: $color, light: $color } else . end
        end
    )
' "$catalog" > "$temporary"

mv "$temporary" "$catalog"
