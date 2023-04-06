return {
	{
		"rebelot/heirline.nvim",
		opts = function(opts)
			opts.tabline = nil
		end,
	},
	{
		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		opts = function(_, opts)
			local signs = { error = " ", warning = " ", hint = " ", info = " " }
			local severities = {
				"error",
				"warning",
			}
			opts.highlights = require("catppuccin.groups.integrations.bufferline").get()
			opts.options = {
				mode = "buffers",
				show_close_icon = false,
				show_buffer_close_icons = false,
				persist_buffer_sort = true,
				diagnostics = "nvim_lsp",
				always_show_bufferline = true,
				diagnostics_indicator = function(_, _, diagnostic)
					local strs = {}
					for _, severity in ipairs(severities) do
						if diagnostic[severity] then
							table.insert(strs, signs[severity] .. diagnostic[severity])
						end
					end

					return table.concat(strs, " ")
				end,
				offsets = {
					{
						filetype = "neo-tree",
						text = "(╯°□°)╯︵ ┻━┻",
						highlight = "Directory",
						text_align = "left",
					},
				},
			}
			return opts
		end,
	},
}
