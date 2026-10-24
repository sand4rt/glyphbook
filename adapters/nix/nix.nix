{
  catalog ? ../../catalog/icons.json,
  colors ? { },
  fallbackColor ? null,
  overrides ? { },
  apps ? { },
  theme ? null,
  themeColors ? { },
  polarity ? null,
  _app ? null,
}@args:
let
  themes = { github-dark-dimmed = builtins.fromJSON (builtins.readFile ../../themes/github-dark-dimmed.json); };
  selectedTheme = if theme == null || builtins.isAttrs theme then { } else
    themes.${theme} or (throw "Glyphbook: unknown theme '${theme}'");
  palette = (selectedTheme.colors or { }) // (if builtins.isAttrs theme then theme else { }) // themeColors;
  validColor = color: builtins.isString color && builtins.match "#[0-9a-fA-F]{6}" color != null;
  checkedPalette = if builtins.all validColor (builtins.attrValues palette) then palette
    else throw "Glyphbook: theme colors must be six-digit hex colors";
  activePolarity = if polarity == null then selectedTheme.polarity or "dark" else polarity;
  themeRole = role: checkedPalette.${role} or (throw "Glyphbook: unknown theme color role '${role}'");
  colorUtils = import ./colors.nix;
  inherit (colorUtils) contrast;
  catalogData = builtins.fromJSON (builtins.readFile catalog);
  configuredIcons = map (
    icon:
    icon
    // {
      color =
        if
          icon ? domains
          && builtins.any (domain: domain != "*" && builtins.substring 0 2 domain != "*.") icon.domains
        then
          colors.${
            builtins.head (
              builtins.filter (domain: domain != "*" && builtins.substring 0 2 domain != "*.") icon.domains
            )
           } or (if builtins.isAttrs (icon.color or null) then icon.color.${activePolarity} or null else icon.color or null)
        else
          if builtins.isAttrs (icon.color or null) then icon.color.${activePolarity} or null else icon.color or null;
    }
  ) catalogData.icons;
  websiteFallback = builtins.head (
    builtins.filter (icon: builtins.elem "*" (icon.domains or [ ])) configuredIcons
  );
  reversedConfiguredIcons = builtins.foldl' (result: icon: [ icon ] ++ result) [ ] configuredIcons;
  categoryMap =
    category: field:
    let
      records = builtins.listToAttrs (
        builtins.concatMap
          (
            icon:
            map (name: {
              inherit name;
              value = icon;
            }) (icon.${field} or [ ])
          )
          reversedConfiguredIcons
      );
    in
    records
    // builtins.mapAttrs (
      name: override:
      if !(records ? ${name}) && !(override ? glyph) then
        throw "Glyphbook: a new ${category} matcher needs a glyph"
      else
        (records.${name} or { }) // override
    ) (overrides.${category} or { });
  rawMini = {
    default = categoryMap "default" "defaults";
    directory = categoryMap "directory" "directories";
    extension = categoryMap "extension" "extensions";
    file = categoryMap "file" "files";
    editorFiletype = categoryMap "editorFiletype" "editorFiletypes";
    lsp = categoryMap "lsp" "lsp";
    os = categoryMap "os" "operatingSystems";
  };
  rawNerdFonts = categoryMap "nerdFont" "nerdFontNames";
  nerdFonts = builtins.mapAttrs (name: _: resolve { category = "nerdFont"; inherit name; }) rawNerdFonts;
  rawSymbols = categoryMap "symbol" "symbols";
  symbols = builtins.mapAttrs (name: _: resolve { category = "symbol"; inherit name; }) rawSymbols;
  websiteMap = categoryMap "website" "domains";
  applicationMap = categoryMap "application" "applications";
  colorFor = app: icon:
    let
      appConfig = if app == null then { } else apps.${app} or { };
      policy = appConfig.colors or { mode = "preserve"; };
      mode = policy.mode or "preserve";
      configuredRole = policy.colorRole or null;
      policyRole = if configuredRole == null then "muted" else configuredRole;
      role = icon.colorRole or null;
      themeColor = if role != null then themeRole role else null;
      original = if themeColor != null then themeColor else icon.color or null;
      readable = color: color != null && (checkedPalette ? background) && contrast color checkedPalette.background >= 3;
      candidates = [ (policy.color or null) (checkedPalette.foregroundStrong or null) (checkedPalette.foreground or null) ]
        ++ builtins.attrValues checkedPalette;
      contrasting = builtins.filter readable candidates;
      policyColor =
        if mode == "none" then null
        else if mode == "monochrome" then (if (policy.color or null) != null then policy.color else checkedPalette.${policyRole} or null)
        else if mode == "role" then themeRole (if configuredRole == null then "foreground" else configuredRole)
        else if mode == "contrast" && checkedPalette ? background && !(readable original) then
          if contrasting == [ ] then throw "Glyphbook: theme has no icon color with 3:1 background contrast"
          else builtins.head contrasting
        else original;
    in
    policyColor;
  explicitColorFor = override:
    if override ? color && override ? colorRole then throw "Glyphbook: specify color or colorRole, not both"
    else if override ? color then
      if override.color == null || validColor override.color then override.color
      else throw "Glyphbook: icon colors must be six-digit hex colors"
    else themeRole override.colorRole;
  resolve = { category, name, app ? _app }:
    let
      records =
        if category == "application" then applicationMap
        else if category == "website" then websiteMap
        else if category == "symbol" then rawSymbols
        else if category == "nerdFont" then rawNerdFonts
        else rawMini.${category};
      global = records.${name} or (throw "Glyphbook: unknown ${category} matcher ${name}");
      globalOverride = overrides.${category}.${name} or { };
      appConfig = if app == null then { } else apps.${app} or { };
      appOverride = appConfig.overrides.${category}.${name} or { };
       role = selectedTheme.roles.${category}.${name} or (global.colorRole or (
         if selectedTheme != { } && (global.color or null) != null
         then colorUtils.role global.color else null
       ));
      resolved = global // { colorRole = role; } // appOverride;
      legacyColor = if category == "website" then colors.${name} or null else null;
      fallback = if category == "website" && name == "*" then fallbackColor else null;
    in
    builtins.seq checkedPalette (resolved // {
      color = if appOverride ? color || appOverride ? colorRole then explicitColorFor appOverride
        else if globalOverride ? color || globalOverride ? colorRole then explicitColorFor globalOverride
        else if legacyColor != null then legacyColor
        else if fallback != null then fallback
        else colorFor app resolved;
    });
in
catalogData
// rec {
  icons = configuredIcons;
  applications = builtins.mapAttrs (name: _: resolve { category = "application"; inherit name; }) applicationMap;
  applicationGlyphs = builtins.mapAttrs (_: icon: icon.glyph) applications;
  git = {
    modified = nerdFonts."oct-diff_modified";
    added = nerdFonts."oct-diff_added";
    untracked = nerdFonts."md-checkbox_blank_circle_outline";
    ignored = nerdFonts."oct-diff_ignored";
    deleted = nerdFonts."oct-diff_removed";
  };
  diagnostics = {
    error = nerdFonts."md-skull".glyph;
    warn = nerdFonts."oct-shield".glyph;
    info = nerdFonts."md-chevron_right_box".glyph;
    hint = nerdFonts."md-lightbulb".glyph;
  };
  nvim = {
    inherit diagnostics;
    completion = {
      Tag = nerdFonts."fa-tag".glyph;
      Text = nerdFonts."md-format_size".glyph;
      Method = nerdFonts."md-cube_outline".glyph;
      Function = nerdFonts."md-cube_outline".glyph;
      Constructor = nerdFonts."oct-gear".glyph;
      Field = nerdFonts."cod-symbol_field".glyph;
      Variable = nerdFonts."md-alpha".glyph;
      Class = nerdFonts."md-shape".glyph;
      Interface = nerdFonts."fa-sitemap".glyph;
      Module = nerdFonts."oct-package".glyph;
      Property = nerdFonts."cod-symbol_field".glyph;
      Unit = nerdFonts."md-ruler".glyph;
      Value = nerdFonts."md-numeric".glyph;
      Enum = nerdFonts."fa-arrow_down_a_z".glyph;
      Keyword = nerdFonts."md-key_variant".glyph;
      Key = nerdFonts."md-key_variant".glyph;
      Snippet = nerdFonts."oct-code".glyph;
      Color = nerdFonts."md-palette".glyph;
      File = nerdFonts."md-text_box".glyph;
      Reference = nerdFonts."md-export".glyph;
      Folder = nerdFonts."md-folder".glyph;
      EnumMember = nerdFonts."fa-arrow_down_a_z".glyph;
      Constant = nerdFonts."md-pi".glyph;
      Struct = nerdFonts."md-file_tree".glyph;
      Event = nerdFonts."fa-bolt".glyph;
      Operator = nerdFonts."md-contrast".glyph;
      TypeParameter = nerdFonts."md-format_text".glyph;
      Table = nerdFonts."fa-table".glyph;
      Object = nerdFonts."md-code_braces".glyph;
      Array = "[]";
      Number = nerdFonts."fa-hashtag".glyph;
      Null = nerdFonts."md-null".glyph;
      String = nerdFonts."md-format_size".glyph;
      Calendar = nerdFonts."fa-calendar".glyph;
      Watch = nerdFonts."md-clock".glyph;
      Package = nerdFonts."seti-julia".glyph;
      Copilot = nerdFonts."fa-github_alt".glyph;
      Codeium = nerdFonts."fa-magic".glyph;
      TabNine = nerdFonts."fa-bolt".glyph;
    };
    statusline = {
      editor = nerdFonts."dev-vim".glyph;
      fallbackFile = nerdFonts."custom-default".glyph;
      directory = nerdFonts."md-folder_outline".glyph;
      diagnostics = diagnostics // {
        summary = nerdFonts."oct-pulse".glyph;
      };
      macro = nerdFonts."fa-bolt".glyph;
      spinner = [
        nerdFonts."fa-circle_o".glyph
        nerdFonts."md-circle_slice_1".glyph
        nerdFonts."md-circle_slice_2".glyph
        nerdFonts."md-circle_slice_3".glyph
        nerdFonts."md-circle_slice_4".glyph
        nerdFonts."md-circle_slice_5".glyph
        nerdFonts."md-circle_slice_6".glyph
        nerdFonts."md-circle_slice_7".glyph
        nerdFonts."md-circle_slice_8".glyph
        nerdFonts."fa-check_circle".glyph
      ];
      gitBranch = nerdFonts."md-source_branch".glyph;
    };
    fyler.untracked = nerdFonts."md-checkbox_blank_outline".glyph;
  };
  spotifyPlayer.liked.color = "Red";
  websiteRecords =
    builtins.sort
      (
        left: right:
        if left.priority != right.priority then
          left.priority < right.priority
        else
          builtins.stringLength (builtins.head left.domains)
          > builtins.stringLength (builtins.head right.domains)
      )
      (
        map (
          domain:
          websiteMap.${domain}
          // {
            domains = [ domain ];
            color = (
              overrides.website.${domain}.color or (
                if domain == "*" && fallbackColor != null then
                  fallbackColor
                else
                  colors.${domain} or (websiteMap.${domain}.color or null)
              )
            );
            priority =
              if domain == "*" then
                2
              else if builtins.substring 0 2 domain == "*." then
                1
              else
                0;
          }
        ) (builtins.attrNames websiteMap)
      );
  websitesFor = app: map (icon:
    let name = builtins.head icon.domains;
    in (resolve { category = "website"; inherit name app; }) // { inherit (icon) domains priority; }
  ) websiteRecords;
  pythonWebsites = import ./python-websites.nix;
  miniFor = app: builtins.mapAttrs (category: records: builtins.mapAttrs (name: _: resolve { inherit category name app; }) records) rawMini;
  mini = miniFor _app;
  inherit nerdFonts;
  inherit symbols;
  inherit resolve;
  websites = websitesFor _app;
  inherit themes;
  themeColors = checkedPalette;
  polarity = activePolarity;
  forApp = app: import ./nix.nix (args // { _app = app; });
  websiteFallback = websiteMap."*".glyph;
  websiteFallbackColor =
    (resolve { category = "website"; name = "*"; }).color;
  websiteFallbackFor = app: (builtins.head (builtins.filter (icon: builtins.elem "*" icon.domains) (websitesFor app))).color;
}
