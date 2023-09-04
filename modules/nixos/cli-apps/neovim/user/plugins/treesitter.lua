return {
	"nvim-treesitter/nvim-treesitter",
	opts = function(_, opts)
		opts.ensure_installed = { "lua", "nix" }
		require("nvim-treesitter.install").prefer_git = true
		return opts
	end,
}
