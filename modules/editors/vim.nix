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
      gcc
      nodejs
      gnumake
      lazygit
      ripgrep
    ];

    hm.programs.zsh.shellAliases = {
      vim = "nvim";
      v = "nvim";
    };
  };
}
