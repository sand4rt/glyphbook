{ config, lib, ... }:
let
  inherit (config.glyphbook.icons) nerdFonts;
  bluetooth = {
    format-connected = nerdFonts."fa-bluetooth".glyph;
    format-disabled = nerdFonts."md-bluetooth_off".glyph;
    format-icons = builtins.genList (_: nerdFonts."md-battery".glyph) 11;
  };
  modules = {
    "hyprland/workspaces".format-icons = {
      power-saver = nerdFonts."md-flash".glyph;
      active = nerdFonts."md-square_rounded".glyph;
      urgent = nerdFonts."fa-circle_exclamation".glyph;
      "1" = "1";
      "2" = "2";
      "3" = "3";
      "4" = "4";
      "5" = "5";
      "6" = "6";
      "7" = "7";
      "8" = "8";
      "9" = "9";
    };
    disk.format-critical = nerdFonts."md-harddisk".glyph;
    cpu.format-critical = nerdFonts."md-chip".glyph;
    memory.format-critical = nerdFonts."md-memory".glyph;
    battery = {
      format = "{icon}";
      format-icons = [
        nerdFonts."md-battery_outline".glyph
        nerdFonts."md-battery_10".glyph
        nerdFonts."md-battery_20".glyph
        nerdFonts."md-battery_30".glyph
        nerdFonts."md-battery_40".glyph
        nerdFonts."md-battery_50".glyph
        nerdFonts."md-battery_60".glyph
        nerdFonts."md-battery_70".glyph
        nerdFonts."md-battery_80".glyph
        nerdFonts."md-battery_90".glyph
        nerdFonts."md-battery".glyph
      ];
    };
    pulseaudio = {
      format-bluetooth = nerdFonts."md-bluetooth".glyph;
      format-bluetooth-muted = nerdFonts."md-bluetooth_off".glyph;
      format-source = nerdFonts."md-microphone".glyph;
      format-source-muted = nerdFonts."md-microphone_off".glyph;
      format-icons = {
        speaker = nerdFonts."fa-volume_high".glyph;
        handsfree = nerdFonts."fa-headphones".glyph;
        headset = nerdFonts."fa-headphones".glyph;
        phone = nerdFonts."fa-phone".glyph;
        phone-muted = nerdFonts."fa-phone".glyph;
        portable = nerdFonts."fa-volume_high".glyph;
        default = [
          nerdFonts."fa-volume_off".glyph
          nerdFonts."fa-volume_down".glyph
          nerdFonts."fa-volume".glyph
          nerdFonts."fa-volume_high".glyph
        ];
      };
    };
  };
in
{
  options.glyphbook.targets.waybar = {
    bluetooth = {
      enable = lib.mkEnableOption "Glyphbook Bluetooth icons for Waybar";
      bars = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Waybar settings entries that receive Glyphbook Bluetooth icons.";
      };
    };
    modules = {
      enable = lib.mkEnableOption "Glyphbook built-in module icons for Waybar";
      bars = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Waybar settings entries that receive Glyphbook built-in module icons.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (
      config.glyphbook.enable
      && config.glyphbook.targets.waybar.bluetooth.enable
      && config.programs.waybar.enable
    ) {
      programs.waybar.settings = builtins.listToAttrs (
        map (bar: {
          name = bar;
          value.bluetooth = lib.mapAttrs (_: lib.mkDefault) bluetooth;
        }) config.glyphbook.targets.waybar.bluetooth.bars
      );
    })
    (lib.mkIf (
      config.glyphbook.enable
      && config.glyphbook.targets.waybar.modules.enable
      && config.programs.waybar.enable
    ) {
      programs.waybar.settings = builtins.listToAttrs (
        map (bar: {
          name = bar;
          value = lib.mapAttrs (
            _: module:
            lib.mapAttrs (
              _: setting:
              if builtins.isAttrs setting then lib.mapAttrs (_: lib.mkDefault) setting else lib.mkDefault setting
            ) module
          ) modules;
        }) config.glyphbook.targets.waybar.modules.bars
      );
    })
  ];
}
