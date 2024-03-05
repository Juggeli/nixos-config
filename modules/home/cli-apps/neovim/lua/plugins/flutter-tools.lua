return {
	{
		"akinsho/flutter-tools.nvim",
		lazy = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"stevearc/dressing.nvim", -- optional for vim.ui.select
		},
		config = true,
		keys = {
			{ "<leader>rr", "<cmd>FlutterRun<cr>", desc = "Run flutter app" },
			{ "<leader>rR", "<cmd>FlutterRestart<cr>", desc = "Restart flutter app" },
			{ "<leader>rh", "<cmd>FlutterReload<cr>", desc = "Reload flutter app" },
			{ "<leader>rd", "<cmd>FlutterDevices<cr>", desc = "Run flutter app in selected device" },
		},
	},
}
