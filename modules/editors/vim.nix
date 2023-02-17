{ config, options, inputs, lib, pkgs, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.editors.vim;
  configDir = config.dotfiles.configDir;
in
{
  options.modules.editors.vim = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      neovim
      gcc
      rustc
      nodejs
      lazygit
      ripgrep
      tree-sitter
      stylua
      sumneko-lua-language-server
    ];

    programs.neovim.defaultEditor = true;

    hm.home.file.".config/nvim/" = {
      source = "${configDir}/nvim/";
      recursive = true;
    };
  };
}
