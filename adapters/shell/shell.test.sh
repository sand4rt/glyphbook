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

jq -e '
  . as $catalog
  | [
      { name: "dev-ember", color: "#E04E39" },
      { name: "dev-angularjs", color: "#E23237" },
      { name: "dev-angular", color: "#0F0F11" },
      { name: "dev-heroku", color: "#430098" },
      { name: "dev-cassandra", color: "#1287B1" },
      { name: "dev-cloudflare", color: "#F38020" },
      { name: "dev-cypressio", color: "#69D3A7" },
      { name: "dev-denojs", color: "#000000" },
      { name: "dev-godot", color: "#478CBF" },
      { name: "dev-jaegertracing", color: "#66CFE3" },
      { name: "dev-maven", color: "#C71A36" },
      { name: "dev-nuxtjs", color: "#00DC82" },
      { name: "dev-oracle", color: "#F80000" },
      { name: "dev-phoenix", color: "#FD4F00" },
      { name: "dev-phpstorm", color: "#000000" },
      { name: "dev-rollup", color: "#EC4A3F" },
      { name: "dev-salesforce", color: "#00A1E0" },
      { name: "dev-solidjs", color: "#2C4F7C" },
      { name: "dev-vitejs", color: "#646CFF" },
      { name: "dev-wasm", color: "#654FF0" },
      { name: "dev-twilio", color: "#F22F46" },
      { name: "fa-github", color: "#181717" },
      { name: "fa-bitbucket", color: "#0052CC" },
      { name: "fa-tumblr", color: "#36465D" },
      { name: "fa-apple", color: "#000000" },
      { name: "fa-medium", color: "#000000" },
      { name: "fa-wikipedia_w", color: "#000000" },
      { name: "fa-paypal", dark: "#003087", light: "#002991" },
      { name: "md-robot_outline", color: "#191919" },
      { name: "dev-adonisjs", color: "#5A45FF" },
      { name: "dev-algolia", color: "#003DFF" },
      { name: "dev-arduino", color: "#00878F" },
      { name: "dev-babel", color: "#F9DC3E" },
      { name: "dev-blender", color: "#E87D0D" },
      { name: "dev-fedora", color: "#51A2DA" },
      { name: "dev-gitbook", color: "#BBDDE5" },
      { name: "dev-opensuse", color: "#73BA25" },
      { name: "dev-postcss", color: "#DD3A0A" },
      { name: "dev-puppeteer", color: "#40B5A4" },
      { name: "dev-qt", color: "#41CD52" },
      { name: "dev-redux", color: "#764ABC" },
      { name: "dev-replit", color: "#F26207" },
      { name: "dev-weblate", color: "#2ECCAA" },
      { name: "dev-chartjs", color: "#FF6384" },
      { name: "dev-duckdb", color: "#FFF000" },
      { name: "dev-gitkraken", color: "#179287" },
      { name: "dev-hoppscotch", color: "#09090B" },
      { name: "dev-mattermost", color: "#0058CC" },
      { name: "dev-newrelic", color: "#1CE783" },
      { name: "dev-ngrok", color: "#1F1E37" },
      { name: "dev-stackblitz", color: "#1269D3" },
      { name: "dev-vscodium", color: "#2F80ED" },
      { name: "dev-zsh", color: "#F15A24" },
      { name: "dev-playwright", color: "#2EAD33" }
    ] as $brands
  | all($brands[]; . as $brand
      | [$catalog.icons[] | select((.nerdFontNames // [] | index($brand.name)) != null)] as $matches
      | ($matches | length) == 1
        and $matches[0].color.dark == ($brand.dark // $brand.color)
        and $matches[0].color.light == ($brand.light // $brand.color)
    )
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
icons_get website playwright.dev | jq -e '.nerdFontNames | index("dev-playwright")' >/dev/null
icons_get website www.phpstorm.com | jq -e '.nerdFontNames | index("dev-phpstorm")' >/dev/null
icons_get website www.cloudflare.com | jq -e '(.nerdFontNames | index("dev-cloudflare")) and .color.dark == "#F38020"' >/dev/null
icons_get website www.jetbrains.com | jq -e '.nerdFontNames | index("dev-jetbrains")' >/dev/null
icons_get website angular.dev | jq -e '(.nerdFontNames | index("dev-angular")) and .color.dark == "#0F0F11"' >/dev/null
icons_get website pypi.org | jq -e '.nerdFontNames | index("dev-pypi")' >/dev/null
icons_get website www.netflix.com | jq -e '(.nerdFontNames | index("md-netflix")) and .color.dark == "#E50914"' >/dev/null
icons_get website app.datadoghq.com | jq -e '.domains | index("*.datadoghq.com")' >/dev/null
icons_get website id.atlassian.com | jq -e '.domains | index("*.atlassian.com")' >/dev/null
icons_get website codeberg.org | jq -e '.domains | index("codeberg.org")' >/dev/null
icons_get website www.adonisjs.com | jq -e '.nerdFontNames | index("dev-adonisjs")' >/dev/null
icons_get website www.algolia.com | jq -e '.nerdFontNames | index("dev-algolia")' >/dev/null
icons_get website www.arduino.cc | jq -e '.nerdFontNames | index("dev-arduino")' >/dev/null
icons_get website docs.gitbook.com | jq -e '.nerdFontNames | index("dev-gitbook")' >/dev/null
icons_get website redux.js.org | jq -e '.nerdFontNames | index("dev-redux")' >/dev/null
icons_get website docs.pptr.dev | jq -e '.nerdFontNames | index("dev-puppeteer")' >/dev/null
icons_get website www.duckdb.org | jq -e '(.nerdFontNames | index("dev-duckdb")) and .color.dark == "#FFF000" and .color.light == "#FFF000"' >/dev/null
icons_get website www.ngrok.com | jq -e '(.nerdFontNames | index("dev-ngrok")) and .color.dark == "#1F1E37" and .color.light == "#1F1E37"' >/dev/null
icons_get website teams.cloud.microsoft | jq -e '.nerdFontNames | index("md-microsoft_teams")' >/dev/null
icons_get website microsoftonline.com | jq -e '.nerdFontNames | index("fa-microsoft")' >/dev/null
icons_get website login.microsoftonline.com | jq -e '.nerdFontNames | index("fa-microsoft")' >/dev/null
icons_get website https://login.microsoftonline.com/ | jq -e '.nerdFontNames | index("fa-microsoft")' >/dev/null
icons_get website learn.microsoft.com | jq -e '.nerdFontNames | index("fa-microsoft")' >/dev/null
icons_get website vssps.dev.azure.com | jq -e '.nerdFontNames | index("md-microsoft_azure_devops")' >/dev/null
icons_get website https://vssps.dev.azure.com/ | jq -e '.nerdFontNames | index("md-microsoft_azure_devops")' >/dev/null
icons_get website 'https://spsprodweu2.vssps.visualstudio.com/_signin?realm=vssps.dev.azure.com' | jq -e '.domains | index("*.visualstudio.com")' >/dev/null
icons_get website typescriptlang.org | jq -e '.nerdFontNames | index("md-language_typescript")' >/dev/null
icons_get website www.typescriptlang.org | jq -e '.domains | index("*.typescriptlang.org")' >/dev/null
icons_get website swift.org | jq -e '.nerdFontNames | index("md-language_swift")' >/dev/null
icons_get website www.swift.org | jq -e '.domains | index("*.swift.org")' >/dev/null
icons_get website php.net | jq -e '.nerdFontNames | index("md-language_php")' >/dev/null
icons_get website go.dev | jq -e '.nerdFontNames | index("md-language_go")' >/dev/null
icons_get website r-project.org | jq -e '.nerdFontNames | index("md-language_r")' >/dev/null
icons_get website lua.org | jq -e '.nerdFontNames | index("md-language_lua")' >/dev/null
icons_get website haskell.org | jq -e '.nerdFontNames | index("md-language_haskell")' >/dev/null
icons_get website ruby-lang.org | jq -e '.nerdFontNames | index("md-language_ruby")' >/dev/null
icons_get website kotlinlang.org | jq -e '.nerdFontNames | index("md-language_kotlin")' >/dev/null
icons_get website fortran-lang.org | jq -e '.nerdFontNames | index("md-language_fortran")' >/dev/null
icons_get website scala-lang.org | jq -e '.nerdFontNames | index("dev-scala")' >/dev/null
icons_get website clojure.org | jq -e '.nerdFontNames | index("dev-clojure")' >/dev/null
icons_get website dart.dev | jq -e '.nerdFontNames | index("dev-dart")' >/dev/null
icons_get website erlang.org | jq -e '.nerdFontNames | index("dev-erlang")' >/dev/null
icons_get website fsharp.org | jq -e '.nerdFontNames | index("dev-fsharp")' >/dev/null
icons_get website python.org | jq -e '.nerdFontNames | index("md-language_python")' >/dev/null
icons_get website rust-lang.org | jq -e '.nerdFontNames | index("md-language_rust")' >/dev/null
icons_get website commonmark.org | jq -e '.nerdFontNames | index("md-language_markdown")' >/dev/null
icons_get website isocpp.org | jq -e '.nerdFontNames | index("md-language_cpp")' >/dev/null
icons_get website java.com | jq -e '.nerdFontNames | index("md-language_java")' >/dev/null
icons_get website store.steampowered.com | jq -e '.nerdFontNames | index("fa-steam")' >/dev/null
icons_get website steamcommunity.com | jq -e '.domains | index("steamcommunity.com")' >/dev/null
icons_get website ghostty.org | jq -e '.nerdFontNames | index("md-ghost")' >/dev/null
icons_get website docs.ghostty.org | jq -e '.domains | index("*.ghostty.org")' >/dev/null
icons_get website earth.google.com | jq -e '.nerdFontNames | index("md-google_earth")' >/dev/null
icons_get website play.google.com | jq -e '.nerdFontNames | index("md-google_play")' >/dev/null
icons_get website translate.google.com | jq -e '.nerdFontNames | index("md-google_translate")' >/dev/null
icons_get website classroom.google.com | jq -e '.nerdFontNames | index("md-google_classroom")' >/dev/null
icons_get website keep.google.com | jq -e '.nerdFontNames | index("md-google_keep")' >/dev/null
icons_get website analytics.google.com | jq -e '.nerdFontNames | index("md-google_analytics")' >/dev/null
icons_get website ads.google.com | jq -e '.nerdFontNames | index("md-google_ads")' >/dev/null
icons_get website cloud.google.com | jq -e '.nerdFontNames | index("md-google_cloud")' >/dev/null
icons_get website chat.google.com | jq -e '.nerdFontNames | index("md-google_hangouts")' >/dev/null
icons_get website hangouts.google.com | jq -e '.domains | index("hangouts.google.com")' >/dev/null
icons_get website jira.atlassian.com | jq -e '.nerdFontNames | index("md-jira")' >/dev/null
icons_get website jsfiddle.net | jq -e '.nerdFontNames | index("md-jsfiddle")' >/dev/null
icons_get website html.spec.whatwg.org | jq -e '.nerdFontNames | index("md-language_html5")' >/dev/null
icons_get website firebase.google.com | jq -e '.nerdFontNames | index("dev-firebase")' >/dev/null
icons_get website vuejs.org | jq -e '.nerdFontNames | index("dev-vuejs")' >/dev/null
icons_get website guide.vuejs.org | jq -e '.domains | index("*.vuejs.org")' >/dev/null
test "$(icons_get website unknown.example | jq -r .glyph)" = "󰖟"
icons_get website docs.github.com | jq -e '.domains | index("*.github.com")' >/dev/null
icons_get website www.mozilla.org | jq -e '.nerdFontNames | index("dev-mozilla")' >/dev/null
icons_get website airbnb.com | jq -e '(.nerdFontNames | index("fa-airbnb")) and .color.dark == "#FF5A5F"' >/dev/null
icons_get website skype.com | jq -e '(.nerdFontNames | index("fa-skype")) and .color.dark == "#00AFF0"' >/dev/null
icons_get website yahoo.com | jq -e '(.nerdFontNames | index("fa-yahoo")) and .color.dark == "#6001D2"' >/dev/null
icons_get website yandex.ru | jq -e '(.nerdFontNames | index("fa-yandex")) and .color.dark == "#FC3F1D"' >/dev/null
icons_get website wechat.com | jq -e '(.nerdFontNames | index("fa-wechat")) and .color.dark == "#07C160"' >/dev/null
icons_get website yelp.com | jq -e '(.nerdFontNames | index("fa-yelp")) and .color.dark == "#D32323"' >/dev/null
icons_get website snapchat.com | jq -e '.nerdFontNames | index("fa-snapchat")' >/dev/null
icons_get website quora.com | jq -e '.nerdFontNames | index("fa-quora")' >/dev/null
icons_get website etsy.com | jq -e '.nerdFontNames | index("fa-etsy")' >/dev/null
icons_get website line.me | jq -e '.nerdFontNames | index("fa-line")' >/dev/null
icons_get website lyft.com | jq -e '.nerdFontNames | index("fa-lyft")' >/dev/null
icons_get website uber.com | jq -e '.nerdFontNames | index("fa-uber")' >/dev/null
icons_get website hulu.com | jq -e '(.nerdFontNames | index("md-hulu")) and .color.dark == "#1CE783"' >/dev/null
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
