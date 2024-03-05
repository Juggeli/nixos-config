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
					-- Set a bit brigher color for window separator
					WinSeparator = { fg = colors.surface1 },
				}
			end,
		},
	},
	{
		"hrsh7th/nvim-cmp",
		opts = function(_, opts)
			local cmp = require("cmp")
			opts.window = {
				documentation = cmp.config.window.bordered(),
				completion = cmp.config.window.bordered({
					winhighlight = "Normal:CmpPmenu,CursorLine:PmenuSel,Search:None",
				}),
			}
			opts.mapping["<CR>"] = nil
			opts.mapping = vim.tbl_deep_extend("force", opts.mapping, {
				["<C-y>"] = cmp.mapping.confirm({ select = true }),
			})
		end,
	},
}
