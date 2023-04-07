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
      neovim
      wl-clipboard
      ripgrep
      lazygit
      bottom
      nodejs
      gdu
      stylua
      lua-language-server
      rnix-lsp
      alejandra
      deadnix
      statix
      rust-analyzer
      clang
      cargo
    ];

    environment.localBinInPath = true;

    plusultra.home.extraOptions.home.sessionVariables = {
      EDITOR = "nvim";
    };

    plusultra.home.configFile = {
      "nvim/lua/user" = {
        source = ./user;
        recursive = true;
      };
      "nvim" = {
        source = "${pkgs.plusultra.astronvim}";
        recursive = true;
      };
    };
  };
}
