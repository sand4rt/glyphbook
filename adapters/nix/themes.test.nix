let
  configured = args: import ./nix.nix args;
  themed = configured { theme = "github-dark-dimmed"; };
  github = icons: (icons.resolve { category = "website"; name = "github.com"; });
  custom = configured {
    theme = "github-dark-dimmed";
    themeColors.foregroundStrong = "#ffffff";
    overrides.website."github.com".glyph = "G";
  };
  overridden = configured {
    theme = "github-dark-dimmed";
    overrides.website."github.com" = { glyph = "G"; colorRole = "blue"; };
    apps.rofi = {
      colors.mode = "none";
      overrides.website."github.com".glyph = "R";
    };
  };
  legacy = configured { theme.muted = "#777777"; };
  contrastIcons = configured {
    theme = "github-dark-dimmed";
    apps.rofi.colors.mode = "contrast";
  };
  light = configured {
    themeColors = { background = "#ffffff"; foreground = "#000000"; foregroundStrong = "#000000"; };
    apps.rofi.colors.mode = "contrast";
  };
  contrast = (import ./colors.nix).contrast;
in
assert (github themed).color == "#cdd9e5";
assert themed.websiteFallbackColor == themed.themeColors.muted;
assert (configured { theme = "github-dark-dimmed"; themeColors.blue = "#123456"; }).mini.editorFiletype.nix.color == "#123456";
assert (themed.forApp "lsd").mini.editorFiletype.nix.color == themed.themeColors.blue;
assert (github custom).color == "#ffffff" && (github custom).glyph == "G";
assert (overridden.resolve { category = "website"; name = "github.com"; app = "rofi"; }).glyph == "R";
assert (overridden.resolve { category = "website"; name = "github.com"; app = "rofi"; }).color == "#539bf5";
assert (builtins.head (builtins.filter (icon: icon.domains == [ "github.com" ]) (overridden.websitesFor "rofi"))).color == "#539bf5";
assert legacy.themeColors.muted == "#777777";
assert contrast "#000000" "#ffffff" == 21;
assert builtins.all (icon: contrast icon.color contrastIcons.themeColors.background >= 3) (contrastIcons.websitesFor "rofi");
assert builtins.all (icon: contrast icon.color "#ffffff" >= 3) (light.websitesFor "rofi");
assert (configured { polarity = "light"; }).polarity == "light";
assert (configured { overrides.nerdFont."md-nix".glyph = "N"; }).nerdFonts."md-nix".glyph == "N";
assert !(builtins.tryEval (github (configured { theme = "missing"; })).color).success;
assert !(builtins.tryEval (github (configured { themeColors.blue = "invalid"; })).color).success;
assert !(builtins.tryEval (github (configured {
  theme = "github-dark-dimmed";
  overrides.website."github.com" = { color = "#ffffff"; colorRole = "blue"; };
})).color).success;
assert !(builtins.tryEval (github (configured {
  overrides.website."github.com".colorRole = "missing";
})).color).success;
true
