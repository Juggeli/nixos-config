inputs@{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.cli-apps.neovim;
in
{
  options.plusultra.cli-apps.neovim = with types; {
    enable = mkBoolOpt false "Whether or not to enable neovim.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      /* neovim */
      /* gcc */
      /* rustc */
      /* nodejs */
      /* lazygit */
      /* ripgrep */
      /* tree-sitter */
      /* stylua */
      /* sumneko-lua-language-server */
      plusultra.neovim
    ];

    environment.variables = {
      EDITOR = "nvim";
    };

    /* plusultra.home = { */
    /*   configFile = { */
    /*     "nvim/" = { */
    /*       source = ./nvim; */
    /*       recursive = true; */
    /*     }; */
    /*   }; */
    /* }; */
  };
}
