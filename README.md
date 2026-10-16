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

| Guide                                  | Purpose                                                   |
| -------------------------------------- | --------------------------------------------------------- |
| [Catalog model](docs/catalog-model.md) | Catalog schema, matcher namespaces, and lookup precedence |
| [Development](docs/development.md)     | Generation, validation, and catalog update workflow       |

## Requirements

- Nerd Fonts 3 or newer
- `jq` for the shell adapter and CLI
- A JSON decoder for Lua consumers

Brand names, logos, and colors remain the property of their respective owners.
