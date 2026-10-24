{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.glyphbook.targets.spotify-player;
  icons = config.glyphbook.icons.forApp "spotify-player";
  heart = icons.nerdFonts."cod-heart_filled";
in
{
  options.glyphbook.targets.spotify-player.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether Glyphbook configures Spotify Player icons.";
  };

  config = lib.mkIf (options ? programs.spotify-player && config.glyphbook.enable && cfg.enable) {
    programs.spotify-player = {
      settings.play_icon = lib.mkDefault "▶";
      settings.liked_icon = lib.mkDefault heart.glyph;
      themes = lib.optionals (heart.color != null) [ {
        component_style.like.fg = heart.color;
      } ];
    };
  };
}
