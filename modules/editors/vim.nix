{ config, options, lib, pkgs, ... }:

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
      lazygit
      ripgrep
      tree-sitter
      rnix-lsp
    ];

    programs.neovim.defaultEditor = true;

    hm.programs.neovim = {
      enable = true;
      vimAlias = true;
      viAlias = true;
      vimdiffAlias = true;
      plugins = with pkgs.vimPlugins; [
        telescope-nvim
        telescope-symbols-nvim
        nvim-treesitter
        nvim-lspconfig
        cmp-nvim-lsp
        nvim-cmp
        gitsigns-nvim
        nvim-autopairs
      ];
      extraConfig = "lua << EOF\n" + builtins.readFile "${configDir}/nvim/init.lua" + "\nEOF";
    };
  };
}
