{ config, lib, ... }:
let
  icons = config.glyphbook.icons.forApp "lsd";
  glyphs = builtins.mapAttrs (_: icon: icon.glyph);
in
{
  options.glyphbook.targets.lsd.enable = lib.mkEnableOption "Glyphbook defaults for lsd";

  config = lib.mkIf (config.glyphbook.enable && config.glyphbook.targets.lsd.enable && config.programs.lsd.enable) {
    programs.lsd.icons = lib.mapAttrs (_: lib.mkDefault) {
      filetype = {
         dir = icons.mini.default.directory.glyph;
         file = icons.mini.default.file.glyph;
         pipe = icons.nerdFonts."md-filter".glyph;
         socket = icons.nerdFonts."md-cube_send".glyph;
         executable = icons.nerdFonts."seti-shell".glyph;
         symlink-dir = icons.nerdFonts."oct-file_symlink_directory".glyph;
         symlink-file = icons.nerdFonts."oct-file_symlink_file".glyph;
         device-char = icons.nerdFonts."seti-project".glyph;
         device-block = icons.nerdFonts."md-webpack".glyph;
         special = icons.nerdFonts."md-snowflake".glyph;
      };
      name = glyphs (icons.mini.directory // icons.mini.file);
      extension = glyphs icons.mini.extension;
    };
  };
}
