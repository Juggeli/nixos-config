return {
	-- Configure LazyVim to load gruvbox
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "catppuccin",
		},
	},
	{
		"neovim/nvim-lspconfig",
		init = function()
			local keys = require("lazyvim.plugins.lsp.keymaps").get()
			-- change a keymap
			keys[#keys + 1] = { "P", vim.lsp.buf.hover, desc = "Hover" }
			keys[#keys + 1] = { "K", false }
		end,
		opts = {
			servers = {
				kotlin_language_server = {},
				nil_ls = {
					settings = {
						["nil"] = {
							formatting = {
								command = { "nixpkgs-fmt" },
							},
						},
					},
				},
			},
		},
	},
	{
		"akinsho/flutter-tools.nvim",
		lazy = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"stevearc/dressing.nvim", -- optional for vim.ui.select
		},
		config = true,
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		opts = {
			close_if_last_window = true,
		},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			indent = {
				enable = true,
				-- Disable dart indendation for now because of massive lag
				disable = {
					"dart",
				},
			},
		},
	},
	{
		"L3MON4D3/LuaSnip",
		optional = true,
		config = function()
			require("luasnip.loaders.from_snipmate").lazy_load()
		end,
	},
	{ "echasnovski/mini.pairs", enabled = false },
	{ "cohama/lexima.vim", event = "VeryLazy" },
	{
		"nvim-telescope/telescope.nvim",
		opts = {
			defaults = {
				layout_strategy = "vertical",
			},
		},
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		opts = {
			custom_highlights = function(colors)
				return {
					WinSeparator = { fg = colors.surface1 },
				}
			end,
		},
	},
	{ "linux-cultist/venv-selector.nvim", enabled = false },
}
