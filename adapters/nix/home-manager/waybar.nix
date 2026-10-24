{ config, lib, ... }:
let
  inherit (config.glyphbook.icons.forApp "waybar") nerdFonts;
  bluetooth = {
    format = nerdFonts."fa-bluetooth".glyph;
    format-connected = nerdFonts."fa-bluetooth".glyph;
    format-disabled = nerdFonts."md-bluetooth_off".glyph;
    format-icons = [
      nerdFonts."md-battery_alert_bluetooth".glyph
      nerdFonts."md-battery_10_bluetooth".glyph
      nerdFonts."md-battery_20_bluetooth".glyph
      nerdFonts."md-battery_30_bluetooth".glyph
      nerdFonts."md-battery_40_bluetooth".glyph
      nerdFonts."md-battery_50_bluetooth".glyph
      nerdFonts."md-battery_60_bluetooth".glyph
      nerdFonts."md-battery_70_bluetooth".glyph
      nerdFonts."md-battery_80_bluetooth".glyph
      nerdFonts."md-battery_90_bluetooth".glyph
      nerdFonts."md-battery_bluetooth".glyph
    ];
  };
  modules = {
    "hyprland/workspaces".format-icons = {
      default = nerdFonts."cod-circle_filled".glyph;
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
    disk.format-critical = nerdFonts."md-database_alert".glyph;
    cpu.format-critical = nerdFonts."md-speedometer".glyph;
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
      format-muted = nerdFonts."fa-volume_xmark".glyph;
      format-bluetooth = nerdFonts."md-earbuds".glyph;
      format-bluetooth-muted = nerdFonts."md-earbuds_off".glyph;
      format-source = nerdFonts."md-microphone".glyph;
      format-source-muted = nerdFonts."md-microphone_off".glyph;
      format-icons = {
        headphones = nerdFonts."fa-headphones".glyph;
        speaker = nerdFonts."md-speaker_wireless".glyph;
        handsfree = nerdFonts."fa-headset".glyph;
        headset = nerdFonts."fa-headset".glyph;
        phone = nerdFonts."fa-phone".glyph;
        phone-muted = nerdFonts."fa-phone_slash".glyph;
        portable = nerdFonts."fa-phone".glyph;
        car = nerdFonts."fa-car".glyph;
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
