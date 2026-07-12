local oil = require("oil")

oil.setup({
	default_file_explorer = true,
	view_options = {
		show_hidden = true,
	},
})

vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" })
vim.keymap.set("n", "<C-t>", oil.toggle_float, { desc = "Oil (floating)" })
