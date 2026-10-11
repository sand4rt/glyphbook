{ config, lib, ... }:
let
  glyphs = builtins.mapAttrs (_: icon: icon.glyph);
in
{
  options.glyphbook.targets.lsd.enable = lib.mkEnableOption "Glyphbook defaults for lsd";

  config = lib.mkIf (config.glyphbook.enable && config.glyphbook.targets.lsd.enable && config.programs.lsd.enable) {
    programs.lsd.icons = lib.mapAttrs (_: lib.mkDefault) {
      filetype = {
        dir = config.glyphbook.icons.mini.default.directory.glyph;
        file = config.glyphbook.icons.mini.default.file.glyph;
        pipe = config.glyphbook.icons.nerdFonts."md-filter".glyph;
        socket = config.glyphbook.icons.nerdFonts."md-cube_send".glyph;
        executable = config.glyphbook.icons.nerdFonts."seti-shell".glyph;
        symlink-dir = config.glyphbook.icons.nerdFonts."oct-file_symlink_directory".glyph;
        symlink-file = config.glyphbook.icons.nerdFonts."oct-file_symlink_file".glyph;
        device-char = config.glyphbook.icons.nerdFonts."seti-project".glyph;
        device-block = config.glyphbook.icons.nerdFonts."md-webpack".glyph;
        special = config.glyphbook.icons.nerdFonts."md-snowflake".glyph;
      };
      name = glyphs (config.glyphbook.icons.mini.directory // config.glyphbook.icons.mini.file);
      extension = glyphs config.glyphbook.icons.mini.extension;
    };
  };
}
