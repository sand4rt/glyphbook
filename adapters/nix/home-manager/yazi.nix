{ config, lib, ... }:
let
  cfg = config.glyphbook.targets.yazi;
  icons = config.glyphbook.icons.forApp "yazi";
  yaziRule = name: icon: {
    inherit name;
    text = icon.glyph;
  } // lib.optionalAttrs ((icon.color or null) != null) {
    fg = icon.color;
  };
  yaziRules = records: map (name: yaziRule name records.${name}) (builtins.attrNames records);
  conditionIcons = [
    { "if" = "orphan"; text = icons.nerdFonts."fa-exclamation_triangle".glyph; }
    { "if" = "link"; text = icons.nerdFonts."oct-file_symlink_file".glyph; }
    { "if" = "block"; text = icons.nerdFonts."fa-bars".glyph; }
    { "if" = "fifo"; text = icons.nerdFonts."fa-empire".glyph; }
    { "if" = "sock"; text = icons.nerdFonts."fa-tty".glyph; }
    { "if" = "sticky"; text = icons.nerdFonts."fa-paint_brush".glyph; }
    { "if" = "dummy"; text = icons.nerdFonts."fa-remove_sign".glyph; }
  ];
  icon = {
    dirs = yaziRules icons.mini.directory;
    files = yaziRules icons.mini.file;
    exts = yaziRules icons.mini.extension;
    prepend_conds =
      let
        defaultRule = category: {
          "if" = if category == "directory" then "dir" else "!dir";
          text = icons.mini.default.${category}.glyph;
        } // lib.optionalAttrs ((icons.mini.default.${category}.color or null) != null) {
          fg = icons.mini.default.${category}.color;
        };
      in
      conditionIcons ++ [
        (defaultRule "directory")
        { "if" = "exec"; text = icons.nerdFonts."dev-terminal".glyph; }
        (defaultRule "file")
      ];
  };
  notify = {
    icon_info = icons.diagnostics.info;
    icon_warn = icons.diagnostics.warn;
    icon_error = icons.diagnostics.error;
  };
  conditionRules = map (
    icon:
    icon
    // lib.optionalAttrs (cfg.conditionColors ? ${icon."if"}) {
      fg = cfg.conditionColors.${icon."if"};
    }
  ) icon.prepend_conds;
in
{
  options.glyphbook.targets.yazi = {
    enable = lib.mkEnableOption "Glyphbook defaults for Yazi" // {
      default = true;
    };
    notifications.enable = lib.mkEnableOption "Glyphbook notification icons for Yazi";
    conditionColors = lib.mkOption {
      type = lib.types.attrsOf (lib.types.strMatching "#[0-9a-fA-F]{6}");
      default = { };
      description = "Yazi icon colors keyed by condition, such as orphan or exec.";
    };
  };

  config =
    lib.mkIf
      (config.glyphbook.enable && cfg.enable && config.programs.yazi.enable)
      {
        assertions = [
          {
            assertion = lib.all (condition: builtins.elem condition (map (rule: rule."if") icon.prepend_conds)) (builtins.attrNames cfg.conditionColors);
            message = "glyphbook.targets.yazi.conditionColors contains an unknown condition.";
          }
        ];
        programs.yazi.theme = {
          icon = lib.mapAttrs (_: lib.mkDefault) (
            icon
            // {
              prepend_conds = conditionRules;
            }
          );
        }
        // lib.optionalAttrs cfg.notifications.enable {
          notify = lib.mapAttrs (_: lib.mkDefault) notify;
        };
      };
}
