#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
catalog=$root/catalog/icons.json

if command -v check-jsonschema >/dev/null; then
  check-jsonschema --schemafile "$root/catalog/schema.json" "$catalog"
fi

jq -e '
  .schemaVersion == 2 and
  (.icons | length > 3000) and
  ([.icons[].glyph] | length == (unique | length)) and
  ([.icons[].nerdFontNames[]?] | length > 3000) and
  ([.icons[] | select(.editorFiletypes) | .editorFiletypes[]] | length >= 971) and
  ([.icons[].domains[]?] | length == (unique | length)) and
  all(.icons[]; (.color.dark | test("^#[0-9A-Fa-f]{6}$")) and (.color.light | test("^#[0-9A-Fa-f]{6}$"))) and
  ([.icons[] | select(.domains? | index("*"))] | length == 1)
' "$catalog" >/dev/null

GLYPHBOOK_CATALOG=$catalog
export GLYPHBOOK_CATALOG
. "$root/adapters/shell/shell.sh"

test "$(icons_get application terminal | jq -r .glyph)" = "󰊠"
icons_get website github.com | jq -e '.domains | index("github.com")' >/dev/null
icons_get website raw.githubusercontent.com | jq -e '.domains | index("raw.githubusercontent.com")' >/dev/null
icons_get website hypr.land | jq -e '.domains | index("hypr.land")' >/dev/null
icons_get website Docs.Google.com | jq -e '.domains | index("docs.google.com")' >/dev/null
icons_get website editorconfig.org | jq -e '.nerdFontNames | index("seti-editorconfig")' >/dev/null
icons_get website firefox.com | jq -e '.applications | index("firefox")' >/dev/null
icons_get website git-scm.com | jq -e '.applications | index("git-dev")' >/dev/null
icons_get website sheets.google.com | jq -e '.applications | index("spreadsheet")' >/dev/null
icons_get website contacts.google.com | jq -e '.applications | index("contacts")' >/dev/null
icons_get website news.google.com | jq -e '.applications | index("news")' >/dev/null
icons_get website qutebrowser.org | jq -e '.applications | index("qutebrowser")' >/dev/null
icons_get website chatgpt.com | jq -e '.nerdFontNames | index("cod-openai")' >/dev/null
icons_get website platform.openai.com | jq -e '.domains | index("*.openai.com")' >/dev/null
icons_get website www.figma.com | jq -e '.domains | index("*.figma.com")' >/dev/null
icons_get website playwright.dev | jq -e '.nerdFontNames | index("md-theater")' >/dev/null
icons_get website app.datadoghq.com | jq -e '.domains | index("*.datadoghq.com")' >/dev/null
icons_get website id.atlassian.com | jq -e '.domains | index("*.atlassian.com")' >/dev/null
icons_get website codeberg.org | jq -e '.domains | index("codeberg.org")' >/dev/null
icons_get website teams.cloud.microsoft | jq -e '.nerdFontNames | index("md-microsoft_teams")' >/dev/null
icons_get website login.microsoftonline.com | jq -e '.nerdFontNames | index("fa-microsoft")' >/dev/null
icons_get website vuejs.org | jq -e '.nerdFontNames | index("dev-vuejs")' >/dev/null
icons_get website guide.vuejs.org | jq -e '.domains | index("*.vuejs.org")' >/dev/null
test "$(icons_get website unknown.example | jq -r .glyph)" = "󰖟"
icons_get website docs.github.com | jq -e '.domains | index("*.github.com")' >/dev/null
test "$(icons_get editor-filetype nix | jq -r .glyph)" = "󱄅"
test "$(icons_get lsp function | jq -r .glyph)" != ""
sh "$root/adapters/shell/glyphbook" get website github.com | jq -e '.domains | index("github.com")' >/dev/null
test "$(sh "$root/adapters/shell/glyphbook" get editor-filetype lua | jq -r .glyph)" != ""
sh "$root/adapters/shell/glyphbook" list application | grep -qx directory
test "$(sh "$root/adapters/shell/glyphbook" file Makefile | jq -r .glyph)" != ""
test "$(sh "$root/adapters/shell/glyphbook" file archive.tar.gz | jq -r .glyph)" != ""

priority_catalog=$(mktemp)
trap 'rm -f "$priority_catalog"' EXIT
jq -n '{icons: [
  {glyph:"F", files:["example.lua"]},
  {glyph:"W", extensions:["tar.gz"]},
  {glyph:"E", extensions:["gz", "lua"]},
  {glyph:"T", editorFiletypes:["lua"]},
  {glyph:"D", defaults:["file"]}
]}' > "$priority_catalog"
GLYPHBOOK_CATALOG=$priority_catalog
test "$(icons_get_file example.lua lua | jq -r .glyph)" = F
test "$(icons_get_file archive.tar.gz lua | jq -r .glyph)" = W
test "$(icons_get_file unknown.lua lua | jq -r .glyph)" = E
test "$(icons_get_file unknown lua | jq -r .glyph)" = T
test "$(icons_get_file unknown | jq -r .glyph)" = D
GLYPHBOOK_CATALOG=$catalog

if [ "${GLYPHBOOK_SKIP_NIX_TEST:-0}" != 1 ]; then
  override=$(nix-instantiate --eval --strict --json -E \
    "(import $root/adapters/nix/nix.nix { colors.\"github.com\" = \"#FFFFFF\"; }).websites" \
    | jq -r '.[] | select(.domains[0] == "github.com") | .color')
  test "$override" = "#FFFFFF"
fi

if command -v lua >/dev/null; then
  luac -p "$root/adapters/lua/lua.lua"
  lua "$root/adapters/lua/lua.test.lua" "$root"
fi
