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
      ]
    ) (builtins.attrNames override)
    && (!(override ? glyph) || (builtins.isString override.glyph && override.glyph != ""))
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
      type = lib.types.attrsOf (lib.types.strMatching "#[0-9a-fA-F]{6}");
      default = { };
      description = "Normalized named theme colors, optionally supplied by Stylix.";
    };
    polarity = lib.mkOption {
      type = lib.types.enum [ "light" "dark" ];
      default = "dark";
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

  config.glyphbook.icons = import ../nix.nix {
    inherit (cfg)
      catalog
      colors
      fallbackColor
      overrides
      apps
      theme
      ;
  };
}
