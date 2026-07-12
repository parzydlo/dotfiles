return {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = {
					vim.env.VIMRUNTIME .. "/lua",
					vim.fn.stdpath("config") .. "/lua",
				},
			},
		},
	},
}
