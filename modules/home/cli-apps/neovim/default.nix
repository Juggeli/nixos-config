{ lib, config, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.plusultra.cli-apps.neovim;
in
{
  options.plusultra.cli-apps.neovim = {
    enable = mkEnableOption "Neovim";
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      extraPackages = with pkgs; [
        # LazyVim
        lua-language-server
        stylua
        # Telescope
        ripgrep
        # nix
        nil
        nixpkgs-fmt

        # For spectre search and replace
        (pkgs.writeShellScriptBin "gsed" "exec -a $0 ${gnused}/bin/sed $@")

        # Copilot
        nodejs_21
      ];

      plugins = with pkgs.vimPlugins; [
        lazy-nvim
      ];

      extraLuaConfig =
        let
          plugins = with pkgs.vimPlugins; [
            # LazyVim
            LazyVim
            bufferline-nvim
            cmp-buffer
            cmp-nvim-lsp
            cmp-path
            cmp_luasnip
            cmp-emoji
            conform-nvim
            dashboard-nvim
            dressing-nvim
            flash-nvim
            friendly-snippets
            gitsigns-nvim
            indent-blankline-nvim
            lualine-nvim
            neo-tree-nvim
            neoconf-nvim
            neodev-nvim
            noice-nvim
            nui-nvim
            nvim-cmp
            nvim-lint
            nvim-lspconfig
            nvim-notify
            nvim-spectre
            nvim-treesitter
            nvim-treesitter-context
            nvim-treesitter-textobjects
            nvim-ts-autotag
            nvim-ts-context-commentstring
            nvim-web-devicons
            persistence-nvim
            plenary-nvim
            telescope-fzf-native-nvim
            telescope-nvim
            todo-comments-nvim
            tokyonight-nvim
            trouble-nvim
            vim-illuminate
            vim-startuptime
            which-key-nvim
            flutter-tools-nvim
            lexima-vim
            neotest-python
            nvim-dap
            nvim-dap-ui
            nvim-dap-virtual-text
            nvim-dap-python
            nvim-dap-go
            nvim-nio
            neotest
            neotest-go
            copilot-lua
            copilot-cmp
            {
              name = "LuaSnip";
              path = luasnip;
            }
            {
              name = "catppuccin";
              path = catppuccin-nvim;
            }
            {
              name = "mini.ai";
              path = mini-nvim;
            }
            {
              name = "mini.bufremove";
              path = mini-nvim;
            }
            {
              name = "mini.comment";
              path = mini-nvim;
            }
            {
              name = "mini.indentscope";
              path = mini-nvim;
            }
            {
              name = "mini.surround";
              path = mini-nvim;
            }
            {
              name = "mini.animate";
              path = mini-nvim;
            }
          ];
          mkEntryFromDrv = drv:
            if lib.isDerivation drv
            then {
              name = "${lib.getName drv}";
              path = drv;
            }
            else drv;
          lazyPath = pkgs.linkFarm "lazy-plugins" (builtins.map mkEntryFromDrv plugins);
        in
        ''
          require("lazy").setup({
            defaults = {
              lazy = true,
            },
            dev = {
              -- reuse files from pkgs.vimPlugins.*
              path = "${lazyPath}",
              patterns = { "." },
              -- fallback to download
              fallback = true,
            },
            spec = {
              { "LazyVim/LazyVim", import = "lazyvim.plugins" },
              { import = "lazyvim.plugins.extras.dap.core" },
              { import = "lazyvim.plugins.extras.ui.mini-animate" },
              { import = "lazyvim.plugins.extras.lang.python" },
              { import = "lazyvim.plugins.extras.coding.copilot" },
              { import = "lazyvim.plugins.extras.lang.go" },
              -- The following configs are needed for fixing lazyvim on nix
              -- force enable telescope-fzf-native.nvim
              { "nvim-telescope/telescope-fzf-native.nvim", enabled = true },
              -- disable mason.nvim, use programs.neovim.extraPackages
              { "williamboman/mason-lspconfig.nvim", enabled = false },
              { "williamboman/mason.nvim", enabled = false },
              { "jay-babu/mason-nvim-dap.nvim", enabled = false },
              -- import/override with your plugins
              { import = "plugins" },
              -- treesitter handled by xdg.configFile."nvim/parser", put this line at the end of spec to clear ensure_installed
              { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = {} } },
            },
          })
        '';
    };

    # https://github.com/nvim-treesitter/nvim-treesitter#i-get-query-error-invalid-node-type-at-position
    xdg.configFile."nvim/parser".source =
      let
        parsers = pkgs.symlinkJoin {
          name = "treesitter-parsers";
          paths =
            (pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins:
              with plugins; [
                nix
                lua
                fish
                dart
                kotlin
                swift
                rust
                go
                c
                vim
                vimdoc
                query
                ninja
                python
                rst
                toml
              ])).dependencies;
        };
      in
      "${parsers}/parser";

    # Normal LazyVim config here, see https://github.com/LazyVim/starter/tree/main/lua
    xdg.configFile."nvim/lua/plugins".source = ./lua/plugins;
    xdg.configFile."nvim/lua/config".source = ./lua/config;
    xdg.configFile."nvim/snippets/nix.snippets".source = ./nix.snippets;

    plusultra.user.impermanence = {
      directories = [
        ".local/state/nvim"
        ".local/share/nvim"
        ".cache/nvim"
      ];
      files = [
        ".config/nvim/lazyvim.json"
      ];
    };
  };
}
