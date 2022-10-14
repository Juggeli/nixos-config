{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.editors.vim;
in
{
  options.modules.editors.vim = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      neovim
      cargo # to install nix lsp
      gcc
      nodejs
      gnumake
      lazygit
      ripgrep
    ];

    home.programs.zsh.shellAliases = {
      vim = "nvim";
      v = "nvim";
    };
  };
}
