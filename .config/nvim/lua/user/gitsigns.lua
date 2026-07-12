local gitsigns = require("gitsigns")

gitsigns.setup({
	on_attach = function(bufnr)
		local opts = { buffer = bufnr, silent = true }
		-- hunk navigation, same keys vim-gitgutter used
		vim.keymap.set("n", "]c", function()
			gitsigns.nav_hunk("next")
		end, opts)
		vim.keymap.set("n", "[c", function()
			gitsigns.nav_hunk("prev")
		end, opts)
		vim.keymap.set("n", "<leader>hp", gitsigns.preview_hunk, opts)
	end,
})
