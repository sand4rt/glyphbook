{ config, lib, ... }:
let
  colors = config.lib.stylix.colors.withHashtag;
in {
  # Import alongside Stylix. These remain defaults so user palette overrides win.
  config.glyphbook = {
    polarity = lib.mkDefault (if config.stylix.polarity == "either" then null else config.stylix.polarity);
    themeColors = lib.mapAttrs (_: lib.mkDefault) {
      background = colors.base00;
      foreground = colors.base05;
      foregroundStrong = colors.base06;
      muted = colors.base03;
      red = colors.base08;
      orange = colors.base09;
      yellow = colors.base0A;
      green = colors.base0B;
      cyan = colors.base0C;
      blue = colors.base0D;
      purple = colors.base0E;
      pink = colors.base0F;
    };
  };
}
