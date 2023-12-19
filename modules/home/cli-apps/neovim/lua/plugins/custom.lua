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
		opts = {
			servers = {
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
		"neovim/nvim-lspconfig",
		init = function()
			local keys = require("lazyvim.plugins.lsp.keymaps").get()
			-- change a keymap
			keys[#keys + 1] = { "P", vim.lsp.buf.hover, desc = "Hover" }
			keys[#keys + 1] = { "K", false }
		end,
	},
}
