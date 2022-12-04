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
    nixpkgs.overlays = [ inputs.vim-extra-plugins.overlays.default ];

    user.packages = with pkgs; [
      lazygit
      ripgrep
      tree-sitter
      rnix-lsp
      sumneko-lua-language-server
      nodePackages.prettier
      stylua
      nodePackages.eslint
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
        telescope-fzf-native-nvim
        nvim-treesitter.withAllGrammars
        nvim-lspconfig
        cmp-nvim-lsp
        nvim-cmp
        cmp-path
        cmp-buffer
        lspsaga-nvim
        null-ls-nvim
        gitsigns-nvim
        nvim-autopairs
        nvim-ts-autotag
        comment-nvim
        lualine-nvim
        luasnip
        cmp_luasnip
        friendly-snippets
        lspkind-nvim
        nvim-tree-lua
        vim-tmux-navigator
        vim-surround
        nvim-web-devicons
        bufferline-nvim
        nvim-lastplace
        bufdelete-nvim
        which-key-nvim
        vim-hexokinase
      ] ++ [
        pkgs.vimExtraPlugins.vim-nightfly-colors
      ];
      extraConfig = "lua << EOF\n" + builtins.readFile "${configDir}/nvim/init.lua" + "\nEOF";
    };
  };
}
