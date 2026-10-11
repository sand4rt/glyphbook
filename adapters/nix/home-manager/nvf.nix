{ nvf }:
{ config, lib, ... }:
let
  cfg = config.glyphbook.targets.nvf;
  icons = config.glyphbook.icons;
in
{
  imports = [
    nvf.homeManagerModules.default
  ];

  options.glyphbook.targets.nvf.enable = lib.mkEnableOption "Glyphbook icon defaults for NVF";

  config = lib.mkIf (config.programs.nvf.enable && config.glyphbook.enable && cfg.enable) {
    programs.nvf.settings.vim = {
      mini.icons = {
        enable = lib.mkDefault true;
        setupOpts = {
          style = lib.mkDefault "glyph";
          file."devcontainer.json" = lib.mkDefault {
            glyph = icons.nerdFonts."oct-shield_lock".glyph;
            hl = "MiniIconsAzure";
          };
          filetype.dotenv = lib.mkDefault {
            glyph = icons.nerdFonts."oct-shield_lock".glyph;
            hl = "MiniIconsYellow";
          };
          extension.gpg = lib.mkDefault {
            glyph = icons.nerdFonts."oct-shield_lock".glyph;
            hl = "MiniIconsRed";
          };
        };
      };
      autocomplete.blink-cmp.setupOpts.appearance.kind_icons = lib.mapAttrs (_: lib.mkDefault) icons.nvim.completion;
      diagnostics.config.signs.text = lib.mkDefault (lib.generators.mkLuaInline ''
        {
          [vim.diagnostic.severity.ERROR] = '${icons.nvim.diagnostics.error}',
          [vim.diagnostic.severity.WARN] = '${icons.nvim.diagnostics.warn}',
          [vim.diagnostic.severity.INFO] = '${icons.nvim.diagnostics.info}',
          [vim.diagnostic.severity.HINT] = '${icons.nvim.diagnostics.hint}',
        }
      '');
      languages.markdown.extensions.render-markdown-nvim.setupOpts.checkbox = {
        checked.icon = lib.mkDefault " ${icons.nerdFonts."md-checkbox_marked".glyph}";
        unchecked.icon = lib.mkDefault " ${icons.nerdFonts."md-checkbox_blank_outline".glyph}";
      };
      ui.noice.setupOpts.cmdline.format = {
        search_down.icon = lib.mkDefault "${icons.nerdFonts."fa-search".glyph} ";
        search_up.icon = lib.mkDefault "${icons.nerdFonts."fa-search".glyph} ";
        lua.icon = lib.mkDefault icons.nerdFonts."seti-lua".glyph;
        help.icon = lib.mkDefault "${icons.nerdFonts."md-keyboard_outline".glyph} ";
        input.icon = lib.mkDefault "${icons.nerdFonts."md-keyboard_outline".glyph} ";
      };
      utility.snacks-nvim.setupOpts.picker.prompt = lib.mkDefault " ${icons.nerdFonts."oct-search".glyph}  ";
      lazy.plugins."nvim-colorizer.lua".setupOpts.user_default_options.virtualtext = lib.mkDefault icons.nerdFonts."fa-square".glyph;
      luaConfigRC.glyphbook-nvf-dap-signs = lib.mkDefault ''
        vim.fn.sign_define("DapStopped", { text = "${icons.nerdFonts."md-label".glyph}", linehl = "DapStoppedLine", texthl = "DapStopped", numhl = "DapStopped" })
        vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "DapBreakpoint" })
        vim.fn.sign_define("DapBreakpointRejected", { text = "●", texthl = "DapRejected", linehl = "", numhl = "DapRejected" })
        vim.fn.sign_define("DapLogPoint", { text = "${icons.nerdFonts."md-circle_multiple".glyph}", texthl = "DapBreakpoint", linehl = "", numhl = "DapBreakpoint" })
      '';
    };
  };
}
