{ config, lib, ... }:
let
  cfg = config.glyphbook;
  iconOverride = lib.types.addCheck (lib.types.attrsOf (lib.types.nullOr lib.types.str)) (
    override:
    lib.all (
      name:
      builtins.elem name [
        "glyph"
          "color"
          "colorRole"
      ]
    ) (builtins.attrNames override)
    && (!(override ? glyph) || (builtins.isString override.glyph && override.glyph != ""))
    && (!(override ? colorRole) || (builtins.isString override.colorRole && override.colorRole != ""))
    && !(override ? color && override ? colorRole)
    && (
      !(override ? color)
      || override.color == null
      || builtins.match "#[0-9a-fA-F]{6}" override.color != null
    )
  );
in
{
  imports = [
    ./lsd.nix
    ./spotify-player.nix
    ./waybar.nix
    ./yazi.nix
    ./neovim.nix
  ];

  options.glyphbook = {
    enable = lib.mkEnableOption "shared Glyphbook icon defaults";
    catalog = lib.mkOption {
      type = lib.types.path;
      default = ../../../catalog/icons.json;
      description = "Portable Glyphbook catalog to resolve.";
    };
    colors = lib.mkOption {
      type = lib.types.attrsOf (lib.types.strMatching "#[0-9a-fA-F]{6}");
      default = { };
      description = "Website color overrides keyed by domain.";
    };
    fallbackColor = lib.mkOption {
      type = lib.types.nullOr (lib.types.strMatching "#[0-9a-fA-F]{6}");
      default = null;
      description = "Fallback website color.";
    };
    theme = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.str (lib.types.attrsOf (lib.types.strMatching "#[0-9a-fA-F]{6}")));
      default = null;
      description = "Built-in color theme name. Legacy inline color sets remain supported; prefer themeColors.";
    };
    themeColors = lib.mkOption {
      type = lib.types.attrsOf (lib.types.strMatching "#[0-9a-fA-F]{6}");
      default = { };
      description = "Named palette color overrides, with or without a built-in theme.";
    };
    polarity = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "light" "dark" ]);
      default = null;
      description = "Active color-scheme polarity used by contrast-aware icon policies.";
    };
    apps = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          colors = lib.mkOption {
            type = lib.types.submodule {
              options = {
                mode = lib.mkOption {
                  type = lib.types.enum [ "preserve" "monochrome" "role" "none" "contrast" ];
                  default = "preserve";
                };
                color = lib.mkOption {
                  type = lib.types.nullOr (lib.types.strMatching "#[0-9a-fA-F]{6}");
                  default = null;
                };
                colorRole = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
              };
            };
            default = { };
          };
          overrides = lib.mkOption {
            type = lib.types.attrsOf (lib.types.attrsOf iconOverride);
            default = { };
          };
        };
      });
      default = { };
      description = "Application-specific color policies and explicit icon overrides.";
    };
    overrides =
      lib.genAttrs
        [
          "application"
          "website"
          "default"
          "directory"
          "extension"
          "file"
          "editorFiletype"
          "lsp"
           "os"
           "nerdFont"
           "symbol"
        ]
        (
          _:
          lib.mkOption {
            type = lib.types.attrsOf iconOverride;
            default = { };
            description = "Global icon overrides keyed by matcher; omitted fields retain catalog defaults.";
          }
        );
    icons = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      description = "Resolved catalog mappings for custom integrations.";
    };
  };

  config.warnings = lib.optional (builtins.isAttrs cfg.theme)
    "glyphbook.theme as a color set is deprecated; move inline colors to glyphbook.themeColors.";

  config.glyphbook.icons = import ../nix.nix {
    inherit (cfg)
      catalog
      colors
      fallbackColor
      overrides
      apps
      theme
      themeColors
      polarity
      ;
  };
}
