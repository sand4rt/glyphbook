#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  printf 'usage: generate MINI_NVIM_CHECKOUT GLYPHNAMES_JSON SIMPLE_ICONS_JSON\n' >&2
  exit 2
fi

root=${GLYPHBOOK_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
mini=$1
glyphnames=$2
simple_icons=$3
resolver=${GLYPHBOOK_RESOLVER:-}
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT

compact_single_item_arrays() {
  sed '
    /^[[:space:]]*"[^"]*": \[$/ {
      N
      N
      s/^\([[:space:]]*"[^"]*":\) \[\n[[:space:]]*\(.*\)\n\([[:space:]]*\)\]\(,\{0,1\}\)$/\1 [ \2 ]\4/
    }
  '
}

format_catalog() {
  local input=$1
  local -a icons
  local icon inline formatted
  local index

  mapfile -t icons < <(jq -c '.icons[]' "$input")
  printf '{\n  "schemaVersion": %s,\n  "icons": [\n' "$(jq -r '.schemaVersion' "$input")"

  for index in "${!icons[@]}"; do
    icon=${icons[index]}
    inline=$(printf '%s\n' "$icon" | sed 's/{/{ /; s/}/ }/; s/\[/[ /g; s/\]/ ]/g; s/:/: /g; s/,/, /g')
    if (( ${#inline} + 4 <= 90 )); then
      printf '    %s' "$inline"
    else
      formatted=$(printf '%s\n' "$icon" | jq . | compact_single_item_arrays)
      printf '%s' "$formatted" | sed 's/^/    /'
    fi

    if (( index + 1 < ${#icons[@]} )); then
      printf ','
    fi
    printf '\n'
  done

  printf '  ]\n}\n'
}

generate_lookup_index() {
  if [[ -z $resolver ]]; then
    return
  fi

  jq -c '.icons[]' "$root/catalog/icons.json" > "$temporary/icons.records.jsonl"
  jq -r '
    .icons | to_entries[]
    | .key as $record
    | .value
    | ([.applications[]? | ["application", ., $record]] +
       [.defaults[]? | ["default", ., $record]] +
       [.directories[]? | ["directory", ., $record]] +
       [.extensions[]? | ["extension", ., $record]] +
       [.files[]? | ["file", ., $record]] +
       [.editorFiletypes[]? | ["editor-filetype", ., $record]] +
       [.lsp[]? | ["lsp", ., $record]] +
       [.operatingSystems[]? | ["os", ., $record]] +
       [.domains[]? | if . == "*" then ["website-fallback", ., $record]
         elif startswith("*.") then ["website-wildcard", .[2:], $record]
         else ["website", ., $record]
         end])[]
    | @tsv
  ' "$root/catalog/icons.json" > "$temporary/icons.matchers.tsv"
  "$resolver" --build "$temporary/icons.records.jsonl" "$temporary/icons.matchers.tsv" "$temporary/icons.index"
  mv "$temporary/icons.records.jsonl" "$root/catalog/icons.records.jsonl"
  mv "$temporary/icons.index" "$root/catalog/icons.index"
}

GLYPHBOOK_MINI_NVIM=$mini \
GLYPHBOOK_MINI_OUTPUT=$temporary/mini.json \
  nvim --clean --headless -l "$root/scripts/export-mini-icons.lua"

jq '
  def slug: ascii_downcase | gsub("[^a-z0-9]"; "");
  map({ key: (.title | slug), value: ("#" + .hex) }) | from_entries
' "$simple_icons" > "$temporary/simple-colors.json"

jq '
  to_entries
  | map(select(.key != "METADATA"))
  | map({ key: .value.char, value: .key })
  | map(select(.key != null))
  | group_by(.key)
  | map({ key: .[0].key, value: (map(.value) | unique) })
  | from_entries
' "$glyphnames" > "$temporary/nerd-font-names.json"

jq \
  --slurpfile mini "$temporary/mini.json" \
  --slurpfile names "$temporary/nerd-font-names.json" \
  --slurpfile catalog "$root/catalog/icons.json" \
  --slurpfile colors "$temporary/simple-colors.json" '
  def values($field): [.[].[$field][]?] | unique;
  def domains:
    values("domains")
    | sort_by(if . == "*" then 2 elif startswith("*.") then 1 else 0 end);
   def semantic_matcher:
     .applications? or .symbols? or .domains? or .defaults? or .directories?
     or .extensions? or .files? or .editorFiletypes? or .lsp? or .operatingSystems?;
   def is_fallback_color:
     .dark == "#8B949E" and .light == "#8B949E";
   def explicit_colors:
     map(select(.color | is_fallback_color | not) | { key: .glyph, value: .color })
     | from_entries;
   def simple_icon_color:
     [
       .nerdFontNames[]?
       | sub("^(dev|fa|fae|seti|cod|linux|md)-"; "")
       | gsub("_"; "")
       | ascii_downcase
       | $colors[0][.]
     ]
     | first
     | if . then { dark: ., light: . } else empty end;
   def merge_by_glyph:
    group_by(.glyph)
    | map(
        . as $group
        | {
            glyph: $group[0].glyph,
            color: ([ $group[] | .color? | select(.) ] | first),
            colorRole: ([ $group[] | .colorRole? | select(.) ] | first),
            nerdFontNames: ($group | values("nerdFontNames")),
            applications: ($group | values("applications")),
            symbols: ($group | values("symbols")),
            domains: ($group | domains),
            defaults: ($group | values("defaults")),
            directories: ($group | values("directories")),
            extensions: ($group | values("extensions")),
            files: ($group | values("files")),
            editorFiletypes: ($group | values("editorFiletypes")),
            lsp: ($group | values("lsp")),
            operatingSystems: ($group | values("operatingSystems"))
          }
        | .color = (
            if (.color | type) == "object" then .color
            elif (.color | type) == "string" then { dark: .color, light: .color }
            else { dark: "#8B949E", light: "#8B949E" }
            end
          )
        | with_entries(select(.value != [] and .value != null))
      );
   ($catalog[0].icons | explicit_colors) as $explicit_colors
   | (($names[0] | to_entries | map({ glyph: .key, nerdFontNames: .value })) +
      [$catalog[0].icons[] | select(semantic_matcher)] + $mini[0] | merge_by_glyph)
   | map(. + { nerdFontNames: ((.nerdFontNames // []) + ($names[0][.glyph] // []) | unique) })
   | map(.color = (simple_icon_color // .color))
   | map(.color = ($explicit_colors[.glyph] // .color))
   | map(with_entries(select(.value != [] and .value != null)))
  | { schemaVersion: 2, icons: . }
' "$root/catalog/icons.json" > "$temporary/icons.unformatted.json"

format_catalog "$temporary/icons.unformatted.json" > "$temporary/icons.json"

mv "$temporary/icons.json" "$root/catalog/icons.json"
generate_lookup_index

jq -n \
  --slurpfile catalog "$root/catalog/icons.json" \
  --slurpfile mini "$temporary/mini.json" '
  def count($field): [$catalog[0].icons[][$field][]?] | length;
  {
    uniqueGlyphs: ($catalog[0].icons | length),
    nerdFontNames: count("nerdFontNames"),
    miniIcons: {
      default: count("defaults"),
      directory: count("directories"),
      extension: count("extensions"),
      file: count("files"),
       editorFiletype: count("editorFiletypes"),
      lsp: count("lsp"),
      os: count("operatingSystems")
    },
    websites: count("domains")
  }
' | compact_single_item_arrays > "$root/catalog/generated-stats.json"
