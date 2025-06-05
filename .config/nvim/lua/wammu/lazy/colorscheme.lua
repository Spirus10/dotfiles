return {
	{
		url = "https://codeberg.org/jthvai/lavender.nvim",
		branch = "stable", -- versioned tags + docs updates from main
		lazy = false,
		priority = 1000,
		config = function()
			vim.g.lavender = {
				transparent = {
					background = true,
					float = true,
					popup = true,
					sidebar = true,
				},
				contrast = true,
				
				italic = {
					comments = true,
					functions = true,
					keywords = false,
					variables = false,
				},
			}
			vim.cmd([[colorscheme lavender]])

		end
	},
}
