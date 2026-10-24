{
  description = "Portable Nerd Font glyph mappings";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nvf = {
    url = "github:NotAShelf/nvf/4cb74ea";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.mini-nvim = {
    url = "github:nvim-mini/mini.nvim";
    flake = false;
  };
  inputs.nerd-fonts = {
    url = "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/glyphnames.json";
    flake = false;
  };
  inputs.simple-icons = {
    url = "github:simple-icons/simple-icons";
    flake = false;
  };

  outputs =
    {
      self,
      nixpkgs,
      mini-nvim,
      nerd-fonts,
      simple-icons,
      home-manager,
      nvf,
    }:
    let
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems =
        f:
        builtins.listToAttrs (
          map (system: {
            name = system;
            value = f system;
          }) systems
        );
    in
    {
      homeManagerModules.default = import ./adapters/nix/home-manager;
      homeManagerModules.stylix = import ./adapters/nix/home-manager/stylix.nix;
      homeManagerModules.nvf = import ./adapters/nix/home-manager/nvf.nix { inherit nvf; };
      lib = import ./adapters/nix/nix.nix { } // {
        withConfig = args: import ./adapters/nix/nix.nix args;
      };
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          glyphbook-resolver = pkgs.stdenv.mkDerivation {
            pname = "glyphbook-resolver";
            version = "0";
            src = ./adapters/rust/glyphbook-resolver.rs;
            nativeBuildInputs = [ pkgs.rustc ];
            dontUnpack = true;
            buildPhase = "rustc $src -O -o glyphbook-resolver";
            installPhase = "install -Dm755 glyphbook-resolver $out/bin/glyphbook-resolver";
          };
          glyphbook = pkgs.writeShellApplication {
            name = "glyphbook";
            runtimeInputs = [ glyphbook-resolver pkgs.python3 ];
            text = ''
               export GLYPHBOOK_CATALOG=${self}/catalog/icons.json
               export GLYPHBOOK_INDEX=${self}/catalog/icons.index
               export GLYPHBOOK_RECORDS=${self}/catalog/icons.records.jsonl
               export GLYPHBOOK_RESOLVER=${glyphbook-resolver}/bin/glyphbook-resolver
               exec ${pkgs.dash}/bin/dash ${self}/adapters/shell/glyphbook "$@"
            '';
          };
        in
        {
          inherit glyphbook;
          inherit glyphbook-resolver;
          default = glyphbook;
        }
      );
      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.glyphbook}/bin/glyphbook";
        };
        generate = {
          type = "app";
          program = "${
            let
              pkgs = nixpkgs.legacyPackages.${system};
              resolver = self.packages.${system}.glyphbook-resolver;
            in
            pkgs.writeShellApplication {
              name = "glyphbook-generate";
              runtimeInputs = with pkgs; [
                jq
                neovim
                resolver
              ];
              text = ''
                export GLYPHBOOK_ROOT="$PWD"
                export GLYPHBOOK_RESOLVER=${resolver}/bin/glyphbook-resolver
                exec ${self}/scripts/generate.sh ${mini-nvim} ${nerd-fonts} ${simple-icons}/data/simple-icons.json
              '';
            }
          }/bin/glyphbook-generate";
        };
      });
      checks = forAllSystems (system: {
        themes = assert import ./adapters/nix/themes.test.nix;
          nixpkgs.legacyPackages.${system}.runCommand "glyphbook-theme-check" {
            nativeBuildInputs = with nixpkgs.legacyPackages.${system}; [ python3 neovim jq ];
          } ''
            python ${self}/adapters/python/themes.test.py
            python ${self}/adapters/python/parity.test.py ${nixpkgs.legacyPackages.${system}.writeText "glyphbook-theme-projection.json" (builtins.toJSON (let icons = import ./adapters/nix/nix.nix { theme = "github-dark-dimmed"; }; in {
              inherit (icons) websites applications mini;
            }))}
            GLYPHBOOK_RESOLVER=${self.packages.${system}.glyphbook-resolver}/bin/glyphbook-resolver python ${self}/adapters/python/prepared.test.py
            GLYPHBOOK_THEME=github-dark-dimmed sh ${self}/adapters/shell/glyphbook get website github.com | jq -e '.color == "#cdd9e5"'
            GLYPHBOOK_ROOT=${self} nvim --headless -u NONE -l ${self}/adapters/lua/themes.test.lua
            touch $out
          '';
        home-manager = import ./adapters/nix/nix.test.nix {
          pkgs = nixpkgs.legacyPackages.${system};
          inherit home-manager nvf;
        };
        catalog =
          nixpkgs.legacyPackages.${system}.runCommand "glyphbook-check"
            {
              nativeBuildInputs = with nixpkgs.legacyPackages.${system}; [
                check-jsonschema
                gnugrep
                jq
                lua
                yamllint
              ];
            }
             ''
               check-jsonschema --schemafile ${self}/themes/schema.json ${self}/themes/github-dark-dimmed.json
               check-jsonschema --schemafile ${self}/catalog/schema.json ${self}/catalog/icons.json
              yamllint -d relaxed ${self}/.github/workflows
               GLYPHBOOK_SKIP_NIX_TEST=1 bash ${self}/adapters/shell/shell.test.sh
              touch $out
            '';
      });
    };
}
