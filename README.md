# Glyphbook

Glyphbook gives your terminal, file manager, editor, launcher, status bar, and
browser tools one shared icon language. Instead of maintaining separate icon
tables for every application, Glyphbook resolves each file, directory, website,
and application to the same Nerd Font glyph and color.

Use it from Nix, Lua, or POSIX shell. Every adapter reads the same portable JSON
catalog and follows the same matching rules.

## Capabilities

- Keep icons consistent across Yazi, Neovim, lsd, Waybar, launchers, scripts,
  and browser menus.
- Use one portable JSON catalog from Nix, Lua, or POSIX shell.
- Override glyphs and colors globally or for a specific application.
- Adapt icon colors to dark and light themes.
- Generate application-native configuration instead of copying icon tables.
- Match files and websites predictably using MiniIcons-compatible precedence.
- Look up icons instantly at runtime.

## Quick Start

<details open>
<summary>Lua: configure Neovim</summary>

Install `mini.icons`, place `adapters/lua/lua.lua` at
`lua/glyphbook.lua` in your Neovim configuration, and point this setup at your
local Glyphbook checkout. Load this from `init.lua`:

```lua
local glyphbook = require('glyphbook')
local catalog = glyphbook.open({
  resolver = vim.fn.expand('~/src/glyphbook/result/bin/glyphbook-resolver'),
  index = vim.fn.expand('~/src/glyphbook/catalog/icons.index'),
  records = vim.fn.expand('~/src/glyphbook/catalog/icons.records.jsonl'),
  decode = vim.json.decode,
})

local function icons(category)
  local result = {}
  for name, icon in pairs(catalog.map(category)) do
    result[name] = { glyph = icon.glyph }
  end
  return result
end

require('mini.icons').setup({
  directory = icons('directory'),
  file = icons('file'),
  extension = icons('extension'),
  filetype = icons('editor_filetype'),
})

```

`mini.icons` now uses Glyphbook's directory, filename, extension, and filetype
mappings. Use `glyphbook.get_file(catalog, path, filetype)` for a direct runtime
lookup in a custom Telescope, Snacks, or statusline component.

</details>

<details>
<summary>Nix and Home Manager: configure Yazi</summary>

Add Glyphbook to your flake inputs:

```nix
{
  inputs.glyphbook.url = "github:sand4rt/glyphbook";
}
```

Then import the Home Manager module and enable Yazi. Glyphbook applies its
directory, filename, and extension icons automatically.

```nix
{ inputs, ... }:
{
  imports = [ inputs.glyphbook.homeManagerModules.default ];

  glyphbook = {
    enable = true;
    targets.yazi.enable = true;
  };

  programs.yazi.enable = true;
}
```

</details>

<details>
<summary>Shell: build an icon-aware file listing</summary>

Source the adapter and use it in a POSIX shell script:

```sh
git clone https://github.com/sand4rt/glyphbook.git
cd glyphbook

export GLYPHBOOK_CATALOG="$PWD/catalog/icons.json"
. ./adapters/shell/shell.sh

list_icons() {
  directory=${1:-.}

  for path in "$directory"/* "$directory"/.[!.]* "$directory"/..?*; do
    [ -e "$path" ] || continue

    if [ -d "$path" ]; then
      icon=$(icons_get directory "${path##*/}" 2>/dev/null || icons_get default directory)
    else
      icon=$(icons_get_file "$path")
    fi

    printf '%s %s\n' "$(printf '%s' "$icon" | jq -r '.glyph')" "${path##*/}"
  done
}

list_icons "${1:-.}"
```

`icons_get_file` follows Glyphbook's filename, compound-extension, extension,
and default-file precedence. The shell adapter requires `jq`.

To inspect an icon before adding it to a config, use the CLI:

```sh
./adapters/shell/glyphbook get website github.com | jq -r '.glyph'
./adapters/shell/glyphbook file archive.tar.gz | jq -r '.glyph'
```

</details>

## Documentation

### Color themes and icon overrides

Select one shared palette for every integration:

```nix
glyphbook = {
  enable = true;
  theme = "github-dark-dimmed";
  themeColors.blue = "#539bf5";
  overrides = {
    application.terminal.glyph = "";
    website."github.com".colorRole = "foregroundStrong";
    extension.nix = { glyph = ""; color = "#7ebae4"; };
  };
  apps.rofi.colors.mode = "contrast";
};
```

`themeColors` changes named palette colors; `overrides` changes individual
glyphs, colors, or both. Use either a fixed `color` or a theme `colorRole`, not
both. Fields merge independently. Application-specific overrides in
`apps.<app>.overrides` win over global overrides; explicit icon colors win over
application policies and theme defaults. Normal Home Manager application options
remain overridable defaults, including Yazi icon lists and lsd glyph mappings.

Built-in `github-dark-dimmed` uses GitHub's semantic foreground and ANSI tokens,
including `foregroundStrong = "#cdd9e5"` for GitHub logos. Available roles are
`background`, `foreground`, `foregroundStrong`, `muted`, `red`, `orange`,
`yellow`, `green`, `cyan`, `blue`, `purple`, and `pink`.

`theme` defaults to null (catalog colors). Partial `themeColors` work with or
without a preset. Legacy `theme = { muted = "#777777"; };` remains supported;
migrate inline colors to `themeColors`. Explicit polarity overrides the preset.
App policies are `preserve` (default), `monochrome`, `role`, `none`, and
`contrast`. Contrast mode preserves readable colors and otherwise selects a
theme color with at least 3:1 sRGB contrast against `background`. Named themes
map catalog hues onto palette families; neutral colors use `foreground`.
Explicit semantic roles (including GitHub's `foregroundStrong`) take precedence
over hue mapping. Without a named theme, catalog colors are preserved.

Custom Nix consumers use the same options with `lib.withConfig`; consume
`websitesFor "rofi"`, `miniFor "yazi"`, or `resolve { category = "application";
name = "terminal"; app = "launcher"; }` to apply app-local policies and overrides.

Stylix is optional. Import `glyphbook.homeManagerModules.stylix` alongside its
default module and Stylix to supply normalized palette defaults. Explicit
`themeColors` win over the provider, whose colors take precedence over the preset.

The portable theme files live in `themes/`. Shell consumers can select a preset
with `GLYPHBOOK_THEME=github-dark-dimmed`, or supply the same configuration as
JSON through `GLYPHBOOK_CONFIG` and optionally `GLYPHBOOK_APP`. The CLI locates
the theme resolver automatically; sourced shell adapters also need
`GLYPHBOOK_THEME_RESOLVER` pointing at `adapters/python/themes.py`. Theme-enabled
shell and Lua resolution requires Python 3. Unthemed lookup retains its existing
fast path. For repeated shell lookups, prepare a configured native index once:

```sh
. /path/to/glyphbook/adapters/shell/shell.sh
icons_prepare_theme /path/to/prepared-icons
icons_get website github.com
```

Set `GLYPHBOOK_RESOLVER`, `GLYPHBOOK_CATALOG`, `GLYPHBOOK_THEME_RESOLVER`, and
the theme/config variables before preparing. Subsequent lookups use the native
index without launching Python or scanning the catalog. Run preparation again
after changing the catalog, theme, config, or app. Preparation writes only to
the explicitly supplied directory; one-shot CLI lookups remain available:

```sh
GLYPHBOOK_THEME=github-dark-dimmed sh adapters/shell/glyphbook get website github.com
```

Lua consumers can use `glyphbook.open` or `glyphbook.load` with
`theme = 'github-dark-dimmed'`, `themeResolver = '/path/to/glyphbook/adapters/python/themes.py'`,
and a `catalog` path (`load` already takes that path as its first argument).
Use `config = '/path/to/config.json'` for palette and individual icon overrides,
and `app = 'rofi'` for app-specific rules. `open` also needs a JSON `decode`
function. Named themes are resolved once when loading, with indexed in-memory
lookups thereafter. Configuration changes require regenerating or reloading the
consumer; this API does not introduce live theme switching.

### Python website menus

Embed `lib.pythonWebsites` in a Nix-generated Python script and pass the resolved
website projection to `Websites`. Generate this JSON with
`builtins.toJSON (icons.websitesFor "rofi")`, where `icons` is the configured
Glyphbook library. This preserves application-specific glyph and color policy.

```python
import json

with open("websites.json") as source:
    websites = Websites(json.load(source))
icon = websites.get_url("https://example.com/page")
```

`get(host)` and `get_url(url)` resolve exact hosts, then the longest matching
wildcard suffix, then the `*` fallback. The adapter indexes only the supplied
website records; it does not cache visited URLs or hostnames. Memory is bounded
by the website projection, regardless of browsing-history size.

| Guide                                  | Purpose                                                   |
| -------------------------------------- | --------------------------------------------------------- |
| [Catalog model](docs/catalog-model.md) | Catalog schema, matcher namespaces, and lookup precedence |
| [Development](docs/development.md)     | Generation, validation, and catalog update workflow       |

## Requirements

- Nerd Fonts 3 or newer
- `jq` for the shell adapter and CLI
- A JSON decoder for Lua consumers

Brand names, logos, and colors remain the property of their respective owners.
