# Catalog Model

`catalog/icons.json` is the source of truth. It has one flat `icons` array.
Every glyph appears in exactly one record, even when it has several meanings:

```json
{
  "glyph": "󱄅",
  "color": "#7EBAE4",
  "applications": ["nix-search"],
  "domains": ["mynixos.com", "*.mynixos.com"],
  "editorFiletypes": ["nix"],
  "operatingSystems": ["nixos"],
  "nerdFontNames": ["md-nix"]
}
```

Matcher fields are optional:

| Field | Matches |
| --- | --- |
| `applications` | Semantic application names, such as `terminal` |
| `domains` | Exact website hosts, `*.` subdomain patterns, or `*` fallback |
| `defaults` | MiniIcons default categories |
| `directories` | Directory names |
| `extensions` | File extensions, including compound extensions |
| `files` | Exact file basenames |
| `editorFiletypes` | Editor-detected filetypes, such as Neovim `typescriptreact` |
| `lsp` | LSP completion kinds |
| `operatingSystems` | Operating-system names |
| `nerdFontNames` | All matching Nerd Font glyph names |

Website lookup uses exact hosts first, then the longest matching `*.` subdomain
pattern, then the single `*` fallback. File lookup follows MiniIcons priority:
exact basename, widest explicit extension, optional detected editor filetype,
then the file default. Filesystem extensions and editor filetypes are separate
matcher namespaces: Yazi and lsd consume extensions, while Neovim can consume
both.

The catalog follows `catalog/schema.json`. Its `schemaVersion` changes for
incompatible data-contract changes. Curated semantic glyph selection prefers
Nerd Font families in this order: Material Design (`md`), Devicons (`dev`), Seti
(`seti`), then custom (`custom`).

Generation preserves non-neutral existing `color.dark` and `color.light`
values for a glyph. When a neutral glyph's Nerd Font name matches a Simple Icons
brand, generation applies that brand color; unmatched glyphs use the neutral
fallback.

## Filetype Icon Curation

The `editorFiletypes` matcher set includes user-facing filetypes supplied by
Neovim and broadly adopted plugins. It deliberately excludes Neovim's technical
filetypes. Keep the Neovim portion current by reviewing changes to
`runtime/lua/vim/filetype.lua` and `runtime/lua/vim/filetype/detect.lua`. It was
last reviewed on 2026-02-13.

When choosing filetype glyphs and colors:

- Spread assignments across the available highlight groups instead of
  concentrating icons in a few colors.
- Choose Nerd Font glyphs from Material Design first, then Devicons, Seti, and
  custom glyphs. In Nerd Font naming, this is `nf-md-*`, `nf-dev-*`,
  `nf-seti-*`, then `nf-custom-*`. Material Design generally has more deliberate
  Unicode assignments and correct double-width rendering in Kitty.
- When a filetype exists in `nvim-web-devicons`, choose the closest available
  highlight hue. Use OKLCH hues aligned with the evenly spaced `mini.hues`
  palette, treating chroma 3 as grey; make a manual adjustment when it improves
  the result.
- Reuse glyphs for closely related types where it improves recognition. This
  includes configuration files, assembly, SQL, Perl, HTML, CSV, shell and log
  files, build-system files, and web-related formats.
- Start new assignments with a semantically appropriate abstract Material Design
  glyph, considering the filetype's origin before matching its name.
- When no suitable semantic glyph exists, use a letter or digit based on the
  filetype's initial. Pick its highlight group to maintain color balance and
  avoid duplicating existing glyph and highlight combinations.
