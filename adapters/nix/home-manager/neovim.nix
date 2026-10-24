{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.glyphbook.targets.neovim;
  mini = config.glyphbook.icons.miniFor "neovim";
  settings = lib.mapAttrs (
    _:
    lib.mapAttrs (
      _: icon:
      {
        glyph = icon.glyph;
      }
      // lib.optionalAttrs ((icon.color or null) != null) {
        hl = "Glyphbook" + builtins.hashString "sha256" icon.color;
      }
    )
   ) (mini // { filetype = mini.editorFiletype; });
  json = builtins.toJSON (lib.recursiveUpdate settings cfg.settings);
  settingsFile = pkgs.writeText "glyphbook-mini-icons.json" json;
in
{
  options.glyphbook.targets.neovim = {
    enable = lib.mkEnableOption "Glyphbook defaults for Neovim's mini.icons";
    settings = lib.mkOption {
      type = (pkgs.formats.json { }).type;
      default = { };
      description = "Application-local mini.icons setup settings; normal values override Glyphbook defaults.";
    };
  };

  config = lib.mkIf (config.glyphbook.enable && cfg.enable && config.programs.neovim.enable) {
    programs.neovim.plugins = [ pkgs.vimPlugins.mini-icons ];
    programs.neovim.initLua = lib.mkBefore ''
      local settings = vim.json.decode(table.concat(vim.fn.readfile("${settingsFile}"), "\n"))
      local function highlights()
        ${lib.concatStringsSep "\n" (
          lib.unique (
            lib.concatLists (
              lib.mapAttrsToList (
                _: icons:
                lib.mapAttrsToList (
                  _: icon:
                  lib.optionalString ((icon.color or null) != null) ''
                    vim.api.nvim_set_hl(0, "Glyphbook${builtins.hashString "sha256" icon.color}", { fg = "${icon.color}" })
                  ''
                ) icons
               ) mini
            )
          )
        )}
      end
      highlights()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("Glyphbook", { clear = true }),
        callback = highlights,
      })
      require("mini.icons").setup(settings)
    '';
  };
}
