# Contributing

Glyphbook has three kinds of maintained files:

- Edit applications, domains, semantic symbols, and glyph candidates in
  `catalog/icons.json`. Records with semantic matchers are retained when the
  catalog is regenerated and merged into the corresponding glyph record.
- Existing non-neutral glyph colors are retained during generation. Records
  with the neutral fallback may receive a matching Simple Icons brand color;
  only unmatched newly introduced glyphs retain the neutral fallback.
- Do not edit generated MiniIcons or Nerd Font records, or `catalog/generated-stats.json`.
- Edit schemas, resolver adapters, projections, and tests as source code.

Website lookup is deterministic: exact hosts win, then the longest matching
subdomain pattern, then the `*` fallback. Record order is never precedence. A
website record has:

- `domains`: exact hosts or `*.` subdomain patterns
- `glyph`: a Nerd Fonts 3 glyph
- `color`: six-digit RGB brand or semantic color

Each matcher belongs to exactly one record. A glyph can intentionally be reused
by distinct semantic records.

Run `nix flake check` before submitting a change. New mappings should include
an exact-host and subdomain lookup assertion in `adapters/shell/shell.test.sh` when relevant.

Edit application and website mappings in `catalog/icons.json`, then run
`nix run .#generate`. The scheduled update workflow proposes reviewed pull
requests for upstream Nerd Fonts, MiniIcons, and Simple Icons changes. Website
health reports are advisory; they never change mappings automatically.
