# Glyphbook Engineering Contract

Glyphbook is a portable icon resolver. Maintain these invariants when changing
the catalog, resolver, generators, or application integrations.

## Product Rules

- One catalog and one resolution model provide consistent Nerd Font glyphs and
  effective colors across every supported application.
- Nix and non-Nix consumers have equivalent resolution semantics. JSON is the
  interchange format; Lua and POSIX shell are native convenience APIs.
- Users can override a glyph or color globally, and can add an app-specific
  override. Explicit overrides win over app color policy, theme colors, and
  catalog defaults.
- Apps can set a color policy. For example, Rofi can use monochrome muted icons
  while explicit per-icon colors still win.
- Stylix is a theme provider, not a core dependency. Its integration supplies
  normalized named colors to the resolver; non-Nix consumers can supply the same
  theme values themselves.
- File matching follows MiniIcons priority exactly: exact basename, widest
  compound extension, narrower extension, detected editor filetype, then file
  default.
- Prefer Nerd Font classes in this order for curated semantic choices:
  `nf-md-*`, `nf-dev-*`, `nf-seti-*`, then `nf-custom-*`. Material Design glyphs
  generally have more deliberate Unicode assignments and render at the correct
  double width in Kitty; Devicons offer broad brand coverage, Seti has
  up-to-date extension icons, and Custom glyphs are niche.

- `extensions` are filesystem suffixes. `editorFiletypes` are editor-detected
  syntax types. Never project an editor filetype into an application that only
  understands extensions, such as Yazi or lsd.
- Website matching is exact host, longest matching `*.` suffix, then `*`
  fallback.

## Catalog Rules

- Catalog records represent semantic icons. Matcher ownership must be unique;
  identical glyph characters may be reused by separate semantic records.
- Prefer Nerd Font glyph families in this order for curated semantic choices:
  `md`, `dev`, `seti`, then `custom`.
- Keep `nerdFontNames` for provenance and raw lookup, but application targets
  should use semantic matchers or symbols instead of hard-coded Nerd Font names.
- `catalog/icons.json` is the single catalog. Records with semantic matchers are
  source records; generated records without matchers must not be edited by hand.
- `catalog/generated-stats.json` is generated output and must not be edited by
  hand.
- Adapters resolve icons and projections translate resolved records to native
  application configuration. Projections must not reimplement lookup, overrides,
  or color precedence.

## Freshness Rules

- Updates to Nerd Fonts, MiniIcons, and Simple Icons are generated
  deterministically and proposed in reviewable pull requests.
- Validate generated schemas, matcher invariants, and deterministic output
  before a generated pull request is created.
- Existing website health checks are advisory. Redirects, outages, and uncertain
  website-icon mappings are never applied automatically.
- Keep a bounded, reviewable website discovery path in mind. Candidate domains
  need provenance and confidence before automation may propose them in a pull
  request; do not perform unbounded web discovery.
