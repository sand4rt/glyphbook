{ pkgs, home-manager, nvf }:
let
  configuration =
    extra:
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ./home-manager
        {
          home.username = "example";
          home.homeDirectory = "/home/example";
          home.stateVersion = "26.05";
          programs.yazi.enable = true;
          programs.neovim.enable = true;
          programs.lsd.enable = true;
          programs.waybar.enable = true;
          glyphbook = {
            enable = true;
            targets.yazi.enable = true;
            targets.yazi.notifications.enable = true;
            targets.yazi.conditionColors.orphan = "#654321";
            targets.yazi.conditionColors.dir = "#123456";
            targets.neovim.enable = true;
            targets.lsd.enable = true;
            targets.waybar.bluetooth = {
              enable = true;
              bars = [ "main" ];
            };
            targets.waybar.modules = {
              enable = true;
              bars = [ "main" ];
            };
            overrides.extension.nix = {
              glyph = "G";
              color = "#123456";
            };
            overrides.editorFiletype.nix = {
              glyph = "G";
              color = "#123456";
            };
            overrides.website."example.com" = {
              glyph = "W";
              color = "#abcdef";
            };
            overrides.directory.project.glyph = "P";
            overrides.default.file.color = null;
            overrides.application.terminal.color = "#ffffff";
            overrides.website."*".color = "#112233";
            overrides.website."*.example.com".glyph = "S";
            overrides.website."*.docs.example.com".glyph = "D";
            overrides.website."plain.example".glyph = "U";
            theme.muted = "#777777";
            apps.rofi.colors = {
              mode = "monochrome";
              color = "#777777";
            };
          };
        }
        extra
      ];
    }).config;
  generated = configuration { };
  nvfGenerated = (home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ./home-manager
      (import ./home-manager/nvf.nix { inherit nvf; })
      {
        home.username = "example";
        home.homeDirectory = "/home/example";
        home.stateVersion = "26.05";
        programs.nvf.enable = true;
        glyphbook = {
          enable = true;
          targets.nvf.enable = true;
        };
      }
    ];
  }).config;
  local = configuration {
    programs.lsd.icons.extension.nix = "L";
    programs.yazi.theme.icon.exts = [
      {
        name = "nix";
        text = "L";
      }
    ];
    programs.yazi.theme.icon.prepend_dirs = [
      {
        name = "project";
        text = "P";
      }
    ];
    glyphbook.targets.neovim.settings.filetype.nix.glyph = "L";
    glyphbook.targets.neovim.settings.filetype.glyphbook_delimiter.glyph = "]=]";
    programs.waybar.settings.main.pulseaudio.format-icons.speaker = "L";
  };
  disabled = configuration { glyphbook.enable = lib.mkForce false; };
  targetDisabled = configuration {
    glyphbook.targets.yazi.enable = lib.mkForce false;
    glyphbook.targets.lsd.enable = lib.mkForce false;
  };
  appDisabled = configuration {
    programs.yazi.enable = lib.mkForce false;
    programs.lsd.enable = lib.mkForce false;
  };
  lib = pkgs.lib;
in
assert builtins.any (
  rule: rule.name == "project" && rule.text == "P" && !(rule ? fg)
) generated.programs.yazi.theme.icon.dirs;
assert builtins.any (
  rule: rule."if" == "!dir" && !(rule ? fg)
) generated.programs.yazi.theme.icon.prepend_conds;
assert builtins.any (
  rule: rule."if" == "orphan" && rule.text == generated.glyphbook.icons.nerdFonts."fa-exclamation_triangle".glyph && rule.fg == "#654321"
) generated.programs.yazi.theme.icon.prepend_conds;
assert builtins.any (
  rule: rule."if" == "dir" && rule.fg == "#123456"
) generated.programs.yazi.theme.icon.prepend_conds;
assert
  map (rule: rule."if") generated.programs.yazi.theme.icon.prepend_conds
  == [ "orphan" "link" "block" "fifo" "sock" "sticky" "dummy" "exec" "dir" "!dir" ];
assert
  generated.glyphbook.icons.applications.terminal.glyph == (import ./nix.nix { })
  .applications.terminal.glyph;
assert generated.glyphbook.icons.git.added.glyph == generated.glyphbook.icons.nerdFonts."oct-diff_added".glyph;
assert generated.glyphbook.icons.git.deleted.glyph == generated.glyphbook.icons.nerdFonts."oct-diff_removed".glyph;
assert generated.glyphbook.icons.git.ignored.glyph == generated.glyphbook.icons.nerdFonts."oct-diff_ignored".glyph;
assert generated.glyphbook.icons.git.modified.glyph == generated.glyphbook.icons.nerdFonts."oct-diff_modified".glyph;
assert generated.glyphbook.icons.git.untracked.glyph == generated.glyphbook.icons.nerdFonts."md-checkbox_blank_circle_outline".glyph;
assert generated.glyphbook.icons.websiteFallbackColor == "#112233";
assert (generated.glyphbook.icons.resolve {
  category = "application";
  name = "calendar";
  app = "rofi";
}).color == "#777777";
assert (generated.glyphbook.icons.resolve {
  category = "application";
  name = "terminal";
  app = "rofi";
}).color == "#ffffff";
assert builtins.any (
  icon: icon.domains == [ "plain.example" ] && icon.color == null
) generated.glyphbook.icons.websites;
assert
  map (icon: builtins.head icon.domains) (
    builtins.filter (
      icon:
      builtins.elem (builtins.head icon.domains) [
        "*.example.com"
        "*.docs.example.com"
      ]
    ) generated.glyphbook.icons.websites
  ) == [
    "*.docs.example.com"
    "*.example.com"
  ];
assert
  !(builtins.tryEval (
    (import ./nix.nix { overrides.file.unknown.color = null; }).mini.file.unknown
  )).success;
assert generated.glyphbook.icons.mini.extension.nix.glyph == "G";
assert generated.programs.yazi.theme.notify.icon_info == generated.glyphbook.icons.nerdFonts."md-information".glyph;
assert local.glyphbook.targets.neovim.settings.filetype.nix.glyph == "L";
assert generated.programs.lsd.icons.extension.nix == "G";
assert generated.programs.waybar.settings.main.bluetooth.format-connected == generated.glyphbook.icons.nerdFonts."fa-bluetooth".glyph;
assert generated.programs.waybar.settings.main.bluetooth.format-icons == builtins.genList (_: generated.glyphbook.icons.nerdFonts."md-battery".glyph) 11;
assert generated.programs.waybar.settings.main."hyprland/workspaces".format-icons."1" == "1";
assert generated.programs.waybar.settings.main.disk.format-critical == generated.glyphbook.icons.nerdFonts."md-harddisk".glyph;
assert generated.programs.waybar.settings.main.cpu.format-critical == generated.glyphbook.icons.nerdFonts."md-chip".glyph;
  assert generated.programs.waybar.settings.main.battery.format-icons == [
    generated.glyphbook.icons.nerdFonts."md-battery_outline".glyph
    generated.glyphbook.icons.nerdFonts."md-battery_10".glyph
    generated.glyphbook.icons.nerdFonts."md-battery_20".glyph
    generated.glyphbook.icons.nerdFonts."md-battery_30".glyph
    generated.glyphbook.icons.nerdFonts."md-battery_40".glyph
    generated.glyphbook.icons.nerdFonts."md-battery_50".glyph
    generated.glyphbook.icons.nerdFonts."md-battery_60".glyph
    generated.glyphbook.icons.nerdFonts."md-battery_70".glyph
    generated.glyphbook.icons.nerdFonts."md-battery_80".glyph
    generated.glyphbook.icons.nerdFonts."md-battery_90".glyph
    generated.glyphbook.icons.nerdFonts."md-battery".glyph
  ];
  assert generated.programs.waybar.settings.main.pulseaudio.format-icons == {
    speaker = generated.glyphbook.icons.nerdFonts."fa-volume_high".glyph;
    handsfree = generated.glyphbook.icons.nerdFonts."fa-headphones".glyph;
    headset = generated.glyphbook.icons.nerdFonts."fa-headphones".glyph;
    phone = generated.glyphbook.icons.nerdFonts."fa-phone".glyph;
    phone-muted = generated.glyphbook.icons.nerdFonts."fa-phone".glyph;
    portable = generated.glyphbook.icons.nerdFonts."fa-volume_high".glyph;
    default = [
      generated.glyphbook.icons.nerdFonts."fa-volume_off".glyph
      generated.glyphbook.icons.nerdFonts."fa-volume_down".glyph
      generated.glyphbook.icons.nerdFonts."fa-volume".glyph
      generated.glyphbook.icons.nerdFonts."fa-volume_high".glyph
    ];
  };
  assert nvfGenerated.programs.nvf.settings.vim.autocomplete.blink-cmp.setupOpts.appearance.kind_icons.Tag == nvfGenerated.glyphbook.icons.nvim.completion.Tag;
  assert nvfGenerated.programs.nvf.settings.vim.diagnostics.config.signs.text != null;
  assert nvfGenerated.programs.nvf.settings.vim.mini.icons.setupOpts.file."devcontainer.json".glyph == nvfGenerated.glyphbook.icons.nerdFonts."oct-shield_lock".glyph;
  assert nvfGenerated.programs.nvf.settings.vim.lazy.plugins."nvim-colorizer.lua".setupOpts.user_default_options.virtualtext == nvfGenerated.glyphbook.icons.nerdFonts."fa-square".glyph;
  assert nvfGenerated.programs.nvf.settings.vim.luaConfigRC.glyphbook-nvf-dap-signs != "";
assert local.programs.lsd.icons.extension.nix == "L";
assert local.programs.waybar.settings.main.pulseaudio.format-icons.speaker == "L";
assert
  local.programs.yazi.theme.icon.exts == [
    {
      name = "nix";
      text = "L";
    }
  ];
assert local.programs.yazi.theme.icon.dirs != [ ];
assert
  local.programs.yazi.theme.icon.prepend_dirs == [
    {
      name = "project";
      text = "P";
    }
  ];
assert disabled.programs.yazi.theme == { } && disabled.programs.neovim.plugins == [ ] && disabled.programs.lsd.icons == { };
assert targetDisabled.programs.yazi.theme == { } && targetDisabled.programs.neovim.plugins != [ ] && targetDisabled.programs.lsd.icons == { };
assert appDisabled.programs.yazi.theme == { } && appDisabled.programs.lsd.icons == { };
assert builtins.any (
  icon: icon.domains == [ "example.com" ] && icon.glyph == "W"
) generated.glyphbook.icons.websites;
pkgs.runCommand "glyphbook-home-manager-check"
  {
    nativeBuildInputs = [
      pkgs.neovim
      pkgs.python3
    ];
    theme = (pkgs.formats.toml { }).generate "theme.toml" generated.programs.yazi.theme;
    luaConfig = pkgs.writeText "glyphbook-init.lua" (
      ''vim.opt.runtimepath:append("${pkgs.vimPlugins.mini-icons}")''
      + "\n"
      + generated.programs.neovim.initLua
    );
    localLuaConfig = pkgs.writeText "glyphbook-local-init.lua" (
      ''vim.opt.runtimepath:append("${pkgs.vimPlugins.mini-icons}")''
      + "\n"
      + local.programs.neovim.initLua
    );
  }
  ''
    python - "$theme" <<'PY'
    import sys, tomllib
    with open(sys.argv[1], "rb") as source:
        icon = tomllib.load(source)["icon"]
    assert next(rule for rule in icon["exts"] if rule["name"] == "nix")["text"] == "G"
    conditions = icon["prepend_conds"]
    assert [rule["if"] for rule in conditions] == ["orphan", "link", "block", "fifo", "sock", "sticky", "dummy", "exec", "dir", "!dir"]
    assert next(rule for rule in conditions if rule["if"] == "orphan")["fg"] == "#654321"
    PY
    nvim --headless -u "$luaConfig" -l ${./home-manager/neovim.test.lua}
    GLYPHBOOK_EXPECTED_GLYPH=L GLYPHBOOK_EXPECTED_FILE_GLYPH=G nvim --headless -u "$localLuaConfig" -l ${./home-manager/neovim.test.lua}
    touch "$out"
  ''
